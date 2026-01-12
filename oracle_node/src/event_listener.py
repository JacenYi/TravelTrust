import logging
import asyncio
import json
from web3 import AsyncWeb3, Web3
from src.config import Config
from src.db_manager import DatabaseManager
from src.business_logic import BusinessLogic

logger = logging.getLogger(__name__)

class EventListener:
    def __init__(self, config: Config, db_manager: DatabaseManager, business_logic: BusinessLogic):
        self.config = config
        self.db_manager = db_manager
        self.business_logic = business_logic
        self.web3 = None
        self.contract = None
        self.listening = False
        self.reconnect_delay = 5  # seconds
        self.max_reconnect_attempts = 10
        self.filters = []  # Used to store all filters
    
    async def connect(self):
        try:
            # Create async Web3 connection
            self.web3 = AsyncWeb3(AsyncWeb3.AsyncHTTPProvider(self.config.rpc_url))
            
            # Check connection
            if not await self.web3.is_connected():
                raise Exception("Failed to connect to RPC endpoint")
            
            logger.info(f"Connected to blockchain (async): {self.config.rpc_url}")
            
            # Load contract
            with open(self.config.abi_path, 'r') as f:
                abi = f.read()
            
            self.contract = self.web3.eth.contract(
                address=Web3.to_checksum_address(self.config.scenic_review_system_address),
                abi=abi
            )
            
            logger.info(f"Contract loaded (async): {self.config.scenic_review_system_address}")
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize async Web3 connection: {e}")
            return False
    
    async def start_listening(self):
        self.listening = True
        reconnect_attempts = 0
        
        while self.listening and reconnect_attempts < self.max_reconnect_attempts:
            try:
                if not await self.web3.is_connected():
                    logger.warning("Blockchain connection lost, attempting to reconnect...")
                    if not await self.connect():
                        reconnect_attempts += 1
                        await asyncio.sleep(self.reconnect_delay)
                        continue
                    reconnect_attempts = 0
                
                # Get latest block number
                current_block = await self.web3.eth.block_number
                logger.info(f"Current block: {current_block}")
                
                # Use concurrent tasks to start all event listeners
                tasks = []
                
                # Calculate from which block to start listening (use a larger range to ensure previous events are captured)
                from_block = max(0, current_block - 500)  # Start listening from the most recent 500 blocks
                
                # Listen for ReviewSubmitted events
                logger.info("Starting to listen for ReviewSubmitted events...")
                tasks.append(asyncio.create_task(self._listen_for_events(
                    self.contract.events.ReviewSubmitted,
                    from_block,  # Start listening from earlier blocks to ensure previous events are captured
                    self._handle_review_submitted
                )))
                
                # Listen for SummaryUpdateRequired events
                logger.info("Starting to listen for SummaryUpdateRequired events...")
                tasks.append(asyncio.create_task(self._listen_for_events(
                    self.contract.events.SummaryUpdateRequired,
                    from_block,
                    self._handle_summary_update_required
                )))
                
                # Listen for ReviewApproved events
                logger.info("Starting to listen for ReviewApproved events...")
                tasks.append(asyncio.create_task(self._listen_for_events(
                    self.contract.events.ReviewApproved,
                    from_block,
                    self._handle_review_approved
                )))
                
                # Listen for SummaryGenerated events
                logger.info("Starting to listen for SummaryGenerated events...")
                tasks.append(asyncio.create_task(self._listen_for_events(
                    self.contract.events.SummaryGenerated,
                    from_block,
                    self._handle_summary_generated
                )))
                
                # Wait for all tasks to complete (this will never happen as they are infinite loops)
                # But we will stop them when self.listening becomes False
                await asyncio.gather(*tasks, return_exceptions=True)
                
            except Exception as e:
                logger.error(f"Error in event listener: {e}")
                reconnect_attempts += 1
                await asyncio.sleep(self.reconnect_delay)
        
        if reconnect_attempts >= self.max_reconnect_attempts:
            logger.critical("Max reconnection attempts reached, event listener stopped")
    
    async def stop_listening(self):
        self.listening = False
        logger.info("Event listener stopped")
    
    async def _listen_for_events(self, event, from_block, handler):
        try:
            # Get historical events
            events = await event.get_logs(from_block=from_block)
            logger.info(f"Found {len(events)} historical {event.event_name} events")
            
            # Process historical events
            for evt in events:
                await handler(evt)
            
            # Use polling mechanism to listen for new events (because Mantle Sepolia RPC doesn't support persistent filters)
            logger.info(f"Starting to poll for {event.event_name} events from block {from_block}")
            
            last_processed_block = from_block
            while self.listening:
                try:
                    # Get latest block number
                    current_block = await self.web3.eth.block_number
                    
                    if current_block > last_processed_block:
                        # Ensure from_block is not greater than to_block
                        query_from_block = last_processed_block + 1
                        query_to_block = current_block
                        
                        if query_from_block > query_to_block:
                            logger.warning(f"Invalid block range: from_block={query_from_block} > to_block={query_to_block}")
                            last_processed_block = current_block
                            await asyncio.sleep(5)
                            continue
                        
                        # Get events in new blocks, add error handling
                        try:
                            new_events = await event.get_logs(
                                from_block=query_from_block,
                                to_block=query_to_block
                            )
                            logger.debug(f"Found {len(new_events)} new {event.event_name} events in blocks {query_from_block} to {query_to_block}")
                            
                            # Process new events
                            for evt in new_events:
                                await handler(evt)
                            
                            last_processed_block = current_block
                        except Exception as e:
                            # Handle "block not found" and "invalid block range params" errors
                            error_msg = str(e)
                            if "block not found" in error_msg or "invalid block range params" in error_msg:
                                logger.warning(f"Block range error, adjusting: {error_msg}")
                                # Only process up to the current latest block
                                last_processed_block = current_block
                            else:
                                # Other errors, re-raise
                                raise
                    
                    # Check for new blocks every 5 seconds
                    await asyncio.sleep(5)
                    
                except Exception as e:
                    logger.error(f"Error polling for {event.event_name} events: {e}")
                    # Continue after a brief pause
                    await asyncio.sleep(1)
                
        except Exception as e:
            logger.error(f"Error listening for {event.event_name} events: {e}")
    
    async def _handle_review_submitted(self, event):
        try:
            # Event name is fixed as ReviewSubmitted
            event_name = "ReviewSubmitted"
            
            # Generate unique event ID
            event_id = f"{event_name}_{event.transactionHash.hex()}_{event.logIndex}"
            
            # Print event processing start log, regardless of whether it has been processed before
            logger.info(f"Starting to process ReviewSubmitted event: {event_id}")
            
            # Check if it has been processed
            if await self.db_manager.is_event_processed(event_id):
                logger.info(f"Event already processed, skipping: {event_id}")
                return
            
            logger.info(f"Processing ReviewSubmitted event: {event_id}")
            
            # Print the structure of the event object to understand the actual property names
            logger.info(f"Event args: {dir(event.args)}")
            logger.info(f"Event args dict: {event.args.__dict__}")
            
            # Extract directly available properties from the event
            review_id = event.args.reviewId
            scenic_id = event.args.scenicId
            user = event.args.user
            
            # Call the contract's getReview method to get the complete review information
            logger.info(f"Calling getReview for review_id: {review_id}")
            try:
                # Execute synchronous method in a separate thread to avoid blocking the async event loop
                review = await asyncio.to_thread(self.business_logic.web3_manager.get_review_by_id, review_id)
                logger.info(f"Review details: {review}")
                
                # Extract complete review information
                if review is not None:
                    content = review[2]  # Review struct: (user, scenicId, content, rating, status, rewarded, timestamp, submitTxHash, approveTxHash)
                    rating = review[3]
                    timestamp = review[6]
                    
                    # Ensure content is a string type, handle bytes type case
                    if isinstance(content, bytes):
                        content = content.decode('utf-8')
                        
                    logger.info(f"Extracted content: '{content}', rating: {rating}, timestamp: {timestamp}")
                else:
                    logger.error(f"get_review_by_id returned None for review_id: {review_id}")
                    # If the retrieval fails, use default values
                    content = ''
                    rating = 0
                    timestamp = 0
                    logger.info(f"Using default values: content: '{content}', rating: {rating}, timestamp: {timestamp}")
            except Exception as e:
                logger.error(f"Failed to get review details: {e}")
                # If retrieval fails, use default values
                content = ''
                rating = 0
                timestamp = 0
                logger.info(f"Using default values due to error: content: '{content}', rating: {rating}, timestamp: {timestamp}")
            
            # Build complete event data
            event_data = {
                'reviewId': review_id,
                'scenicSpotId': scenic_id,
                'user': user,
                'content': content,
                'rating': rating,
                'submittedAt': timestamp,
                'transaction_hash': event.transactionHash.hex()  # Add transaction hash
            }
            
            # Record the event as processing
            await self.db_manager.mark_event_as_processed(
                event_id=event_id,
                event_type=event_name,
                transaction_hash=event.transactionHash.hex(),
                block_number=event.blockNumber,
                event_data=json.dumps(event_data),
                status='processing'
            )
            
            # Process business logic
            success, result = await self.business_logic.process_review_submitted(event_data)
            
            # Update event status
            status = 'success' if success else 'failed'
            await self.db_manager.mark_event_as_processed(
                event_id=event_id,
                event_type=event_name,  # Fix: Use the previously defined event_name variable
                transaction_hash=event.transactionHash.hex(),
                block_number=event.blockNumber,
                event_data=json.dumps(event_data),
                status=status,
                result=str(result)
            )
            
            logger.info(f"Processed ReviewSubmitted event: {event_id}, status: {status}")
            
        except Exception as e:
            logger.error(f"Error handling ReviewSubmitted event: {e}")
    
    async def _handle_summary_update_required(self, event):
        try:
            # Event name is fixed as SummaryUpdateRequired
            event_name = "SummaryUpdateRequired"
            
            # Generate unique event ID
            event_id = f"{event_name}_{event.transactionHash.hex()}_{event.logIndex}"
            
            # Check if it has been processed
            if await self.db_manager.is_event_processed(event_id):
                logger.info(f"Event already processed: {event_id}")
                return
            
            logger.info(f"Processing SummaryUpdateRequired event: {event_id}")
            
            # Extract event data
            event_data = {
                'scenicSpotId': event.args.scenicId,
                'fromReviewIndex': event.args.fromReviewIndex,
                'toReviewIndex': event.args.toReviewIndex,
                'currentLastReviewIndex': event.args.currentLastReviewIndex
            }
            
            # Record the event as processing
            await self.db_manager.mark_event_as_processed(
                event_id=event_id,
                event_type=event_name,
                transaction_hash=event.transactionHash.hex(),
                block_number=event.blockNumber,
                event_data=json.dumps(event_data),
                status='processing'
            )
            
            # Process business logic
            success, result = await self.business_logic.process_summary_update_required(event_data)
            
            # Update event status
            status = 'success' if success else 'failed'
            await self.db_manager.mark_event_as_processed(
                event_id=event_id,
                event_type=event_name,
                transaction_hash=event.transactionHash.hex(),
                block_number=event.blockNumber,
                event_data=json.dumps(event_data),
                status=status,
                result=str(result)
            )
            
            logger.info(f"Processed SummaryUpdateRequired event: {event_id}, status: {status}")
            
        except Exception as e:
            logger.error(f"Error handling SummaryUpdateRequired event: {e}")
    
    async def _handle_review_approved(self, event):
        try:
            # Event name is fixed as ReviewApproved
            event_name = "ReviewApproved"
            
            # Generate unique event ID
            event_id = f"{event_name}_{event.transactionHash.hex()}_{event.logIndex}"
            
            # Check if it has been processed
            if await self.db_manager.is_event_processed(event_id):
                logger.debug(f"Event already processed: {event_id}")
                return
            
            logger.info(f"Processing ReviewApproved event: {event_id}")
            
            # Extract event data - only access properties that actually exist in the event
            # ReviewApproved event only contains reviewId and approved properties
            event_data = {
                'reviewId': event.args.reviewId,
                'isApproved': event.args.approved,  # Use the correct property name 'approved'
                'transaction_hash': event.transactionHash.hex()  # Add transaction hash
            }
            
            # Record the event as processing
            await self.db_manager.mark_event_as_processed(
                event_id=event_id,
                event_type=event_name,
                transaction_hash=event.transactionHash.hex(),
                block_number=event.blockNumber,
                event_data=json.dumps(event_data),
                status='processing'
            )
            
            # Process business logic
            success, result = await self.business_logic.process_review_approved(event_data)
            
            # Update event status
            status = 'success' if success else 'failed'
            await self.db_manager.mark_event_as_processed(
                event_id=event_id,
                event_type=event_name,
                transaction_hash=event.transactionHash.hex(),
                block_number=event.blockNumber,
                event_data=json.dumps(event_data),
                status=status,
                result=str(result)
            )
            
            logger.info(f"Processed ReviewApproved event: {event_id}, status: {status}")
            
        except Exception as e:
            logger.error(f"Error handling ReviewApproved event: {e}")
    
    async def _handle_summary_generated(self, event):
        try:
            # Event name is fixed as SummaryGenerated
            event_name = "SummaryGenerated"
            
            # Generate unique event ID
            event_id = f"{event_name}_{event.transactionHash.hex()}_{event.logIndex}"
            
            # Check if it has been processed
            if await self.db_manager.is_event_processed(event_id):
                logger.debug(f"Event already processed: {event_id}")
                return
            
            logger.info(f"Processing SummaryGenerated event: {event_id}")
            
            # Extract event data
            event_data = {
                'scenicSpotId': event.args.scenicId,
                'transaction_hash': event.transactionHash.hex()  # Add transaction hash
            }
            
            # Record the event as processing
            await self.db_manager.mark_event_as_processed(
                event_id=event_id,
                event_type=event_name,
                transaction_hash=event.transactionHash.hex(),
                block_number=event.blockNumber,
                event_data=json.dumps(event_data),
                status='processing'
            )
            
            # Process business logic
            success, result = await self.business_logic.process_summary_generated(event_data)
            
            # Update event status
            status = 'success' if success else 'failed'
            await self.db_manager.mark_event_as_processed(
                event_id=event_id,
                event_type=event_name,
                transaction_hash=event.transactionHash.hex(),
                block_number=event.blockNumber,
                event_data=json.dumps(event_data),
                status=status,
                result=str(result)
            )
            
            logger.info(f"Processed SummaryGenerated event: {event_id}, status: {status}")
            
        except Exception as e:
            logger.error(f"Error handling SummaryGenerated event: {e}")
