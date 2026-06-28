import sqlite3
import time


class MemoryStore:
    """
    Lightweight persistent learning memory.
    Stores:
    - prompt
    - intent
    - model
    - confidence
    - success score (manual or implicit later)
    """

    def __init__(self, db_path="moe_memory.db"):
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self._init_db()

    def _init_db(self):
        cursor = self.conn.cursor()
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS memory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            prompt TEXT,
            intent TEXT,
            model TEXT,
            confidence REAL,
            score REAL DEFAULT 0,
            timestamp REAL
        )
        """)
        self.conn.commit()

    def add(self, prompt, intent, model, confidence, score=0.0):
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT INTO memory (prompt, intent, model, confidence, score, timestamp)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (prompt, intent, model, confidence, score, time.time()))
        self.conn.commit()

    def get_recent(self, limit=20):
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT prompt, intent, model, confidence, score
            FROM memory
            ORDER BY timestamp DESC
            LIMIT ?
        """, (limit,))
        return cursor.fetchall()

    def update_score(self, memory_id, score):
        cursor = self.conn.cursor()
        cursor.execute("""
            UPDATE memory SET score = ? WHERE id = ?
        """, (score, memory_id))
        self.conn.commit()