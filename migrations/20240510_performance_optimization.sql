-- Performance optimizations for AgoraNet database
-- Add additional indices for better query performance

-- Add combined indices for frequently used query patterns
CREATE INDEX IF NOT EXISTS idx_messages_thread_created_at ON messages(thread_id, created_at);
CREATE INDEX IF NOT EXISTS idx_reactions_message_type ON reactions(message_id, reaction_type);
CREATE INDEX IF NOT EXISTS idx_credential_links_thread_created_at ON credential_links(thread_id, created_at);

-- Add partial index for active credentials
CREATE INDEX IF NOT EXISTS idx_active_credentials ON verified_credentials(subject_did, credential_type)
WHERE (valid_until IS NULL OR valid_until > NOW());

-- Enable table statistics gathering for query optimizer
ALTER TABLE threads SET (autovacuum_vacuum_scale_factor = 0.05);
ALTER TABLE threads SET (autovacuum_analyze_scale_factor = 0.02);
ALTER TABLE messages SET (autovacuum_vacuum_scale_factor = 0.05);
ALTER TABLE messages SET (autovacuum_analyze_scale_factor = 0.02);
ALTER TABLE reactions SET (autovacuum_vacuum_scale_factor = 0.05);
ALTER TABLE reactions SET (autovacuum_analyze_scale_factor = 0.02);

-- Create materialized view for frequently accessed thread stats
CREATE MATERIALIZED VIEW IF NOT EXISTS thread_stats AS
SELECT 
    t.id AS thread_id,
    t.title,
    t.proposal_cid,
    t.created_at,
    t.updated_at,
    COUNT(DISTINCT m.id) AS message_count,
    COUNT(DISTINCT cl.id) AS credential_link_count,
    MAX(m.created_at) AS last_message_at
FROM 
    threads t
LEFT JOIN 
    messages m ON t.id = m.thread_id
LEFT JOIN 
    credential_links cl ON t.id = cl.thread_id
GROUP BY 
    t.id, t.title, t.proposal_cid, t.created_at, t.updated_at;

-- Create index on the materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_thread_stats_thread_id ON thread_stats(thread_id);

-- Function to refresh the materialized view
CREATE OR REPLACE FUNCTION refresh_thread_stats()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY thread_stats;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to refresh the materialized view
DROP TRIGGER IF EXISTS refresh_thread_stats_trigger ON threads;
CREATE TRIGGER refresh_thread_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON threads
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_thread_stats();

DROP TRIGGER IF EXISTS refresh_thread_stats_messages_trigger ON messages;
CREATE TRIGGER refresh_thread_stats_messages_trigger
AFTER INSERT OR UPDATE OR DELETE ON messages
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_thread_stats();

DROP TRIGGER IF EXISTS refresh_thread_stats_credential_links_trigger ON credential_links;
CREATE TRIGGER refresh_thread_stats_credential_links_trigger
AFTER INSERT OR UPDATE OR DELETE ON credential_links
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_thread_stats(); 