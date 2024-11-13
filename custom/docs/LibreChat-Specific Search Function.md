```markdown
# Step-by-Step Implementation of Vector Search Functions

## 1. Connect to Database
```bash
docker exec -it LibreChat-Vectordb psql -U myuser -d mydatabase
```

## 2. Create Main Search Function

```sql
CREATE OR REPLACE FUNCTION search_embeddings(
    query_embedding vector(1536),
    similarity_threshold FLOAT DEFAULT 0.7,
    max_results INTEGER DEFAULT 7,
    metadata_filter JSONB DEFAULT NULL
) RETURNS TABLE (
    id BIGINT,
    content TEXT,
    similarity FLOAT,
    metadata JSONB
) LANGUAGE plpgsql AS $$
BEGIN
    SET LOCAL parallel_tuple_cost = 0;
    SET LOCAL parallel_setup_cost = 0;

    RETURN QUERY
    SELECT
        e.id,
        e.content,
        1 - (e.embedding <=> query_embedding) as similarity,
        e.metadata
    FROM embeddings e
    WHERE 1 - (e.embedding <=> query_embedding) > similarity_threshold
        AND (metadata_filter IS NULL OR e.metadata @> metadata_filter)
    ORDER BY e.embedding <=> query_embedding
    LIMIT max_results;
END;
$$
;IT max_results;
END;
$$
;
```

## 3. Create Hybrid Index Function

```sql
CREATE OR REPLACE FUNCTION create_hybrid_index(field_name TEXT)
RETURNS VOID AS $$
BEGIN
    EXECUTE format(
        'CREATE INDEX CONCURRENTLY idx_%s_hybrid ON embeddings 
         USING ivfflat (embedding vector_cosine_ops) 
         INCLUDE (%s) 
         WITH (lists = 1000)',
        field_name, field_name
    );
END;
$$
 LANGUAGE plpgsql;ts;
END;
$$
;
;
END;
$$
;
```

## 4. Verify Functions

```sql
-- Check if functions exist
\df search_embeddings
\df create_hybrid_index
```

## 5. Test Search Function

```sql
-- Get a sample embedding to test with
WITH sample AS (
    SELECT embedding FROM embeddings LIMIT 1
)
SELECT * FROM search_embeddings(
    (SELECT embedding FROM sample),
    0.7,
    7
);
```

## 6. Create Common Hybrid Indexes (Optional)

```sql
-- Create hybrid index for content field
SELECT create_hybrid_index('content');

-- Create hybrid index for metadata
SELECT create_hybrid_index('metadata');
```

## 7. Monitor Performance

```sql
SELECT 
    schemaname,
    relname as table_name,
    indexrelname as index_name,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname = 'embeddings';
```

## Important Notes:

- Default max_results is set to 7 to match LibreChat's SIMILARITY_TOP_K
- The similarity threshold of 0.7 is a good starting point
- Hybrid indexes are optional but can improve performance
- These functions work with the previously created table structure
- Parallel query execution is enabled for your 16-core system

## Exit PostgreSQL

```sql
\q
```

```

Citations:
[1] https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/25641359/ea7445a1-7dc2-4c30-9c6c-5afe37d1532a/paste.txt
