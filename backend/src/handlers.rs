use crate::models::*;
use crate::services::*;
use crate::AppState;
use axum::{
    extract::{Extension, Path, Query},
    http::StatusCode,
    response::Json,
};
use serde::Deserialize;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use validator::Validate;

pub async fn register(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Json(payload): Json<RegisterRequest>,
) -> Result<Json<AuthResponse>, StatusCode> {
    // Validate request
    if let Err(validation_errors) = payload.validate() {
        tracing::warn!("Validation error: {:?}", validation_errors);
        return Err(StatusCode::BAD_REQUEST);
    }
    
    // Check if email already exists
    if UserService::find_by_email(state.db.pool(), &payload.email)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .is_some()
    {
        return Err(StatusCode::CONFLICT);
    }
    
    // Check if username already exists
    if UserService::find_by_username(state.db.pool(), &payload.username)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .is_some()
    {
        return Err(StatusCode::CONFLICT);
    }
    
    // Create user
    let user = UserService::create_user(
        state.db.pool(),
        &payload.email,
        &payload.username,
        &payload.password,
        payload.name.as_deref(),
    )
    .await
    .map_err(|e| {
        tracing::error!("Failed to create user: {:?}", e);
        // Check if it's a unique constraint violation
        if e.to_string().contains("unique") || e.to_string().contains("duplicate") {
            StatusCode::CONFLICT
        } else {
            StatusCode::INTERNAL_SERVER_ERROR
        }
    })?;
    
    // Generate token
    let token = AuthService::generate_token(
        user.id,
        &state.config.jwt_secret,
        state.config.jwt_expiration,
    )
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(AuthResponse {
        token,
        user: user.into(),
    }))
}

pub async fn login(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, StatusCode> {
    // Validate request
    if let Err(validation_errors) = payload.validate() {
        tracing::warn!("Validation error: {:?}", validation_errors);
        return Err(StatusCode::BAD_REQUEST);
    }
    
    // Find user
    let user = UserService::find_by_email(state.db.pool(), &payload.email)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::UNAUTHORIZED)?;
    
    // Verify password
    if !AuthService::verify_password(&payload.password, &user.password_hash)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    {
        return Err(StatusCode::UNAUTHORIZED);
    }
    
    // Generate token
    let token = AuthService::generate_token(
        user.id,
        &state.config.jwt_secret,
        state.config.jwt_expiration,
    )
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(AuthResponse {
        token,
        user: user.into(),
    }))
}

pub async fn get_me(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
) -> Result<Json<UserResponse>, StatusCode> {
    let user = UserService::find_by_id(state.db.pool(), user_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    Ok(Json(user.into()))
}

pub async fn get_conversations(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
) -> Result<Json<Vec<ConversationResponse>>, StatusCode> {
    let conversations = ConversationService::get_user_conversations(state.db.pool(), user_id)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get conversations: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    
    Ok(Json(conversations))
}

#[derive(Deserialize)]
pub struct SearchUsersQuery {
    q: Option<String>,
    limit: Option<i64>,
}

pub async fn search_users(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Query(query): Query<SearchUsersQuery>,
) -> Result<Json<Vec<UserResponse>>, StatusCode> {
    let search_query = query.q.unwrap_or_else(|| "".to_string()).trim().to_string();
    let limit = query.limit.unwrap_or(50).min(100); // Max 100 results
    
    // Always search, even if query is empty (returns all users)
    let users = if search_query.is_empty() {
        // Return all users if no search query
        UserService::get_all_users(state.db.pool(), limit, 0, Some(user_id))
            .await
            .map_err(|e| {
                tracing::error!("Failed to get users: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?
    } else {
        // Search users by email, username, or name
        UserService::search_users(state.db.pool(), &search_query, limit, Some(user_id))
            .await
            .map_err(|e| {
                tracing::error!("Failed to search users: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?
    };
    
    Ok(Json(users.into_iter().map(Into::into).collect()))
}

#[derive(Deserialize)]
pub struct FindByEmailQuery {
    email: String,
}

pub async fn find_user_by_email(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Query(query): Query<FindByEmailQuery>,
) -> Result<Json<UserResponse>, StatusCode> {
    // Find user by email
    let user = UserService::find_by_email(state.db.pool(), &query.email)
        .await
        .map_err(|e| {
            tracing::error!("Failed to find user by email: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    // Don't return the current user
    if user.id == user_id {
        return Err(StatusCode::BAD_REQUEST);
    }
    
    Ok(Json(user.into()))
}

#[derive(Deserialize)]
pub struct CreateConversationRequest {
    participant_id: Uuid,
}

pub async fn create_conversation(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Json(payload): Json<CreateConversationRequest>,
) -> Result<Json<ConversationResponse>, StatusCode> {
    // Verify that the participant exists
    let participant = UserService::find_by_id(state.db.pool(), payload.participant_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    // Don't allow creating conversation with yourself
    if payload.participant_id == user_id {
        return Err(StatusCode::BAD_REQUEST);
    }
    
    // Get or create conversation
    let conversation = ConversationService::get_or_create_conversation(
        state.db.pool(),
        user_id,
        payload.participant_id,
    )
    .await
    .map_err(|e| {
        tracing::error!("Failed to create conversation: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    
    // Build response
    let unread_count: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(*)::bigint
        FROM messages
        WHERE conversation_id = $1 AND recipient_id = $2 AND is_read = false
        "#,
    )
    .bind(conversation.id)
    .bind(user_id)
    .fetch_one(state.db.pool())
    .await
    .unwrap_or(0);
    
    let participant_status = crate::services::PresenceService::get_presence(
        state.db.pool(),
        payload.participant_id,
    )
    .await
    .ok()
    .flatten()
    .map(|p| p.status)
    .unwrap_or_else(|| "offline".to_string());
    
    Ok(Json(ConversationResponse {
        id: conversation.id,
        participant_id: payload.participant_id,
        participant_name: participant.name,
        participant_avatar: participant.avatar_url,
        last_message: None,
        last_message_time: conversation.last_message_time,
        unread_count,
        participant_status,
    }))
}

// Stories handlers
pub async fn create_story(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Json(payload): Json<CreateStoryRequest>,
) -> Result<Json<StoryResponse>, StatusCode> {
    if let Err(_) = payload.validate() {
        return Err(StatusCode::BAD_REQUEST);
    }
    
    let story = StoryService::create_story(
        state.db.pool(),
        user_id,
        payload.content_text.as_deref(),
        payload.media_url.as_deref(),
        &payload.media_type,
    )
    .await
    .map_err(|e| {
        tracing::error!("Failed to create story: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    
    let user = UserService::find_by_id(state.db.pool(), user_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    Ok(Json(StoryResponse {
        id: story.id,
        user_id: story.user_id,
        user_name: user.name,
        user_avatar: user.avatar_url,
        content_text: story.content_text,
        media_url: story.media_url,
        media_type: story.media_type,
        created_at: story.created_at,
        expires_at: story.expires_at,
        views_count: story.views_count,
        is_viewed: false,
    }))
}

pub async fn get_stories(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Query(query): Query<MessageQuery>,
) -> Result<Json<Vec<StoryResponse>>, StatusCode> {
    let limit = query.limit.unwrap_or(50);
    
    let stories = StoryService::get_all_stories(state.db.pool(), user_id, limit)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get stories: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    
    Ok(Json(stories))
}

pub async fn view_story(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Path(story_id): Path<Uuid>,
) -> Result<StatusCode, StatusCode> {
    StoryService::view_story(state.db.pool(), story_id, user_id)
        .await
        .map_err(|e| {
            tracing::error!("Failed to view story: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    
    Ok(StatusCode::OK)
}

// Channels handlers
pub async fn create_channel(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Json(payload): Json<CreateChannelRequest>,
) -> Result<Json<ChannelResponse>, StatusCode> {
    if let Err(_) = payload.validate() {
        return Err(StatusCode::BAD_REQUEST);
    }
    
    let channel = ChannelService::create_channel(
        state.db.pool(),
        user_id,
        &payload.name,
        payload.description.as_deref(),
        payload.avatar_url.as_deref(),
        payload.is_private.unwrap_or(false),
    )
    .await
    .map_err(|e| {
        tracing::error!("Failed to create channel: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    
    let creator = UserService::find_by_id(state.db.pool(), user_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    
    let member_count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*)::bigint FROM channel_members WHERE channel_id = $1",
    )
    .bind(channel.id)
    .fetch_one(state.db.pool())
    .await
    .unwrap_or(1);
    
    Ok(Json(ChannelResponse {
        id: channel.id,
        name: channel.name,
        description: channel.description,
        creator_id: channel.creator_id,
        creator_name: creator.name,
        avatar_url: channel.avatar_url,
        is_private: channel.is_private,
        member_count,
        last_message_time: None,
        created_at: channel.created_at,
    }))
}

pub async fn get_channels(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
) -> Result<Json<Vec<ChannelResponse>>, StatusCode> {
    let channels = ChannelService::get_user_channels(state.db.pool(), user_id)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get channels: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    
    Ok(Json(channels))
}

pub async fn get_channel_messages(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Path(channel_id): Path<Uuid>,
    Query(query): Query<MessageQuery>,
) -> Result<Json<Vec<ChannelMessageResponse>>, StatusCode> {
    // Verify user is member of channel
    let is_member: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM channel_members WHERE channel_id = $1 AND user_id = $2)",
    )
    .bind(channel_id)
    .bind(user_id)
    .fetch_one(state.db.pool())
    .await
    .unwrap_or(false);
    
    if !is_member {
        return Err(StatusCode::FORBIDDEN);
    }
    
    let limit = query.limit.unwrap_or(50);
    
    let messages = ChannelService::get_channel_messages(state.db.pool(), channel_id, limit)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get channel messages: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    
    Ok(Json(messages))
}

#[derive(Deserialize)]
pub struct MessageQuery {
    limit: Option<i64>,
}

pub async fn get_messages(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Path(conversation_id): Path<Uuid>,
    Query(query): Query<MessageQuery>,
) -> Result<Json<Vec<MessageResponse>>, StatusCode> {
    let limit = query.limit.unwrap_or(50);
    
    let messages = MessageService::get_conversation_messages(
        state.db.pool(),
        conversation_id,
        user_id,
        limit,
    )
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(messages.into_iter().map(Into::into).collect()))
}

pub async fn mark_message_read(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Path(message_id): Path<Uuid>,
) -> Result<StatusCode, StatusCode> {
    MessageService::mark_as_read(state.db.pool(), message_id, user_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(StatusCode::OK)
}

pub async fn start_call(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Json(payload): Json<crate::models::CallRequestPayload>,
) -> Result<Json<crate::models::Call>, StatusCode> {
    // Check if user already has an active call
    if let Ok(Some(_)) = crate::services::CallService::get_active_call(state.db.pool(), user_id).await {
        return Err(StatusCode::CONFLICT);
    }
    
    let call = crate::services::CallService::create_call(
        state.db.pool(),
        user_id,
        payload.recipient_id,
        &payload.call_type,
    )
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(call))
}

pub async fn get_call_history(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Query(query): Query<MessageQuery>,
) -> Result<Json<Vec<crate::models::CallHistoryResponse>>, StatusCode> {
    let limit = query.limit.unwrap_or(50);
    
    let calls = crate::services::CallService::get_user_call_history(
        state.db.pool(),
        user_id,
        limit,
    )
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(calls))
}

pub async fn get_active_call(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
) -> Result<Json<Option<crate::models::Call>>, StatusCode> {
    let call = crate::services::CallService::get_active_call(state.db.pool(), user_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(Json(call))
}

pub async fn update_presence(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Json(payload): Json<crate::models::UpdatePresenceRequest>,
) -> Result<Json<crate::models::UserPresence>, StatusCode> {
    // Valider le statut
    let valid_statuses = ["online", "offline", "away", "busy"];
    if !valid_statuses.contains(&payload.status.as_str()) {
        tracing::warn!("Invalid presence status: {}", payload.status);
        return Err(StatusCode::BAD_REQUEST);
    }
    
    let presence = crate::services::PresenceService::update_presence(
        state.db.pool(),
        user_id,
        &payload.status,
    )
    .await
    .map_err(|e| {
        tracing::error!("Failed to update presence: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    
    Ok(Json(presence))
}

pub async fn get_presence(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(_user_id): Extension<Uuid>,
    Path(target_user_id): Path<Uuid>,
) -> Result<Json<crate::models::UserPresence>, StatusCode> {
    let presence = crate::services::PresenceService::get_presence(
        state.db.pool(),
        target_user_id,
    )
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;
    
    Ok(Json(presence))
}

/// Store encrypted content for a message
/// 
/// SECURITY: This endpoint stores encrypted content as opaque binary data.
/// The backend cannot read or decrypt the content.
pub async fn store_encrypted_content(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Json(payload): Json<crate::models::EncryptedContentRequest>,
) -> Result<StatusCode, StatusCode> {
    // Verify that the user is the sender of the message
    let message = sqlx::query_as::<_, crate::models::Message>(
        "SELECT * FROM messages WHERE id = $1",
    )
    .bind(payload.message_id)
    .fetch_optional(state.db.pool())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;
    
    if message.sender_id != user_id {
        return Err(StatusCode::FORBIDDEN);
    }
    
    // Decode base64 content
    use base64::{Engine as _, engine::general_purpose};
    let content_data = general_purpose::STANDARD
        .decode(&payload.content_data)
        .map_err(|_| StatusCode::BAD_REQUEST)?;
    
    // Store as opaque binary (backend cannot read it)
    crate::services::EncryptedContentService::store_content(
        state.db.pool(),
        payload.message_id,
        &content_data,
        payload.content_hash.as_deref(),
        payload.expires_at,
    )
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    Ok(StatusCode::CREATED)
}

/// Retrieve encrypted content for a message
/// 
/// SECURITY: This endpoint returns encrypted content as opaque binary data.
/// The backend cannot decrypt it - decryption happens client-side.
pub async fn get_encrypted_content(
    Extension(state): Extension<std::sync::Arc<AppState>>,
    Extension(user_id): Extension<Uuid>,
    Path(message_id): Path<Uuid>,
) -> Result<Json<crate::models::EncryptedContentResponse>, StatusCode> {
    // Verify that the user is the sender or recipient
    let message = sqlx::query_as::<_, crate::models::Message>(
        "SELECT * FROM messages WHERE id = $1",
    )
    .bind(message_id)
    .fetch_optional(state.db.pool())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;
    
    if message.sender_id != user_id && message.recipient_id != user_id {
        return Err(StatusCode::FORBIDDEN);
    }
    
    // Get encrypted content (opaque binary)
    let content_data = crate::services::EncryptedContentService::get_content(
        state.db.pool(),
        message_id,
    )
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;
    
    // Get hash if available
    let content_hash: Option<String> = sqlx::query_scalar(
        "SELECT content_hash FROM encrypted_content WHERE message_id = $1",
    )
    .bind(message_id)
    .fetch_optional(state.db.pool())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    let created_at: DateTime<Utc> = sqlx::query_scalar(
        "SELECT created_at FROM encrypted_content WHERE message_id = $1",
    )
    .bind(message_id)
    .fetch_one(state.db.pool())
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    use base64::{Engine as _, engine::general_purpose};
    Ok(Json(crate::models::EncryptedContentResponse {
        message_id,
        content_data: general_purpose::STANDARD.encode(&content_data),
        content_hash,
        created_at,
    }))
}

