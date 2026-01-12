import aiosqlite
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

class DatabaseManager:
    def __init__(self, db_path):
        self.db_path = db_path
        self.conn = None
    
    async def connect(self):
        try:
            self.conn = await aiosqlite.connect(self.db_path)
            await self._create_tables()
            logger.info(f"Connected to database: {self.db_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            return False
    
    async def close(self):
        if self.conn:
            await self.conn.close()
            logger.info("Database connection closed")
    
    async def _create_tables(self):
        try:
            # Event processing table - for idempotency control
            await self.conn.execute('''
                CREATE TABLE IF NOT EXISTS processed_events (
                    event_id TEXT PRIMARY KEY,
                    event_type TEXT NOT NULL,
                    transaction_hash TEXT NOT NULL,
                    block_number INTEGER NOT NULL,
                    event_data TEXT,
                    status TEXT NOT NULL,
                    processed_at TIMESTAMP,
                    result TEXT
                )
            ''')
            
            # Transaction records - for tracking Oracle-initiated transactions
            await self.conn.execute('''
                CREATE TABLE IF NOT EXISTS oracle_transactions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    original_event_id TEXT,
                    transaction_hash TEXT NOT NULL,
                    function_name TEXT NOT NULL,
                    parameters TEXT,
                    status TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    confirmed_at TIMESTAMP
                )
            ''')
            
            # Review audit status table
            await self.conn.execute('''
                CREATE TABLE IF NOT EXISTS review_audit (
                    review_id INTEGER PRIMARY KEY,
                    scenic_spot_id INTEGER NOT NULL,
                    user_address TEXT NOT NULL,
                    review_content TEXT NOT NULL,
                    rating INTEGER NOT NULL,
                    is_approved BOOLEAN,
                    audit_reason TEXT,
                    processed_at TIMESTAMP
                )
            ''')
            
            # Summary generation status table
            await self.conn.execute('''
                CREATE TABLE IF NOT EXISTS summary_generation (
                    scenic_spot_id INTEGER PRIMARY KEY,
                    last_summary_id INTEGER,
                    last_summary_content TEXT,
                    last_generated_at TIMESTAMP,
                    next_generation_at TIMESTAMP
                )
            ''')
            
            await self.conn.commit()
            logger.info("Database tables created/updated successfully")
            
        except Exception as e:
            logger.error(f"Failed to create database tables: {e}")
            await self.conn.rollback()
    
    async def is_event_processed(self, event_id):
        try:
            async with self.conn.execute(
                "SELECT status FROM processed_events WHERE event_id = ?", 
                (event_id,)
            ) as cursor:
                row = await cursor.fetchone()
                return row is not None
        except Exception as e:
            logger.error(f"Failed to check if event is processed: {e}")
            return False
    
    async def mark_event_as_processed(self, event_id, event_type, transaction_hash, block_number, event_data, status, result=None):
        try:
            await self.conn.execute('''
                INSERT OR REPLACE INTO processed_events 
                (event_id, event_type, transaction_hash, block_number, event_data, status, processed_at, result)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                event_id, event_type, transaction_hash, block_number, 
                event_data, status, datetime.now(), result
            ))
            await self.conn.commit()
            logger.info(f"Event marked as processed: {event_id}, status: {status}")
            return True
        except Exception as e:
            logger.error(f"Failed to mark event as processed: {e}")
            await self.conn.rollback()
            return False
    
    async def record_oracle_transaction(self, original_event_id, transaction_hash, function_name, parameters, status):
        try:
            await self.conn.execute('''
                INSERT INTO oracle_transactions 
                (original_event_id, transaction_hash, function_name, parameters, status)
                VALUES (?, ?, ?, ?, ?)
            ''', (original_event_id, transaction_hash, function_name, parameters, status))
            await self.conn.commit()
            logger.info(f"Oracle transaction recorded: {transaction_hash}, function: {function_name}")
            return True
        except Exception as e:
            logger.error(f"Failed to record Oracle transaction: {e}")
            await self.conn.rollback()
            return False
    
    async def update_transaction_status(self, transaction_hash, status, confirmed_at=None):
        try:
            if confirmed_at is None:
                await self.conn.execute(
                    "UPDATE oracle_transactions SET status = ? WHERE transaction_hash = ?",
                    (status, transaction_hash)
                )
            else:
                await self.conn.execute(
                    "UPDATE oracle_transactions SET status = ?, confirmed_at = ? WHERE transaction_hash = ?",
                    (status, confirmed_at, transaction_hash)
                )
            await self.conn.commit()
            logger.info(f"Transaction status updated: {transaction_hash}, status: {status}")
            return True
        except Exception as e:
            logger.error(f"Failed to update transaction status: {e}")
            await self.conn.rollback()
            return False
    
    async def save_review_audit(self, review_id, scenic_spot_id, user_address, review_content, rating, is_approved, audit_reason=None):
        try:
            await self.conn.execute('''
                INSERT OR REPLACE INTO review_audit 
                (review_id, scenic_spot_id, user_address, review_content, rating, is_approved, audit_reason, processed_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                review_id, scenic_spot_id, user_address, review_content, 
                rating, is_approved, audit_reason, datetime.now()
            ))
            await self.conn.commit()
            logger.info(f"Review audit saved: {review_id}, approved: {is_approved}")
            return True
        except Exception as e:
            logger.error(f"Failed to save review audit: {e}")
            await self.conn.rollback()
            return False
    
    async def get_review_audit(self, review_id):
        try:
            async with self.conn.execute(
                "SELECT * FROM review_audit WHERE review_id = ?", 
                (review_id,)
            ) as cursor:
                row = await cursor.fetchone()
                if row:
                    return {
                        'review_id': row[0],
                        'scenic_spot_id': row[1],
                        'user_address': row[2],
                        'review_content': row[3],
                        'rating': row[4],
                        'is_approved': row[5],
                        'audit_reason': row[6],
                        'processed_at': row[7]
                    }
                return None
        except Exception as e:
            logger.error(f"Failed to get review audit: {e}")
            return None
    
    async def update_summary_generation(self, scenic_spot_id, summary_id=None, summary_content=None):
        try:
            now = datetime.now()
            await self.conn.execute('''
                INSERT OR REPLACE INTO summary_generation 
                (scenic_spot_id, last_summary_id, last_summary_content, last_generated_at, next_generation_at)
                VALUES (?, ?, ?, ?, datetime('now', '+1 day'))
            ''', (scenic_spot_id, summary_id, summary_content, now))
            await self.conn.commit()
            logger.info(f"Summary generation updated for scenic spot: {scenic_spot_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to update summary generation: {e}")
            await self.conn.rollback()
            return False
    
    async def get_last_summary(self, scenic_spot_id):
        try:
            async with self.conn.execute(
                "SELECT last_summary_id, last_summary_content, last_generated_at FROM summary_generation WHERE scenic_spot_id = ?", 
                (scenic_spot_id,)
            ) as cursor:
                row = await cursor.fetchone()
                if row:
                    return {
                        'last_summary_id': row[0],
                        'last_summary_content': row[1],
                        'last_generated_at': row[2]
                    }
                return None
        except Exception as e:
            logger.error(f"Failed to get last summary: {e}")
            return None
