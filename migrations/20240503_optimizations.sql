-- Add additional indexes to improve query performance
CREATE INDEX IF NOT EXISTS idx_threads_proposal_cid ON threads(proposal_cid);
CREATE INDEX IF NOT EXISTS idx_threads_updated_at ON threads(updated_at);
CREATE INDEX IF NOT EXISTS idx_credential_links_credential_cid ON credential_links(credential_cid);

-- Messages table for thread replies
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY,
    thread_id UUID NOT NULL REFERENCES threads(id) ON DELETE CASCADE,
    author_did TEXT,
    content TEXT NOT NULL,
    reply_to UUID REFERENCES messages(id) ON DELETE SET NULL,
    is_system BOOLEAN NOT NULL DEFAULT false,
    metadata TEXT, -- For system messages, stores related CIDs or other data
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Reactions table
CREATE TABLE IF NOT EXISTS reactions (
    id UUID PRIMARY KEY,
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    author_did TEXT NOT NULL,
    reaction_type TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (message_id, author_did, reaction_type)
);

-- Credentials table to track validated credentials for authorization
CREATE TABLE IF NOT EXISTS verified_credentials (
    id UUID PRIMARY KEY,
    credential_cid TEXT NOT NULL,
    subject_did TEXT NOT NULL,
    issuer_did TEXT NOT NULL,
    credential_type TEXT NOT NULL,
    valid_until TIMESTAMPTZ,
    verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (credential_cid)
);

-- Add indexes for new tables
CREATE INDEX IF NOT EXISTS idx_messages_thread_id ON messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_messages_reply_to ON messages(reply_to);
CREATE INDEX IF NOT EXISTS idx_messages_author_did ON messages(author_did);
CREATE INDEX IF NOT EXISTS idx_reactions_message_id ON reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_reactions_author_did ON reactions(author_did);
CREATE INDEX IF NOT EXISTS idx_verified_credentials_subject_did ON verified_credentials(subject_did);
CREATE INDEX IF NOT EXISTS idx_verified_credentials_type ON verified_credentials(credential_type); 