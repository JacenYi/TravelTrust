import logging
import json
from src.config import Config
from src.web3_manager import Web3Manager
from src.db_manager import DatabaseManager
from src.volc_engine_ai import VolcEngineAI

logger = logging.getLogger(__name__)

class BusinessLogic:
    def __init__(self, config: Config, web3_manager: Web3Manager, db_manager: DatabaseManager):
        self.config = config
        self.web3_manager = web3_manager
        self.db_manager = db_manager
        
        # Initialize Volc Engine AI service
        self.volc_ai = VolcEngineAI(
            api_key=config.volc_ai_api_key,
            api_url=config.volc_ai_api_url
        )
    
    async def process_review_submitted(self, event_data):
        """Process review submission event - update transaction hash and perform AI audit"""
        try:
            review_id = event_data['reviewId']
            scenic_spot_id = event_data['scenicSpotId']
            user_address = event_data['user']
            review_content = event_data['content']
            rating = event_data['rating']
            tx_hash = event_data['transaction_hash']  # Get the actual transaction hash from the event
            
            logger.info(f"Processing review submission for review_id: {review_id}")
            
            # 1. Update review transaction hash - only update submitHash, use zero hash for approveHash
            tx_hash_bytes32 = self.web3_manager.web3.to_bytes(hexstr=tx_hash)
            
            func_call = self.web3_manager.contract.functions.updateReviewTxHashes(
                review_id,  # reviewId
                tx_hash_bytes32,  # submitHash (bytes32) - use actual transaction hash
                self.web3_manager.web3.to_bytes(hexstr="0x" + "0" * 64)  # approveHash (bytes32) - initialize to zero hash
            )
            
            # Send transaction
            update_tx_hash = self.web3_manager.send_transaction(func_call)
            if update_tx_hash is None:
                logger.error(f"Failed to update transaction hash for review_id: {review_id}")
                return False, "Failed to update transaction hash"
            
            logger.info(f"Successfully updated transaction hash for review_id: {review_id}, tx_hash: {update_tx_hash}")
            
            # 2. Get scenic spot information
            scenic_spot_info = self.web3_manager.get_scenic_spot(scenic_spot_id)
            # getScenicSpot returns a tuple (ScenicSpot, Summary), scenic spot name is in the ScenicSpot struct
            scenic_spot_name = scenic_spot_info[0][1] if scenic_spot_info and len(scenic_spot_info) > 0 else "Unknown Scenic Spot"
            
            # 3. Build AI audit structure
            # Add detailed debug logs to check each field type
            logger.info(f"scenic_spot_info type: {type(scenic_spot_info)}, scenic_spot_info: {scenic_spot_info}")
            logger.info(f"scenic_spot_name type: {type(scenic_spot_name)}, value: {scenic_spot_name}")
            logger.info(f"review_content type: {type(review_content)}, value: {review_content}")
            logger.info(f"rating type: {type(rating)}, value: {rating}")
                        
            # Process review_content
            if isinstance(review_content, bytes):
                review_content = review_content.decode('utf-8')
                logger.info(f"Converted review_content from bytes to string: {review_content}")
            elif not isinstance(review_content, (str, int, float, bool, type(None))):
                review_content = str(review_content)
                logger.info(f"Converted review_content to string: {review_content}")
            
            # Process rating
            if not isinstance(rating, (int, float)):
                try:
                    rating = float(rating)
                    logger.info(f"Converted rating to float: {rating}")
                except:
                    rating = 0
                    logger.info(f"Failed to convert rating, using default: {rating}")
            
            # Build audit_content dictionary
            audit_content = {
                "ScenicSpotName": scenic_spot_name,
                "EvaluationScore": rating,
                "content": review_content
            }
            
            # Check types of audit_content dictionary
            for key, value in audit_content.items():
                logger.info(f"audit_content[{key}] type: {type(value)}, value: {value}")
            
            # Use try-except to catch JSON serialization errors and print detailed information
            try:
                audit_content_str = json.dumps(audit_content, ensure_ascii=False)
                logger.info(f"----------------------audit_content: {audit_content_str}")
            except Exception as e:
                logger.error(f"Failed to serialize audit_content to JSON: {e}")
                logger.error(f"Detailed error information:")
                for key, value in audit_content.items():
                    logger.error(f"  {key}: type={type(value)}, repr={repr(value)}, str={str(value)}")
                raise
            
            is_approved = await self._audit_review_content(audit_content_str)

            audit_reason = "Content approved" if is_approved else "Content contains inappropriate information"
            
            # Save audit result
            await self.db_manager.save_review_audit(
                review_id=review_id,
                scenic_spot_id=scenic_spot_id,
                user_address=user_address,
                review_content=review_content,
                rating=rating,
                is_approved=is_approved,
                audit_reason=audit_reason
            )
            
            # 3. Call updateReviewStatus to update review status
            logger.info(f"AI audit result: review_id={review_id}, is_approved={is_approved}")
            
            func_call = self.web3_manager.contract.functions.updateReviewStatus(
                review_id,
                is_approved
            )
            
            # Send transaction
            approve_tx_hash = self.web3_manager.send_transaction(func_call)
            if approve_tx_hash is None:
                logger.error(f"Failed to update review status for review_id: {review_id}")
                return False, "Failed to update review status"
            
            logger.info(f"Successfully updated review status for review_id: {review_id}, is_approved={is_approved}, tx_hash: {approve_tx_hash}")
            
            return True, f"tx_hash: {update_tx_hash}, approve_tx_hash: {approve_tx_hash}"
            
        except Exception as e:
            logger.error(f"Error processing review_submitted event: {e}")
            return False, str(e)
    
    async def process_review_approved(self, event_data):
        """Process review approval event - update approval transaction hash"""
        try:
            review_id = event_data['reviewId']
            tx_hash = event_data['transaction_hash']  # Get the actual transaction hash from the event
            
            logger.info(f"Processing review approval for review_id: {review_id}")
            
            # Convert transaction hash string to bytes32 type required by smart contract
            tx_hash_bytes32 = self.web3_manager.web3.to_bytes(hexstr=tx_hash)
            
            # Update review transaction hash - only update approveHash, use zero hash for submitHash
            func_call = self.web3_manager.contract.functions.updateReviewTxHashes(
                review_id,  # reviewId
                self.web3_manager.web3.to_bytes(hexstr="0x" + "0" * 64),  # submitHash (bytes32) - use zero hash
                tx_hash_bytes32  # approveHash (bytes32) - use actual transaction hash
            )
            
            # Send transaction
            oracle_tx_hash = self.web3_manager.send_transaction(func_call)
            if oracle_tx_hash is None:
                logger.error(f"Failed to update approval transaction hash for review_id: {review_id}")
                return False, "Failed to send transaction"
            
            logger.info(f"Successfully updated approval transaction hash for review_id: {review_id}, tx_hash: {oracle_tx_hash}")
            return True, oracle_tx_hash
            
        except Exception as e:
            logger.error(f"Error processing review_approved event: {e}")
            return False, str(e)
    
    async def process_summary_update_required(self, event_data):
        """Process summary update request event - generate and upload AI summary"""
        try:
            scenic_spot_id = event_data['scenicSpotId']
            from_review_index = event_data['fromReviewIndex']
            to_review_index = event_data['toReviewIndex']
            current_last_review_index = event_data['currentLastReviewIndex']
            
            logger.info(f"Processing summary update for scenic_spot_id: {scenic_spot_id}")
            logger.info(f"  fromReviewIndex: {from_review_index}, toReviewIndex: {to_review_index}, currentLastReviewIndex: {current_last_review_index}")
            
            # 1. Use getReviewsForSummary method to get approved reviews and corresponding review IDs
            # Calculate the number of reviews needed (to_review_index - from_review_index + 1)
            review_count = to_review_index - from_review_index + 1
            
            # Call getReviewsForSummary method of the contract
            reviews_result = self.web3_manager.get_reviews_for_summary(scenic_spot_id, review_count)
            
            if not reviews_result:
                logger.warning(f"Failed to get reviews for summary for scenic_spot_id: {scenic_spot_id}")
                return True, "Failed to get reviews for summary"
            
            requested_reviews, requested_review_ids = reviews_result
            
            logger.info(f"Found {len(requested_reviews)} reviews via getReviewsForSummary, corresponding IDs: {requested_review_ids}")
            
            if not requested_reviews:
                logger.warning(f"No reviews found for scenic_spot_id: {scenic_spot_id}")
                return True, "No reviews to summarize"
            
            # 2. Use the retrieved approved reviews and review IDs
            approved_reviews = requested_reviews
            review_ids = requested_review_ids
            
            logger.info(f"Using {len(approved_reviews)} approved reviews for summary generation")
            
            # Get scenic spot information
            scenic_spot_info = self.web3_manager.get_scenic_spot(scenic_spot_id)
            scenic_spot_name = scenic_spot_info[0][1] if scenic_spot_info else "Unknown Scenic Spot"
            
            # Build summary structure
            # Format all approved reviews
            all_reviews = []
            for review in approved_reviews:  # Take all approved reviews
                content = review[2]  # Third element is content
                rating = review[3]  # Fourth element is rating
                
                # Parse content to JSON object and extract actual content
                try:
                    content_json = json.loads(content)
                    actual_content = content_json.get("content", "")
                except json.JSONDecodeError:
                    actual_content = content
                
                all_reviews.append(f"content: {actual_content},EvaluationScore: {rating}")
            
            reviews_str = ";".join(all_reviews)
            summary_input = f"ScenicSpotName:{scenic_spot_name},top20reviews: {reviews_str}"
            
            logger.info(f"----------------------summary_input: {summary_input}")
            
            # Generate AI summary
            summary_content = await self._generate_ai_summary(summary_input)
            
            if not summary_content:
                logger.error(f"Failed to generate summary for scenic_spot_id: {scenic_spot_id}")
                return False, "Failed to generate summary"
            
            logger.info(f"Generated summary: {summary_content}")
            
            logger.info(f"Using review_ids: {review_ids}")
            
            # Upload summary to contract
            func_call = self.web3_manager.contract.functions.uploadSummary(
                scenic_spot_id,  # scenicId
                summary_content,  # content
                review_ids,  # reviewIds array
                to_review_index  # lastReviewIndex (use toReviewIndex from event)
            )
            
            # Send transaction
            tx_hash = self.web3_manager.send_transaction(func_call)
            if tx_hash is None:
                logger.error(f"Failed to upload summary for scenic_spot_id: {scenic_spot_id}")
                return False, "Failed to send transaction"
            
            # Update summary status in the database
            last_summary = await self.db_manager.get_last_summary(scenic_spot_id)
            last_summary_id = last_summary['last_summary_id'] if last_summary else None
            new_summary_id = last_summary_id + 1 if last_summary_id else 1
            
            await self.db_manager.update_summary_generation(
                scenic_spot_id=scenic_spot_id,
                summary_id=new_summary_id,
                summary_content=summary_content
            )
            
            logger.info(f"Successfully uploaded summary for scenic_spot_id: {scenic_spot_id}")
            logger.info(f"  Oracle transaction hash: {tx_hash}")
            logger.info(f"  Summary version: {new_summary_id}")
            
            return True, f"summary_id: {new_summary_id}, tx_hash: {tx_hash}"
            
        except Exception as e:
            logger.error(f"Error processing summary_update_required event: {e}")
            return False, str(e)
    
    async def process_summary_generated(self, event_data):
        """Process SummaryGenerated event - update summary txHash"""
        try:
            scenic_spot_id = event_data['scenicSpotId']
            tx_hash = event_data['transaction_hash']  # Get the actual transaction hash from the event
            
            logger.info(f"Processing SummaryGenerated event for scenic_spot_id: {scenic_spot_id}")
            
            # Convert transaction hash string to bytes32 type required by smart contract
            tx_hash_bytes32 = self.web3_manager.web3.to_bytes(hexstr=tx_hash)
            
            # Call updateSummaryTxHash to update the summary's transaction hash
            func_call = self.web3_manager.contract.functions.updateSummaryTxHash(
                scenic_spot_id,  # scenicId
                tx_hash_bytes32  # txHash (bytes32) - use actual transaction hash
            )
            
            # Send transaction
            oracle_tx_hash = self.web3_manager.send_transaction(func_call)
            if oracle_tx_hash is None:
                logger.error(f"Failed to update summary txHash for scenic_spot_id: {scenic_spot_id}")
                return False, "Failed to send transaction"
            
            logger.info(f"Successfully updated summary txHash for scenic_spot_id: {scenic_spot_id}, tx_hash: {oracle_tx_hash}")
            
            return True, oracle_tx_hash
            
        except Exception as e:
            logger.error(f"Error processing summary_generated event: {e}")
            return False, str(e)
    
    async def _audit_review_content(self, content):
        """Review content audit logic - using Volc Engine AI"""
        # Call Volc Engine AI service for content audit
        return await self.volc_ai.audit_review_content(
            content=content,
            model_id=self.config.audit_model_id
        )
    
    async def _generate_ai_summary(self, summary_input):
        """Generate AI summary - using Volc Engine AI"""
        # Call Volc Engine AI service to generate summary
        return await self.volc_ai.generate_summary_from_input(
            summary_input=summary_input,
            model_id=self.config.summary_model_id
        )
