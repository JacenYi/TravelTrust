import os
from dotenv import load_dotenv
import logging
import pathlib

class Config:
    def __init__(self):
        # Load environment variables
        load_dotenv()
        
        # Mantle Network Configuration
        self.rpc_url = os.getenv("RPC_URL", "https://rpc.sepolia.mantle.xyz")
        self.websocket_url = os.getenv("WEBSOCKET_URL", "wss://ws.sepolia.mantle.xyz")
        self.chain_id = int(os.getenv("CHAIN_ID", "5003"))
        
        # Oracle Private Key
        self.oracle_private_key = os.getenv("ORACLE_PRIVATE_KEY")
        if not self.oracle_private_key:
            raise ValueError("ORACLE_PRIVATE_KEY environment variable is required")
        
        # Contract Addresses
        self.scenic_review_system_address = os.getenv("SCENIC_REVIEW_SYSTEM_ADDRESS")
        if not self.scenic_review_system_address:
            raise ValueError("SCENIC_REVIEW_SYSTEM_ADDRESS environment variable is required")
        
        # Application Configuration
        self.log_level = os.getenv("LOG_LEVEL", "INFO")
        self.log_file = os.getenv("LOG_FILE", "logs/oracle.log")
        
        # ABI Path Configuration
        self.abi_path = os.getenv("ABI_PATH", "src/abi/ScenicReviewSystem.json")
        
        # Database Configuration
        self.db_path = os.getenv("DB_PATH", "db/oracle.db")
        
        # Transaction Configuration
        self.gas_multiplier = float(os.getenv("GAS_MULTIPLIER", "1.5"))
        self.max_retries = int(os.getenv("MAX_RETRIES", "3"))
        self.retry_delay = int(os.getenv("RETRY_DELAY", "5"))
        
        # Event Listening Configuration
        self.block_batch_size = int(os.getenv("BLOCK_BATCH_SIZE", "1000"))
        self.max_parallel_events = int(os.getenv("MAX_PARALLEL_EVENTS", "10"))
        
        # Volc Engine AI Configuration
        self.volc_ai_api_key = os.getenv("VOLC_AI_API_KEY")
        self.audit_model_id = os.getenv("AUDIT_MODEL_ID")
        self.summary_model_id = os.getenv("SUMMARY_MODEL_ID")
        self.volc_ai_api_url = os.getenv("VOLC_AI_API_URL", "YOU_AI_URL")
        
        # Setup logging
        self.setup_logging()
    
    def setup_logging(self):
        """Configure logging system"""
        # Ensure log directory exists
        log_dir = os.path.dirname(self.log_file)
        if log_dir and not os.path.exists(log_dir):
            os.makedirs(log_dir)
        
        # Configure logging
        logging.basicConfig(
            level=getattr(logging, self.log_level),
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.log_file),
                logging.StreamHandler()
            ]
        )
        
        # Set web3 log level
        logging.getLogger("web3").setLevel(logging.WARNING)
        logging.getLogger("urllib3").setLevel(logging.WARNING)

# Create global configuration instance
config = Config()