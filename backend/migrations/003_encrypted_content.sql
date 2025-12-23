-- Create encrypted_content table
-- This table stores encrypted content as opaque binary data
-- The backend cannot read or decrypt this content - it's just a storage layer
-- Clients handle all encryption/decryption using Signal Protocol

CREATE TABLE IF NOT EXISTS encrypted_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    content_data BYTEA NOT NULL, -- Encrypted content (opaque to backend)
    content_hash VARCHAR(64), -- SHA-256 hash for integrity verification
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE, -- Optional expiration for content
    UNIQUE(message_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_encrypted_content_message_id ON encrypted_content(message_id);
CREATE INDEX IF NOT EXISTS idx_encrypted_content_expires_at ON encrypted_content(expires_at) WHERE expires_at IS NOT NULL;

-- Add comment explaining the security model
COMMENT ON TABLE encrypted_content IS 'Stores encrypted message content as opaque binary. Backend cannot read or decrypt. Signal Protocol handled client-side.';
COMMENT ON COLUMN encrypted_content.content_data IS 'Encrypted content - opaque binary data, backend cannot decrypt';
COMMENT ON COLUMN encrypted_content.content_hash IS 'SHA-256 hash for integrity verification only';

