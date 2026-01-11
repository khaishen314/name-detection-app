CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- Set similarity threshold
SET pg_trgm.similarity_threshold = 0.6;
SET enable_seqscan = OFF;
