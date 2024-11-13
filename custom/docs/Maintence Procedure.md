```markdown
# LibreChat Vector Database Maintenance Setup

## 1. Connect to Database
```bash
docker exec -it LibreChat-Vectordb psql -U myuser -d mydatabase
```

## 2. Create Maintenance Procedure

```sql
CREATE OR REPLACE PROCEDURE maintain_librechat_vectors()
LANGUAGE plpgsql AS $$
BEGIN
    -- Update statistics
    ANALYZE VERBOSE embeddings;

    -- Vacuum dead tuples
    VACUUM (ANALYZE, VERBOSE) embeddings;

    -- Reindex
    REINDEX INDEX CONCURRENTLY idx_embedding_ivfflat;
END;
$$;
```

## 3. Create Monitoring View

```sql
CREATE MATERIALIZED VIEW librechat_vector_stats AS
SELECT 
    count(*) as total_vectors,
    pg_size_pretty(pg_total_relation_size('embeddings')) as total_size,
    pg_size_pretty(pg_indexes_size('embeddings')) as index_size
WITH DATA;
```

## 4. Verify Setup

```sql
-- Check if procedure exists
\df maintain_librechat_vectors

-- Check if view exists
\dv librechat_vector_stats
```

## 5. Test Maintenance Procedure

```sql
-- Run maintenance
CALL maintain_librechat_vectors();

-- View statistics
SELECT * FROM librechat_vector_stats;
```

## 6. Schedule Regular Maintenance (Optional)

```sql
-- Create extension if not exists
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule maintenance for 2 AM daily
SELECT cron.schedule('0 2 * * *', 'CALL maintain_librechat_vectors()');
```

## Important Notes:

- Run maintenance during low-usage periods
- Monitor disk space before running VACUUM
- The REINDEX operation requires additional disk space
- Maintenance procedure is safe to run while system is online
- View refresh needs to be done manually or scheduled

## Exit PostgreSQL

```sql
\q
```

```

Citations:
[1] https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/25641359/ea7445a1-7dc2-4c30-9c6c-5afe37d1532a/paste.txt
