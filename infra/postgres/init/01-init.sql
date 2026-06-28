CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  text TEXT NOT NULL,
  source TEXT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  vector_id TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_memories_created_at
  ON memories (created_at);

CREATE INDEX IF NOT EXISTS idx_memories_source
  ON memories (source);

CREATE INDEX IF NOT EXISTS idx_memories_metadata
  ON memories USING GIN (metadata);
