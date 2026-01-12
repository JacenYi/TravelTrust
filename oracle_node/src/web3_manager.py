import os
import logging
from web3 import Web3
from src.config import Config

logger = logging.getLogger(__name__)

class Web3Manager:
    def __init__(self, config: Config):
        self.config = config
        self.web3 = None
        self.oracle_account = None
        self.contract = None
        self.local_nonce = None  # Local nonce counter
        
    def connect(self):
        try:
            # Create Web3 connection
            self.web3 = Web3(Web3.HTTPProvider(self.config.rpc_url))
            
            # Check connection status
            if not self.web3.is_connected():
                raise Exception("Failed to connect to RPC endpoint")
            
            logger.info(f"Connected to blockchain: {self.config.rpc_url}")
            
            # Load Oracle account
            self.oracle_account = self.web3.eth.account.from_key(self.config.oracle_private_key)
            logger.info(f"Oracle account loaded: {self.oracle_account.address}")
            
            # Load contract
            with open(self.config.abi_path, 'r') as f:
                abi = f.read()
            
            self.contract = self.web3.eth.contract(
                address=self.web3.to_checksum_address(self.config.scenic_review_system_address),
                abi=abi
            )
            
            logger.info(f"Contract loaded: {self.config.scenic_review_system_address}")
            
            # Verify Oracle address in contract
            try:
                contract_oracle_address = self.contract.functions.oracleAddress().call()
                logger.info(f"Contract oracle address: {contract_oracle_address}")
                logger.info(f"Oracle account matches contract oracle address: {contract_oracle_address == self.oracle_account.address}")
            except Exception as e:
                logger.error(f"Failed to verify contract oracle address: {e}")
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize Web3 connection: {e}")
            return False
    
    def get_nonce(self):
        try:
            # If local nonce doesn't exist, get the latest value from the blockchain
            if self.local_nonce is None:
                self.local_nonce = self.web3.eth.get_transaction_count(self.oracle_account.address)
                logger.info(f"Initialized local nonce from blockchain: {self.local_nonce}")
            return self.local_nonce
        except Exception as e:
            logger.error(f"Failed to get nonce: {e}")
            return None
    
    def estimate_gas(self, tx):
        try:
            return self.web3.eth.estimate_gas(tx)
        except Exception as e:
            logger.error(f"Failed to estimate gas: {e}")
            return None
    
    def send_transaction(self, func_call, value=0, retry_count=3):
        try:
            # Get Oracle account address
            oracle_address = self.oracle_account.address
            logger.info(f"Sending transaction from Oracle address: {oracle_address}")
            
            # Verify Oracle address in contract
            try:
                contract_oracle_address = self.contract.functions.oracleAddress().call()
                logger.info(f"Contract oracle address: {contract_oracle_address}")
                logger.info(f"Oracle account matches contract oracle address: {contract_oracle_address == oracle_address}")
            except Exception as e:
                logger.error(f"Failed to verify contract oracle address: {e}")
            
            for attempt in range(retry_count):
                # Build transaction
                nonce = self.get_nonce()
                if nonce is None:
                    return None
                logger.info(f"Using nonce: {nonce} (attempt {attempt + 1})")
                
                # First try to build the transaction directly without using estimate_gas
                try:
                    # Build complete transaction
                    tx = func_call.build_transaction({
                        'from': oracle_address,
                        'nonce': nonce,
                        'gasPrice': self.web3.eth.gas_price,
                        'chainId': self.config.chain_id,
                        'value': value
                    })
                    
                    logger.info(f"Transaction built successfully: {tx}")
                    
                    # Sign transaction
                    signed_tx = self.web3.eth.account.sign_transaction(
                        tx, self.config.oracle_private_key
                    )
                    logger.info(f"Transaction signed successfully")
                    
                    # Send transaction - use the correct property name raw_transaction (underscore format)
                    tx_hash = self.web3.eth.send_raw_transaction(signed_tx.raw_transaction)
                    logger.info(f"Transaction sent: {tx_hash.hex()}")
                    
                    # Wait for transaction confirmation
                    tx_receipt = self.web3.eth.wait_for_transaction_receipt(tx_hash)
                    
                    if tx_receipt.status == 1:
                        logger.info(f"Transaction confirmed: {tx_hash.hex()}")
                        # Increment local nonce after success
                        if self.local_nonce is not None:
                            self.local_nonce += 1
                            logger.info(f"Updated local nonce to: {self.local_nonce}")
                        return tx_hash.hex()
                    else:
                        logger.error(f"Transaction failed: {tx_hash.hex()}")
                        # Get the reason for transaction failure
                        try:
                            # Try to get the reason for transaction failure
                            receipt = self.web3.eth.get_transaction_receipt(tx_hash)
                            logger.error(f"Transaction receipt: {receipt}")
                        except Exception as e:
                            logger.error(f"Failed to get transaction receipt: {e}")
                        return None
                        
                except Exception as e:
                    logger.error(f"Error in transaction process: {e}")
                    # Try to get more detailed error information
                    error_str = str(e)
                    if hasattr(e, 'args'):
                        error_str += f" Args: {e.args}"
                    if hasattr(e, 'data'):
                        error_str += f" Data: {e.data}"
                    logger.error(f"Detailed error: {error_str}")
                    
                    # Check if it's a nonce-related error
                    if "nonce too low" in error_str.lower() or "replacement transaction underpriced" in error_str.lower():
                        logger.error(f"Nonce error detected, resetting local nonce and retrying (attempt {attempt + 1}/{retry_count})")
                        # Reset local nonce, the next attempt will get the latest value from the blockchain
                        self.local_nonce = None
                        continue
                    elif attempt < retry_count - 1:
                        logger.error(f"Retrying transaction (attempt {attempt + 2}/{retry_count})")
                        continue
                    else:
                        logger.error(f"All retry attempts failed for transaction")
                        return None
                
        except Exception as e:
            logger.error(f"Failed to send transaction: {e}")
            # Try to get more detailed error information
            if hasattr(e, 'args'):
                logger.error(f"Error args: {e.args}")
            if hasattr(e, 'data'):
                logger.error(f"Error data: {e.data}")
            return None
    
    def get_block_number(self):
        try:
            return self.web3.eth.block_number
        except Exception as e:
            logger.error(f"Failed to get block number: {e}")
            return None
    
    def get_review_by_id(self, review_id):
        try:
            return self.contract.functions.reviews(review_id).call()
        except Exception as e:
            logger.error(f"Failed to get review {review_id}: {e}")
            return None
    
    def get_reviews_for_summary(self, scenic_spot_id, count):
        try:
            # Get a specified number of reviews for summary generation
            # Need to specify from address as Oracle address because the contract has verification
            return self.contract.functions.getReviewsForSummary(
                scenic_spot_id, count
            ).call({
                'from': self.oracle_account.address
            })
        except Exception as e:
            logger.error(f"Failed to get reviews for summary: {e}")
            return None
    
    def get_scenic_reviews(self, scenic_spot_id):
        """Get all review IDs for a specific scenic spot"""
        try:
            return self.contract.functions.scenicReviews(scenic_spot_id).call()
        except Exception as e:
            logger.error(f"Failed to get scenic reviews for id {scenic_spot_id}: {e}")
            return None
    
    def get_scenic_spot(self, scenic_spot_id):
        """Get detailed information for a specific scenic spot"""
        try:
            return self.contract.functions.getScenicSpot(scenic_spot_id).call()
        except Exception as e:
            logger.error(f"Failed to get scenic spot for id {scenic_spot_id}: {e}")
            return None
