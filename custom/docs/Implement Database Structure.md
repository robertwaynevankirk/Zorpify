

## Implementation Steps for Database Structure

```bash
# Connect to the running container
docker exec -it LibreChat-Vectordb psql -U myuser -d mydatabase
```

```sql
-- Run these first
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

```sql
-- Create the embeddings table with optimal settings for LibreChat
CREATE TABLE IF NOT EXISTS embeddings (
 id BIGSERIAL PRIMARY KEY,
 content_hash TEXT NOT NULL,
 embedding vector(1536) NOT NULL,
 metadata JSONB,
 content TEXT,
 created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT unique_content UNIQUE (content_hash)
);
```

```sql
-- Create the IVFFlat index for vector similarity search
CREATE INDEX idx_embedding_ivfflat ON embeddings 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 1000);

```

```sql
-- Create supporting indexes
CREATE INDEX idx_content_hash ON embeddings (content_hash);
CREATE INDEX idx_metadata ON embeddings USING GIN (metadata);
```

```sql
-- Optimize table settings
ALTER TABLE embeddings SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_analyze_scale_factor = 0.02,
    parallel_workers = 8
);
```

```sql
-- Verify table creation
\d embeddings
```

```sql
-- Verify indexes
\di
```

```sql
-- Verify extensions
\dx
```

```
DROP TABLE IF EXISTS langchain_pg_collection CASCADE;
DROP TABLE IF EXISTS langchain_pg_embedding CASCADE;
```



**Important Notes:**

These commands should be run in sequence- The database name (`mydatabase`) and user (`myuser`) match the defaults in your docker-compose.vectordb.yml- The vector dimension (1536) matches the OpenAI text-embedding-3-large model specified in your configuration- The parallel_workers setting is optimized for your 16-core processor- No need to implement partitioning as it's not supported in the current LibreChat RAG implementation- The IVFFlat index with 1000 lists is a good balance for the expected data size in LibreChatTo exit the PostgreSQL prompt after completing these steps:

```sql
\q
```

These settings provide an optimized foundation for LibreChat's vector storage while staying within the constraints of its RAG implementation. 
