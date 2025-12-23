use crate::models::*;
use anyhow::Context;
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::{DateTime, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String, // user id
    exp: usize,
    iat: usize,
}

pub struct AuthService;

impl AuthService {
    pub fn hash_password(password: &str) -> anyhow::Result<String> {
        hash(password, DEFAULT_COST).context("Failed to hash password")
    }
    
    pub fn verify_password(password: &str, hash: &str) -> anyhow::Result<bool> {
        verify(password, hash).context("Failed to verify password")
    }
    
    pub fn generate_token(user_id: Uuid, secret: &str, expiration: i64) -> anyhow::Result<String> {
        let now = Utc::now().timestamp() as usize;
        let exp = now + expiration as usize;
        
        let claims = Claims {
            sub: user_id.to_string(),
            exp,
            iat: now,
        };
        
        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(secret.as_ref()),
        )
        .context("Failed to generate token")
    }
    
    pub fn verify_token(token: &str, secret: &str) -> anyhow::Result<Uuid> {
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(secret.as_ref()),
            &Validation::default(),
        )
        .context("Invalid token")?;
        
        Uuid::parse_str(&token_data.claims.sub).context("Invalid user ID in token")
    }
}

pub struct UserService;

impl UserService {
    pub async fn create_user(
        pool: &PgPool,
        email: &str,
        username: &str,
        password: &str,
        name: Option<&str>,
    ) -> anyhow::Result<User> {
        let password_hash = AuthService::hash_password(password)?;
        let user_id = Uuid::new_v4();
        
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (id, email, username, password_hash, name, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $6)
            RETURNING *
            "#,
        )
        .bind(user_id)
        .bind(email)
        .bind(username)
        .bind(password_hash)
        .bind(name)
        .bind(Utc::now())
        .fetch_one(pool)
        .await
        .context("Failed to create user")?;
        
        Ok(user)
    }
    
    pub async fn find_by_email(pool: &PgPool, email: &str) -> anyhow::Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE email = $1",
        )
        .bind(email)
        .fetch_optional(pool)
        .await
        .context("Failed to find user")?;
        
        Ok(user)
    }
    
    pub async fn find_by_id(pool: &PgPool, user_id: Uuid) -> anyhow::Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE id = $1",
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await
        .context("Failed to find user")?;
        
        Ok(user)
    }
    
    /// Find user by username
    pub async fn find_by_username(pool: &PgPool, username: &str) -> anyhow::Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE username = $1",
        )
        .bind(username)
        .fetch_optional(pool)
        .await
        .context("Failed to find user by username")?;
        
        Ok(user)
    }
    
    /// Search users by username, email or name
    /// This function searches users by:
    /// - Exact email match (highest priority)
    /// - Username match (starts with)
    /// - Email match (contains)
    /// - Name match (contains)
    pub async fn search_users(
        pool: &PgPool,
        query: &str,
        limit: i64,
        exclude_user_id: Option<Uuid>,
    ) -> anyhow::Result<Vec<User>> {
        // Trim and normalize the query
        let query = query.trim();
        if query.is_empty() {
            return Ok(vec![]);
        }
        
        // Create search patterns
        let exact_pattern = query.to_string();
        let starts_with_pattern = format!("{}%", query);
        let contains_pattern = format!("%{}%", query);
        
        let users = if let Some(exclude_id) = exclude_user_id {
            sqlx::query_as::<_, User>(
                r#"
                SELECT * FROM users
                WHERE (
                    email = $1 
                    OR email ILIKE $2 
                    OR COALESCE(username, '') = $1
                    OR COALESCE(username, '') ILIKE $2
                    OR COALESCE(username, '') ILIKE $3
                    OR COALESCE(name, '') ILIKE $3
                    OR email ILIKE $3
                )
                AND id != $4
                ORDER BY 
                    CASE 
                        WHEN email = $1 THEN 1
                        WHEN COALESCE(username, '') = $1 THEN 2
                        WHEN email ILIKE $2 THEN 3
                        WHEN COALESCE(username, '') ILIKE $2 THEN 4
                        WHEN email ILIKE $3 THEN 5
                        WHEN COALESCE(username, '') ILIKE $3 THEN 6
                        WHEN COALESCE(name, '') ILIKE $3 THEN 7
                        ELSE 8
                    END,
                    created_at DESC
                LIMIT $5
                "#,
            )
            .bind(&exact_pattern)
            .bind(&starts_with_pattern)
            .bind(&contains_pattern)
            .bind(exclude_id)
            .bind(limit)
            .fetch_all(pool)
            .await
            .context("Failed to search users")?
        } else {
            sqlx::query_as::<_, User>(
                r#"
                SELECT * FROM users
                WHERE (
                    email = $1 
                    OR email ILIKE $2 
                    OR COALESCE(username, '') = $1
                    OR COALESCE(username, '') ILIKE $2
                    OR COALESCE(username, '') ILIKE $3
                    OR COALESCE(name, '') ILIKE $3
                    OR email ILIKE $3
                )
                ORDER BY 
                    CASE 
                        WHEN email = $1 THEN 1
                        WHEN COALESCE(username, '') = $1 THEN 2
                        WHEN email ILIKE $2 THEN 3
                        WHEN COALESCE(username, '') ILIKE $2 THEN 4
                        WHEN email ILIKE $3 THEN 5
                        WHEN COALESCE(username, '') ILIKE $3 THEN 6
                        WHEN COALESCE(name, '') ILIKE $3 THEN 7
                        ELSE 8
                    END,
                    created_at DESC
                LIMIT $4
                "#,
            )
            .bind(&exact_pattern)
            .bind(&starts_with_pattern)
            .bind(&contains_pattern)
            .bind(limit)
            .fetch_all(pool)
            .await
            .context("Failed to search users")?
        };
        
        Ok(users)
    }
    
    /// Get all users (for contacts list)
    pub async fn get_all_users(
        pool: &PgPool,
        limit: i64,
        offset: i64,
        exclude_user_id: Option<Uuid>,
    ) -> anyhow::Result<Vec<User>> {
        let users = if let Some(exclude_id) = exclude_user_id {
            sqlx::query_as::<_, User>(
                "SELECT * FROM users WHERE id != $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3",
            )
            .bind(exclude_id)
            .bind(limit)
            .bind(offset)
            .fetch_all(pool)
            .await
            .context("Failed to get users")?
        } else {
            sqlx::query_as::<_, User>(
                "SELECT * FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2",
            )
            .bind(limit)
            .bind(offset)
            .fetch_all(pool)
            .await
            .context("Failed to get users")?
        };
        
        Ok(users)
    }
}

/// Service for message metadata management
/// 
/// SECURITY: This service handles ONLY metadata routing.
/// It does NOT store encrypted content or encryption keys.
/// Signal Protocol encryption/decryption is handled entirely client-side.
pub struct MessageService;

impl MessageService {
    /// Create message metadata entry
    /// 
    /// This function stores ONLY metadata (IDs, timestamps, session reference).
    /// The encrypted content is handled separately by the client.
    pub async fn create_message(
        pool: &PgPool,
        sender_id: Uuid,
        recipient_id: Uuid,
        message_type: &str,
        session_id: Option<&str>,
    ) -> anyhow::Result<Message> {
        // Get or create conversation
        let conversation = ConversationService::get_or_create_conversation(
            pool,
            sender_id,
            recipient_id,
        )
        .await?;
        
        let message_id = Uuid::new_v4();
        let timestamp = Utc::now();
        
        let message = sqlx::query_as::<_, Message>(
            r#"
            INSERT INTO messages (id, conversation_id, sender_id, recipient_id, message_type, timestamp, session_id, is_read)
            VALUES ($1, $2, $3, $4, $5, $6, $7, false)
            RETURNING *
            "#,
        )
        .bind(message_id)
        .bind(conversation.id)
        .bind(sender_id)
        .bind(recipient_id)
        .bind(message_type)
        .bind(timestamp)
        .bind(session_id)
        .fetch_one(pool)
        .await
        .context("Failed to create message")?;
        
        // Update conversation
        sqlx::query(
            r#"
            UPDATE conversations 
            SET last_message_id = $1, last_message_time = $2, updated_at = $2
            WHERE id = $3
            "#,
        )
        .bind(message_id)
        .bind(timestamp)
        .bind(conversation.id)
        .execute(pool)
        .await
        .context("Failed to update conversation")?;
        
        Ok(message)
    }
    
    pub async fn mark_as_read(
        pool: &PgPool,
        message_id: Uuid,
        reader_id: Uuid,
    ) -> anyhow::Result<()> {
        sqlx::query(
            r#"
            UPDATE messages 
            SET is_read = true, read_at = $1
            WHERE id = $2 AND recipient_id = $3
            "#,
        )
        .bind(Utc::now())
        .bind(message_id)
        .bind(reader_id)
        .execute(pool)
        .await
        .context("Failed to mark message as read")?;
        
        Ok(())
    }
    
    pub async fn get_conversation_messages(
        pool: &PgPool,
        conversation_id: Uuid,
        user_id: Uuid,
        limit: i64,
    ) -> anyhow::Result<Vec<Message>> {
        let messages = sqlx::query_as::<_, Message>(
            r#"
            SELECT * FROM messages
            WHERE conversation_id = $1 AND (sender_id = $2 OR recipient_id = $2)
            ORDER BY timestamp DESC
            LIMIT $3
            "#,
        )
        .bind(conversation_id)
        .bind(user_id)
        .bind(limit)
        .fetch_all(pool)
        .await
        .context("Failed to get messages")?;
        
        Ok(messages)
    }
}

/// Service for encrypted content storage
/// 
/// SECURITY: This service stores encrypted content as opaque binary data.
/// The backend cannot read or decrypt the content - it's just a storage layer.
/// All encryption/decryption is handled client-side using Signal Protocol.
pub struct EncryptedContentService;

impl EncryptedContentService {
    /// Store encrypted content for a message
    /// 
    /// The content is stored as opaque binary data.
    /// The backend cannot read or decrypt it.
    pub async fn store_content(
        pool: &PgPool,
        message_id: Uuid,
        content_data: &[u8],
        content_hash: Option<&str>,
        expires_at: Option<DateTime<Utc>>,
    ) -> anyhow::Result<()> {
        sqlx::query(
            r#"
            INSERT INTO encrypted_content (message_id, content_data, content_hash, expires_at)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (message_id) 
            DO UPDATE SET 
                content_data = $2,
                content_hash = $3,
                expires_at = $4
            "#,
        )
        .bind(message_id)
        .bind(content_data)
        .bind(content_hash)
        .bind(expires_at)
        .execute(pool)
        .await
        .context("Failed to store encrypted content")?;
        
        Ok(())
    }
    
    /// Retrieve encrypted content for a message
    /// 
    /// Returns the encrypted content as opaque binary data.
    /// The backend cannot decrypt it.
    pub async fn get_content(
        pool: &PgPool,
        message_id: Uuid,
    ) -> anyhow::Result<Option<Vec<u8>>> {
        let result = sqlx::query_scalar::<_, Option<Vec<u8>>>(
            r#"
            SELECT content_data FROM encrypted_content
            WHERE message_id = $1
            AND (expires_at IS NULL OR expires_at > NOW())
            "#,
        )
        .bind(message_id)
        .fetch_optional(pool)
        .await
        .context("Failed to get encrypted content")?;
        
        Ok(result.flatten())
    }
    
    /// Delete expired content
    pub async fn cleanup_expired(pool: &PgPool) -> anyhow::Result<u64> {
        let deleted = sqlx::query(
            "DELETE FROM encrypted_content WHERE expires_at < NOW()",
        )
        .execute(pool)
        .await
        .context("Failed to cleanup expired content")?;
        
        Ok(deleted.rows_affected())
    }
}

pub struct StoryService;

impl StoryService {
    pub async fn create_story(
        pool: &PgPool,
        user_id: Uuid,
        content_text: Option<&str>,
        media_url: Option<&str>,
        media_type: &str,
    ) -> anyhow::Result<Story> {
        let story_id = Uuid::new_v4();
        let now = Utc::now();
        let expires_at = now + chrono::Duration::hours(24);
        
        let story = sqlx::query_as::<_, Story>(
            r#"
            INSERT INTO stories (id, user_id, content_text, media_url, media_type, created_at, expires_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            "#,
        )
        .bind(story_id)
        .bind(user_id)
        .bind(content_text)
        .bind(media_url)
        .bind(media_type)
        .bind(now)
        .bind(expires_at)
        .fetch_one(pool)
        .await
        .context("Failed to create story")?;
        
        Ok(story)
    }
    
    pub async fn get_user_stories(
        pool: &PgPool,
        user_id: Uuid,
    ) -> anyhow::Result<Vec<Story>> {
        let stories = sqlx::query_as::<_, Story>(
            r#"
            SELECT * FROM stories
            WHERE user_id = $1 AND expires_at > NOW()
            ORDER BY created_at DESC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .context("Failed to get user stories")?;
        
        Ok(stories)
    }
    
    pub async fn get_all_stories(
        pool: &PgPool,
        viewer_id: Uuid,
        limit: i64,
    ) -> anyhow::Result<Vec<StoryResponse>> {
        let stories = sqlx::query_as::<_, Story>(
            r#"
            SELECT s.* FROM stories s
            INNER JOIN users u ON s.user_id = u.id
            WHERE s.expires_at > NOW()
            ORDER BY s.created_at DESC
            LIMIT $1
            "#,
        )
        .bind(limit)
        .fetch_all(pool)
        .await
        .context("Failed to get stories")?;
        
        let mut responses = Vec::new();
        for story in stories {
            let user = UserService::find_by_id(pool, story.user_id)
                .await
                .ok()
                .flatten();
            
            let is_viewed = sqlx::query_scalar::<_, bool>(
                "SELECT EXISTS(SELECT 1 FROM story_views WHERE story_id = $1 AND viewer_id = $2)",
            )
            .bind(story.id)
            .bind(viewer_id)
            .fetch_one(pool)
            .await
            .unwrap_or(false);
            
            responses.push(StoryResponse {
                id: story.id,
                user_id: story.user_id,
                user_name: user.as_ref().and_then(|u| u.name.clone()),
                user_avatar: user.as_ref().and_then(|u| u.avatar_url.clone()),
                content_text: story.content_text,
                media_url: story.media_url,
                media_type: story.media_type,
                created_at: story.created_at,
                expires_at: story.expires_at,
                views_count: story.views_count,
                is_viewed,
            });
        }
        
        Ok(responses)
    }
    
    pub async fn view_story(
        pool: &PgPool,
        story_id: Uuid,
        viewer_id: Uuid,
    ) -> anyhow::Result<()> {
        // Check if already viewed
        let exists = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM story_views WHERE story_id = $1 AND viewer_id = $2)",
        )
        .bind(story_id)
        .bind(viewer_id)
        .fetch_one(pool)
        .await
        .context("Failed to check story view")?;
        
        if !exists {
            // Add view
            sqlx::query(
                "INSERT INTO story_views (story_id, viewer_id) VALUES ($1, $2)",
            )
            .bind(story_id)
            .bind(viewer_id)
            .execute(pool)
            .await
            .context("Failed to add story view")?;
            
            // Update views count
            sqlx::query(
                "UPDATE stories SET views_count = views_count + 1 WHERE id = $1",
            )
            .bind(story_id)
            .execute(pool)
            .await
            .context("Failed to update story views count")?;
        }
        
        Ok(())
    }
    
    pub async fn delete_expired_stories(pool: &PgPool) -> anyhow::Result<u64> {
        let deleted = sqlx::query(
            "DELETE FROM stories WHERE expires_at < NOW()",
        )
        .execute(pool)
        .await
        .context("Failed to delete expired stories")?;
        
        Ok(deleted.rows_affected())
    }
}

pub struct ChannelService;

impl ChannelService {
    pub async fn create_channel(
        pool: &PgPool,
        creator_id: Uuid,
        name: &str,
        description: Option<&str>,
        avatar_url: Option<&str>,
        is_private: bool,
    ) -> anyhow::Result<Channel> {
        let channel_id = Uuid::new_v4();
        let now = Utc::now();
        
        let channel = sqlx::query_as::<_, Channel>(
            r#"
            INSERT INTO channels (id, name, description, creator_id, avatar_url, is_private, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $7)
            RETURNING *
            "#,
        )
        .bind(channel_id)
        .bind(name)
        .bind(description)
        .bind(creator_id)
        .bind(avatar_url)
        .bind(is_private)
        .bind(now)
        .fetch_one(pool)
        .await
        .context("Failed to create channel")?;
        
        // Add creator as admin member
        sqlx::query(
            "INSERT INTO channel_members (channel_id, user_id, role) VALUES ($1, $2, 'admin')",
        )
        .bind(channel_id)
        .bind(creator_id)
        .execute(pool)
        .await
        .context("Failed to add creator to channel")?;
        
        Ok(channel)
    }
    
    pub async fn get_user_channels(
        pool: &PgPool,
        user_id: Uuid,
    ) -> anyhow::Result<Vec<ChannelResponse>> {
        let channels = sqlx::query_as::<_, Channel>(
            r#"
            SELECT c.* FROM channels c
            INNER JOIN channel_members cm ON c.id = cm.channel_id
            WHERE cm.user_id = $1
            ORDER BY c.updated_at DESC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .context("Failed to get user channels")?;
        
        let mut responses = Vec::new();
        for channel in channels {
            let creator = UserService::find_by_id(pool, channel.creator_id)
                .await
                .ok()
                .flatten();
            
            let member_count: i64 = sqlx::query_scalar(
                "SELECT COUNT(*)::bigint FROM channel_members WHERE channel_id = $1",
            )
            .bind(channel.id)
            .fetch_one(pool)
            .await
            .unwrap_or(0);
            
            let last_message_time: Option<DateTime<Utc>> = sqlx::query_scalar(
                "SELECT MAX(timestamp) FROM channel_messages WHERE channel_id = $1",
            )
            .bind(channel.id)
            .fetch_optional(pool)
            .await
            .ok()
            .flatten();
            
            responses.push(ChannelResponse {
                id: channel.id,
                name: channel.name,
                description: channel.description,
                creator_id: channel.creator_id,
                creator_name: creator.as_ref().and_then(|u| u.name.clone()),
                avatar_url: channel.avatar_url,
                is_private: channel.is_private,
                member_count,
                last_message_time,
                created_at: channel.created_at,
            });
        }
        
        Ok(responses)
    }
    
    pub async fn add_member(
        pool: &PgPool,
        channel_id: Uuid,
        user_id: Uuid,
    ) -> anyhow::Result<()> {
        sqlx::query(
            "INSERT INTO channel_members (channel_id, user_id, role) VALUES ($1, $2, 'member') ON CONFLICT DO NOTHING",
        )
        .bind(channel_id)
        .bind(user_id)
        .execute(pool)
        .await
        .context("Failed to add member to channel")?;
        
        Ok(())
    }
    
    pub async fn remove_member(
        pool: &PgPool,
        channel_id: Uuid,
        user_id: Uuid,
    ) -> anyhow::Result<()> {
        sqlx::query(
            "DELETE FROM channel_members WHERE channel_id = $1 AND user_id = $2",
        )
        .bind(channel_id)
        .bind(user_id)
        .execute(pool)
        .await
        .context("Failed to remove member from channel")?;
        
        Ok(())
    }
    
    pub async fn create_message(
        pool: &PgPool,
        channel_id: Uuid,
        sender_id: Uuid,
        message_type: &str,
        session_id: Option<&str>,
    ) -> anyhow::Result<ChannelMessage> {
        let message_id = Uuid::new_v4();
        let timestamp = Utc::now();
        
        let message = sqlx::query_as::<_, ChannelMessage>(
            r#"
            INSERT INTO channel_messages (id, channel_id, sender_id, message_type, timestamp, session_id, is_read)
            VALUES ($1, $2, $3, $4, $5, $6, false)
            RETURNING *
            "#,
        )
        .bind(message_id)
        .bind(channel_id)
        .bind(sender_id)
        .bind(message_type)
        .bind(timestamp)
        .bind(session_id)
        .fetch_one(pool)
        .await
        .context("Failed to create channel message")?;
        
        // Update channel updated_at
        sqlx::query(
            "UPDATE channels SET updated_at = $1 WHERE id = $2",
        )
        .bind(timestamp)
        .bind(channel_id)
        .execute(pool)
        .await
        .context("Failed to update channel")?;
        
        Ok(message)
    }
    
    pub async fn get_channel_messages(
        pool: &PgPool,
        channel_id: Uuid,
        limit: i64,
    ) -> anyhow::Result<Vec<ChannelMessageResponse>> {
        let messages = sqlx::query_as::<_, ChannelMessage>(
            r#"
            SELECT * FROM channel_messages
            WHERE channel_id = $1
            ORDER BY timestamp DESC
            LIMIT $2
            "#,
        )
        .bind(channel_id)
        .bind(limit)
        .fetch_all(pool)
        .await
        .context("Failed to get channel messages")?;
        
        let mut responses = Vec::new();
        for message in messages {
            let sender = UserService::find_by_id(pool, message.sender_id)
                .await
                .ok()
                .flatten();
            
            responses.push(ChannelMessageResponse {
                id: message.id,
                channel_id: message.channel_id,
                sender_id: message.sender_id,
                sender_name: sender.as_ref().and_then(|u| u.name.clone()),
                sender_avatar: sender.as_ref().and_then(|u| u.avatar_url.clone()),
                message_type: message.message_type,
                timestamp: message.timestamp,
                session_id: message.session_id,
                is_read: message.is_read,
            });
        }
        
        Ok(responses)
    }
}

pub struct ConversationService;

impl ConversationService {
    pub async fn get_or_create_conversation(
        pool: &PgPool,
        user1_id: Uuid,
        user2_id: Uuid,
    ) -> anyhow::Result<Conversation> {
        // Try to find existing conversation
        let conversation = sqlx::query_as::<_, Conversation>(
            r#"
            SELECT * FROM conversations
            WHERE (user1_id = $1 AND user2_id = $2) OR (user1_id = $2 AND user2_id = $1)
            LIMIT 1
            "#,
        )
        .bind(user1_id)
        .bind(user2_id)
        .fetch_optional(pool)
        .await
        .context("Failed to find conversation")?;
        
        if let Some(conv) = conversation {
            return Ok(conv);
        }
        
        // Create new conversation
        let conversation_id = Uuid::new_v4();
        let now = Utc::now();
        
        let conversation = sqlx::query_as::<_, Conversation>(
            r#"
            INSERT INTO conversations (id, user1_id, user2_id, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $4)
            RETURNING *
            "#,
        )
        .bind(conversation_id)
        .bind(user1_id)
        .bind(user2_id)
        .bind(now)
        .fetch_one(pool)
        .await
        .context("Failed to create conversation")?;
        
        Ok(conversation)
    }
    
    pub async fn get_user_conversations(
        pool: &PgPool,
        user_id: Uuid,
    ) -> anyhow::Result<Vec<ConversationResponse>> {
        // Get conversations - return empty list if none found (not an error)
        let conversations = match sqlx::query_as::<_, Conversation>(
            r#"
            SELECT * FROM conversations
            WHERE user1_id = $1 OR user2_id = $1
            ORDER BY last_message_time DESC NULLS LAST, updated_at DESC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        {
            Ok(convs) => convs,
            Err(e) => {
                tracing::warn!("Failed to get conversations for user {}: {:?}", user_id, e);
                // Return empty list instead of error for new users
                return Ok(Vec::new());
            }
        };
        
        // Build response with participant info
        let mut responses = Vec::new();
        for conv in conversations {
            let participant_id = if conv.user1_id == user_id {
                conv.user2_id
            } else {
                conv.user1_id
            };
            
            // Get participant info - skip if participant not found (deleted user)
            let participant = match UserService::find_by_id(pool, participant_id).await {
                Ok(Some(p)) => p,
                Ok(None) => {
                    tracing::warn!("Participant {} not found for conversation {}", participant_id, conv.id);
                    continue; // Skip this conversation
                }
                Err(e) => {
                    tracing::warn!("Failed to get participant {}: {:?}", participant_id, e);
                    continue; // Skip this conversation
                }
            };
            
            // Get unread count - default to 0 on error
            let unread_count: i64 = sqlx::query_scalar(
                r#"
                SELECT COUNT(*)::bigint
                FROM messages
                WHERE conversation_id = $1 AND recipient_id = $2 AND is_read = false
                "#,
            )
            .bind(conv.id)
            .bind(user_id)
            .fetch_one(pool)
            .await
            .unwrap_or(0);
            
            // Get participant presence - default to offline on error
            let participant_status = crate::services::PresenceService::get_presence(pool, participant_id)
                .await
                .ok()
                .flatten()
                .map(|p| p.status)
                .unwrap_or_else(|| "offline".to_string());
            
            responses.push(ConversationResponse {
                id: conv.id,
                participant_id,
                participant_name: participant.name,
                participant_avatar: participant.avatar_url,
                last_message: None, // Could be populated from last_message_id
                last_message_time: conv.last_message_time,
                unread_count,
                participant_status,
            });
        }
        
        Ok(responses)
    }
}

pub struct CallService;

impl CallService {
    pub async fn create_call(
        pool: &PgPool,
        caller_id: Uuid,
        recipient_id: Uuid,
        call_type: &str,
    ) -> anyhow::Result<Call> {
        let call_id = Uuid::new_v4().to_string();
        let call_uuid = Uuid::new_v4();
        let now = Utc::now();
        
        let call = sqlx::query_as::<_, Call>(
            r#"
            INSERT INTO calls (id, call_id, caller_id, recipient_id, call_type, status, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, 'pending', $6, $6)
            RETURNING *
            "#,
        )
        .bind(call_uuid)
        .bind(&call_id)
        .bind(caller_id)
        .bind(recipient_id)
        .bind(call_type)
        .bind(now)
        .fetch_one(pool)
        .await
        .context("Failed to create call")?;
        
        Ok(call)
    }
    
    pub async fn update_call_status(
        pool: &PgPool,
        call_id: &str,
        status: &str,
    ) -> anyhow::Result<Call> {
        let now = Utc::now();
        
        let call = sqlx::query_as::<_, Call>(
            r#"
            UPDATE calls
            SET status = $1, updated_at = $2
            WHERE call_id = $3
            RETURNING *
            "#,
        )
        .bind(status)
        .bind(now)
        .bind(call_id)
        .fetch_one(pool)
        .await
        .context("Failed to update call status")?;
        
        Ok(call)
    }
    
    pub async fn accept_call(
        pool: &PgPool,
        call_id: &str,
    ) -> anyhow::Result<Call> {
        let now = Utc::now();
        
        let call = sqlx::query_as::<_, Call>(
            r#"
            UPDATE calls
            SET status = 'accepted', started_at = $1, updated_at = $1
            WHERE call_id = $2
            RETURNING *
            "#,
        )
        .bind(now)
        .bind(call_id)
        .fetch_one(pool)
        .await
        .context("Failed to accept call")?;
        
        Ok(call)
    }
    
    pub async fn end_call(
        pool: &PgPool,
        call_id: &str,
    ) -> anyhow::Result<Call> {
        let now = Utc::now();
        
        // Calculate duration if call was started
        let call = sqlx::query_as::<_, Call>(
            r#"
            UPDATE calls
            SET status = 'ended', 
                ended_at = $1, 
                duration_seconds = CASE 
                    WHEN started_at IS NOT NULL THEN EXTRACT(EPOCH FROM ($1 - started_at))::INTEGER
                    ELSE NULL
                END,
                updated_at = $1
            WHERE call_id = $2
            RETURNING *
            "#,
        )
        .bind(now)
        .bind(call_id)
        .fetch_one(pool)
        .await
        .context("Failed to end call")?;
        
        Ok(call)
    }
    
    pub async fn get_call_by_id(
        pool: &PgPool,
        call_id: &str,
    ) -> anyhow::Result<Option<Call>> {
        let call = sqlx::query_as::<_, Call>(
            "SELECT * FROM calls WHERE call_id = $1",
        )
        .bind(call_id)
        .fetch_optional(pool)
        .await
        .context("Failed to get call")?;
        
        Ok(call)
    }
    
    pub async fn get_user_call_history(
        pool: &PgPool,
        user_id: Uuid,
        limit: i64,
    ) -> anyhow::Result<Vec<CallHistoryResponse>> {
        let rows = sqlx::query(
            r#"
            SELECT 
                c.id,
                c.call_id,
                c.caller_id,
                c.recipient_id,
                c.call_type,
                c.status,
                c.started_at,
                c.ended_at,
                c.duration_seconds,
                c.created_at,
                caller.name as caller_name,
                recipient.name as recipient_name
            FROM calls c
            LEFT JOIN users caller ON caller.id = c.caller_id
            LEFT JOIN users recipient ON recipient.id = c.recipient_id
            WHERE c.caller_id = $1 OR c.recipient_id = $1
            ORDER BY c.created_at DESC
            LIMIT $2
            "#,
        )
        .bind(user_id)
        .bind(limit)
        .fetch_all(pool)
        .await
        .context("Failed to get call history")?;
        
        use sqlx::Row;
        let mut calls = Vec::new();
        for row in rows {
            calls.push(CallHistoryResponse {
                id: row.get("id"),
                call_id: row.get("call_id"),
                caller_id: row.get("caller_id"),
                recipient_id: row.get("recipient_id"),
                call_type: row.get("call_type"),
                status: row.get("status"),
                started_at: row.get("started_at"),
                ended_at: row.get("ended_at"),
                duration_seconds: row.get("duration_seconds"),
                created_at: row.get("created_at"),
                caller_name: row.get("caller_name"),
                recipient_name: row.get("recipient_name"),
            });
        }
        
        Ok(calls)
    }
    
    pub async fn get_active_call(
        pool: &PgPool,
        user_id: Uuid,
    ) -> anyhow::Result<Option<Call>> {
        let call = sqlx::query_as::<_, Call>(
            r#"
            SELECT * FROM calls
            WHERE (caller_id = $1 OR recipient_id = $1)
            AND status IN ('pending', 'accepted')
            ORDER BY created_at DESC
            LIMIT 1
            "#,
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await
        .context("Failed to get active call")?;
        
        Ok(call)
    }
}

pub struct PresenceService;

impl PresenceService {
    pub async fn update_presence(
        pool: &PgPool,
        user_id: Uuid,
        status: &str,
    ) -> anyhow::Result<UserPresence> {
        let now = Utc::now();
        
        let presence = sqlx::query_as::<_, UserPresence>(
            r#"
            INSERT INTO user_presence (user_id, status, last_seen, updated_at)
            VALUES ($1, $2, $3, $3)
            ON CONFLICT (user_id) 
            DO UPDATE SET 
                status = $2,
                last_seen = CASE 
                    WHEN $2 = 'offline' THEN user_presence.last_seen
                    ELSE $3
                END,
                updated_at = $3
            RETURNING *
            "#,
        )
        .bind(user_id)
        .bind(status)
        .bind(now)
        .fetch_one(pool)
        .await
        .context("Failed to update presence")?;
        
        Ok(presence)
    }
    
    pub async fn get_presence(
        pool: &PgPool,
        user_id: Uuid,
    ) -> anyhow::Result<Option<UserPresence>> {
        let presence = sqlx::query_as::<_, UserPresence>(
            "SELECT * FROM user_presence WHERE user_id = $1",
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await
        .context("Failed to get presence")?;
        
        Ok(presence)
    }
    
    pub async fn get_multiple_presences(
        pool: &PgPool,
        user_ids: &[Uuid],
    ) -> anyhow::Result<Vec<UserPresence>> {
        let presences = sqlx::query_as::<_, UserPresence>(
            "SELECT * FROM user_presence WHERE user_id = ANY($1)",
        )
        .bind(user_ids)
        .fetch_all(pool)
        .await
        .context("Failed to get presences")?;
        
        Ok(presences)
    }
    
    pub async fn mark_offline_after_timeout(
        pool: &PgPool,
        timeout_minutes: i64,
    ) -> anyhow::Result<()> {
        sqlx::query(
            r#"
            UPDATE user_presence
            SET status = 'offline', updated_at = NOW()
            WHERE status = 'online'
            AND last_seen < NOW() - INTERVAL '1 minute' * $1
            "#,
        )
        .bind(timeout_minutes)
        .execute(pool)
        .await
        .context("Failed to mark offline users")?;
        
        Ok(())
    }
}

