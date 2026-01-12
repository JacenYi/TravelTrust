import asyncio
import logging
import signal
import sys
from pathlib import Path

# Add project root directory to Python path
sys.path.append(str(Path(__file__).parent.parent))

from src.config import Config
from src.db_manager import DatabaseManager
from src.web3_manager import Web3Manager
from src.event_listener import EventListener
from src.business_logic import BusinessLogic

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('oracle_node.log', encoding='utf-8')
    ]
)

logger = logging.getLogger(__name__)

class OracleNode:
    def __init__(self):
        self.config = None
        self.db_manager = None
        self.web3_manager = None
        self.event_listener = None
        self.business_logic = None
        self.running = False
    
    async def initialize(self):
        """Initialize Oracle Node"""
        try:
            logger.info("Initializing Oracle Node...")
            
            # Load configuration
            self.config = Config()
            logger.info("Configuration loaded successfully")
            
            # Initialize database
            self.db_manager = DatabaseManager(self.config.db_path)
            if not await self.db_manager.connect():
                logger.error("Failed to connect to database")
                return False
            logger.info("Database connected successfully")
            
            # Initialize Web3 connection
            self.web3_manager = Web3Manager(self.config)
            if not self.web3_manager.connect():
                logger.error("Failed to connect to blockchain")
                await self.db_manager.close()
                return False
            logger.info("Blockchain connection established")
            
            # Initialize business logic
            self.business_logic = BusinessLogic(self.config, self.web3_manager, self.db_manager)
            logger.info("Business logic initialized")
            
            # Initialize event listener
            self.event_listener = EventListener(self.config, self.db_manager, self.business_logic)
            if not await self.event_listener.connect():
                logger.error("Failed to initialize event listener")
                await self.db_manager.close()
                return False
            logger.info("Event listener initialized")
            
            logger.info("Oracle Node initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize Oracle Node: {e}")
            await self.cleanup()
            return False
    
    async def start(self):
        """Start Oracle Node"""
        if not self.running:
            try:
                self.running = True
                logger.info("Starting Oracle Node...")
                
                # Start event listener
                await self.event_listener.start_listening()
                
                logger.info("Oracle Node started")
                
                # Keep running state
                while self.running:
                    await asyncio.sleep(1)
                    
            except Exception as e:
                logger.error(f"Error running Oracle Node: {e}")
                await self.cleanup()
    
    async def stop(self):
        """Stop Oracle Node"""
        if self.running:
            try:
                self.running = False
                logger.info("Stopping Oracle Node...")
                
                # Stop event listener
                if self.event_listener:
                    await self.event_listener.stop_listening()
                
                # Clean up resources
                await self.cleanup()
                
                logger.info("Oracle Node stopped")
                
            except Exception as e:
                logger.error(f"Error stopping Oracle Node: {e}")
    
    async def cleanup(self):
        """Clean up resources"""
        try:
            # Close database connection
            if self.db_manager:
                await self.db_manager.close()
            
            logger.info("Resources cleaned up")
            
        except Exception as e:
            logger.error(f"Error during cleanup: {e}")

async def main():
    """Main function"""
    oracle_node = OracleNode()
    
    # Initialize Oracle Node
    if not await oracle_node.initialize():
        logger.error("Failed to initialize Oracle Node")
        return
    
    # Set up signal handling
    def signal_handler(signum, frame):
        logger.info(f"Received signal {signum}, shutting down...")
        asyncio.create_task(oracle_node.stop())
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Start Oracle Node
    await oracle_node.start()

def ensure_directories():
    """Ensure necessary directories exist"""
    import os
    
    # Create log directory
    log_file = os.getenv("LOG_FILE", "logs/oracle.log")
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    
    # Create database directory
    db_path = os.getenv("DB_PATH", "db/oracle.db")
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    
    # Create output directory (if needed)
    os.makedirs("output", exist_ok=True)

if __name__ == "__main__":
    try:
        # Ensure necessary directories exist
        ensure_directories()
        
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("KeyboardInterrupt received, exiting...")
    except Exception as e:
        logger.error(f"Unhandled exception: {e}")
        sys.exit(1)
