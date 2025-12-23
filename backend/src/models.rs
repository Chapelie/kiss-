use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub password_hash: String,
    pub name: Option<String>,
    pub avatar_url: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub name: Option<String>,
    pub avatar_url: Option<String>,
    pub created_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        UserResponse {
            id: user.id,
            email: user.email,
            username: user.username,
            name: user.name,
            avatar_url: user.avatar_url,
            created_at: user.created_at,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 1, message = "Password is required"))]
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(email)]
    pub email: String,
    #[validate(length(min = 3, max = 50, message = "Username must be between 3 and 50 characters"))]
    pub username: String,
    #[validate(length(min = 8, message = "Password must be at least 8 characters"))]
    pub password: String,
    #[validate(length(max = 255, message = "Name must be less than 255 characters"))]
    pub name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthResponse {
    pub token: String,
    pub user: UserResponse,
}

/// Message metadata structure
/// 
/// SECURITY NOTE: This struct contains ONLY metadata, NEVER encrypted content.
/// The backend is a gateway only - Signal Protocol encryption is handled client-side.
/// Content is encrypted on the client and transmitted via a separate secure channel.
/// The backend cannot read or decrypt message content.
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Message {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: Uuid,
    pub recipient_id: Uuid,
    pub message_type: String, // 'text', 'image', 'file', etc.
    pub timestamp: DateTime<Utc>,
    pub session_id: Option<String>, // Signal session ID (reference only, no keys)
    pub is_read: bool,
    pub read_at: Option<DateTime<Utc>>,
    // NOTE: NO content field - backend is blind to message content
    // NOTE: NO encryption keys - all keys managed client-side
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessageRequest {
    pub recipient_id: Uuid,
    pub message_type: String,
    pub session_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessageResponse {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: Uuid,
    pub recipient_id: Uuid,
    pub message_type: String,
    pub timestamp: DateTime<Utc>,
    pub session_id: Option<String>,
    pub is_read: bool,
}

/// Encrypted content storage (opaque to backend)
/// 
/// SECURITY: This structure stores encrypted content as opaque binary data.
/// The backend cannot read or decrypt this content - it's just a storage layer.
/// All encryption/decryption is handled client-side using Signal Protocol.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EncryptedContentRequest {
    pub message_id: Uuid,
    pub content_data: String, // Base64 encoded encrypted content
    pub content_hash: Option<String>, // SHA-256 hash for integrity
    pub expires_at: Option<DateTime<Utc>>, // Optional expiration
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EncryptedContentResponse {
    pub message_id: Uuid,
    pub content_data: String, // Base64 encoded encrypted content
    pub content_hash: Option<String>,
    pub created_at: DateTime<Utc>,
}

impl From<Message> for MessageResponse {
    fn from(message: Message) -> Self {
        MessageResponse {
            id: message.id,
            conversation_id: message.conversation_id,
            sender_id: message.sender_id,
            recipient_id: message.recipient_id,
            message_type: message.message_type,
            timestamp: message.timestamp,
            session_id: message.session_id,
            is_read: message.is_read,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Conversation {
    pub id: Uuid,
    pub user1_id: Uuid,
    pub user2_id: Uuid,
    pub last_message_id: Option<Uuid>,
    pub last_message_time: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConversationResponse {
    pub id: Uuid,
    pub participant_id: Uuid,
    pub participant_name: Option<String>,
    pub participant_avatar: Option<String>,
    pub last_message: Option<String>,
    pub last_message_time: Option<DateTime<Utc>>,
    pub unread_count: i64,
    pub participant_status: String, // 'online', 'offline', 'away'
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Call {
    pub id: Uuid,
    pub call_id: String,
    pub caller_id: Uuid,
    pub recipient_id: Uuid,
    pub call_type: String, // 'audio' or 'video'
    pub status: String, // 'pending', 'accepted', 'rejected', 'busy', 'ended', 'missed'
    pub started_at: Option<DateTime<Utc>>,
    pub ended_at: Option<DateTime<Utc>>,
    pub duration_seconds: Option<i32>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallRequest {
    pub call_id: String,
    pub caller_id: Uuid,
    pub recipient_id: Uuid,
    pub call_type: String, // 'audio' or 'video'
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallRequestPayload {
    pub recipient_id: Uuid,
    pub call_type: String, // 'audio' or 'video'
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallResponse {
    pub call_id: String,
    pub response: String, // 'accept', 'reject', 'busy'
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallResponsePayload {
    pub call_id: String,
    pub response: String, // 'accept', 'reject', 'busy'
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallHistoryResponse {
    pub id: Uuid,
    pub call_id: String,
    pub caller_id: Uuid,
    pub recipient_id: Uuid,
    pub call_type: String,
    pub status: String,
    pub started_at: Option<DateTime<Utc>>,
    pub ended_at: Option<DateTime<Utc>>,
    pub duration_seconds: Option<i32>,
    pub created_at: DateTime<Utc>,
    pub caller_name: Option<String>,
    pub recipient_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserPresence {
    pub user_id: Uuid,
    pub status: String, // 'online', 'offline', 'away', 'busy'
    pub last_seen: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PresenceUpdate {
    pub user_id: Uuid,
    pub status: String, // 'online', 'offline', 'away'
    pub last_seen: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdatePresenceRequest {
    pub status: String, // 'online', 'offline', 'away'
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TypingIndicator {
    pub user_id: Uuid,
    pub conversation_id: Uuid,
    pub is_typing: bool,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReadReceipt {
    pub message_id: Uuid,
    pub reader_id: Uuid,
    pub read_at: DateTime<Utc>,
}

// WebSocket message types
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum WebSocketMessage {
    #[serde(rename = "message")]
    Message {
        payload: MessageRequest,
    },
    #[serde(rename = "message_response")]
    MessageResponse {
        payload: MessageResponse,
    },
    #[serde(rename = "call_request")]
    CallRequest {
        payload: CallRequestPayload,
    },
    #[serde(rename = "call_response")]
    CallResponse {
        payload: CallResponsePayload,
    },
    #[serde(rename = "call_request_full")]
    CallRequestFull {
        payload: CallRequest,
    },
    #[serde(rename = "call_response_full")]
    CallResponseFull {
        payload: CallResponse,
    },
    #[serde(rename = "presence_update")]
    PresenceUpdate {
        payload: PresenceUpdate,
    },
    #[serde(rename = "typing_indicator")]
    TypingIndicator {
        payload: TypingIndicator,
    },
    #[serde(rename = "read_receipt")]
    ReadReceipt {
        payload: ReadReceipt,
    },
    #[serde(rename = "heartbeat")]
    Heartbeat {
        payload: HeartbeatPayload,
    },
    #[serde(rename = "heartbeat_response")]
    HeartbeatResponse {
        payload: HeartbeatPayload,
    },
    #[serde(rename = "error")]
    Error {
        payload: ErrorPayload,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeartbeatPayload {
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorPayload {
    pub message: String,
    pub code: Option<String>,
}

// Stories models
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Story {
    pub id: Uuid,
    pub user_id: Uuid,
    pub content_text: Option<String>,
    pub media_url: Option<String>,
    pub media_type: String,
    pub created_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub views_count: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoryResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub user_name: Option<String>,
    pub user_avatar: Option<String>,
    pub content_text: Option<String>,
    pub media_url: Option<String>,
    pub media_type: String,
    pub created_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub views_count: i32,
    pub is_viewed: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct CreateStoryRequest {
    #[validate(length(max = 500, message = "Content text must be less than 500 characters"))]
    pub content_text: Option<String>,
    pub media_url: Option<String>,
    #[validate(length(min = 1, message = "Media type is required"))]
    pub media_type: String, // 'image' or 'video'
}

// Channels models
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Channel {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub creator_id: Uuid,
    pub avatar_url: Option<String>,
    pub is_private: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelResponse {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub creator_id: Uuid,
    pub creator_name: Option<String>,
    pub avatar_url: Option<String>,
    pub is_private: bool,
    pub member_count: i64,
    pub last_message_time: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct CreateChannelRequest {
    #[validate(length(min = 1, max = 255, message = "Channel name must be between 1 and 255 characters"))]
    pub name: String,
    #[validate(length(max = 1000, message = "Description must be less than 1000 characters"))]
    pub description: Option<String>,
    pub avatar_url: Option<String>,
    pub is_private: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ChannelMessage {
    pub id: Uuid,
    pub channel_id: Uuid,
    pub sender_id: Uuid,
    pub message_type: String,
    pub timestamp: DateTime<Utc>,
    pub session_id: Option<String>,
    pub is_read: bool,
    pub read_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelMessageResponse {
    pub id: Uuid,
    pub channel_id: Uuid,
    pub sender_id: Uuid,
    pub sender_name: Option<String>,
    pub sender_avatar: Option<String>,
    pub message_type: String,
    pub timestamp: DateTime<Utc>,
    pub session_id: Option<String>,
    pub is_read: bool,
}

