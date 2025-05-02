-- Create threads table
CREATE TABLE IF NOT EXISTS threads (
    id UUID PRIMARY KEY,
    title TEXT NOT NULL,
    proposal_cid TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create credential_links table
CREATE TABLE IF NOT EXISTS credential_links (
    id UUID PRIMARY KEY,
    thread_id UUID NOT NULL REFERENCES threads(id) ON DELETE CASCADE,
    credential_cid TEXT NOT NULL,
    linked_by TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_threads_created_at ON threads(created_at);
CREATE INDEX IF NOT EXISTS idx_credential_links_thread_id ON credential_links(thread_id);
CREATE INDEX IF NOT EXISTS idx_credential_links_created_at ON credential_links(created_at); 