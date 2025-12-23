use axum::{
    extract::{
        ws::{Message, WebSocketUpgrade},
        Extension, Query,
    },
    response::Response,
};
use futures::{SinkExt, StreamExt};
use serde::Deserialize;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};
use tracing;
use uuid::Uuid;

use crate::models::*;
use crate::services::*;
use crate::AppState;

type Tx = broadcast::Sender<String>;
type PeerMap = Arc<RwLock<HashMap<Uuid, Tx>>>;

#[derive(Deserialize)]
pub struct WsQuery {
    pub token: String,
}

pub async fn handle_websocket(
    ws: WebSocketUpgrade,
    Extension(state): Extension<Arc<AppState>>,
    Query(query): Query<WsQuery>,
) -> Response {
    // Verify token
    let user_id = match AuthService::verify_token(&query.token, &state.config.jwt_secret) {
        Ok(id) => id,
        Err(_) => {
            return axum::response::Response::builder()
                .status(axum::http::StatusCode::UNAUTHORIZED)
                .body(axum::body::Body::from("Unauthorized"))
                .unwrap()
                .into();
        }
    };
    
    // Get or create peer map
    let peer_map = get_peer_map();
    
    // Create channel for this connection
    let (tx, _rx) = broadcast::channel(100);
    peer_map.write().await.insert(user_id, tx.clone());
    
    tracing::info!("🔌 WebSocket connection established for user: {}", user_id);
    
    let state_clone = state.clone();
    let peer_map_clone = peer_map.clone();
    let user_id_clone = user_id;
    
    // Update and broadcast presence
    broadcast_presence_update(&peer_map, user_id, "online", &state).await;
    
    // Send current presence status to the newly connected user for all their contacts
    if let Ok(conversations) = crate::services::ConversationService::get_user_conversations(
        state.db.pool(),
        user_id,
    )
    .await
    {
        let participant_ids: Vec<Uuid> = conversations
            .iter()
            .map(|c| c.participant_id)
            .collect();
        
        if !participant_ids.is_empty() {
            if let Ok(presences) = crate::services::PresenceService::get_multiple_presences(
                state.db.pool(),
                &participant_ids,
            )
            .await
            {
                for presence in presences {
                    let update = WebSocketMessage::PresenceUpdate {
                        payload: PresenceUpdate {
                            user_id: presence.user_id,
                            status: presence.status,
                            last_seen: presence.last_seen,
                        },
                    };
                    send_to_user(&peer_map, user_id, &update).await;
                }
            }
        }
    }
    
    ws.on_upgrade(move |socket| async move {
        // Handle WebSocket
        let (mut sender, mut receiver) = socket.split();
        
        // Spawn task to handle incoming messages
        let peer_map_msg = peer_map_clone.clone();
        let state_msg = state_clone.clone();
        let user_id_msg = user_id_clone;
        let mut rx = tx.subscribe();
        
        tokio::spawn(async move {
            while let Some(msg) = receiver.next().await {
                match msg {
                    Ok(Message::Text(text)) => {
                        if let Err(e) = handle_websocket_message(
                            &text,
                            user_id_msg,
                            &peer_map_msg,
                            &state_msg,
                        )
                        .await
                        {
                            tracing::error!("Error handling WebSocket message: {}", e);
                        }
                    }
                    Ok(Message::Close(_)) => {
                        break;
                    }
                    Err(e) => {
                        tracing::error!("WebSocket error: {}", e);
                        break;
                    }
                    _ => {}
                }
            }
            
            // Cleanup on disconnect
            peer_map_msg.write().await.remove(&user_id_msg);
            broadcast_presence_update(&peer_map_msg, user_id_msg, "offline", &state_msg).await;
            tracing::info!("🔌 WebSocket disconnected for user: {}", user_id_msg);
        });
        
        // Spawn task to send messages to this connection
        tokio::spawn(async move {
            while let Ok(msg) = rx.recv().await {
                if sender.send(Message::Text(msg)).await.is_err() {
                    break;
                }
            }
        });
    })
}

async fn handle_websocket_message(
    text: &str,
    user_id: Uuid,
    peer_map: &PeerMap,
    state: &AppState,
) -> anyhow::Result<()> {
    let message: WebSocketMessage = serde_json::from_str(text)?;
    
    match message {
        WebSocketMessage::Message { payload } => {
            handle_message(payload, user_id, peer_map, state).await?;
        }
        WebSocketMessage::CallRequest { payload } => {
            handle_call_request(payload, user_id, peer_map, state).await?;
        }
        WebSocketMessage::CallResponse { payload } => {
            handle_call_response(payload, user_id, peer_map, state).await?;
        }
        WebSocketMessage::TypingIndicator { payload } => {
            handle_typing_indicator(payload, user_id, peer_map).await?;
        }
        WebSocketMessage::ReadReceipt { payload } => {
            handle_read_receipt(payload, user_id, state).await?;
        }
        WebSocketMessage::PresenceUpdate { payload } => {
            handle_presence_update(payload, user_id, peer_map, state).await?;
        }
        WebSocketMessage::Heartbeat { payload: _ } => {
            handle_heartbeat(user_id, peer_map).await?;
        }
        _ => {}
    }
    
    Ok(())
}

/// Handle incoming message metadata
/// 
/// SECURITY: This function processes ONLY metadata.
/// The encrypted content is NOT transmitted via WebSocket.
/// The backend acts as a blind gateway - it cannot read message content.
async fn handle_message(
    payload: crate::models::MessageRequest,
    sender_id: Uuid,
    peer_map: &PeerMap,
    state: &AppState,
) -> anyhow::Result<()> {
    // Store ONLY metadata in database (no content, no keys)
    let message = MessageService::create_message(
        state.db.pool(),
        sender_id,
        payload.recipient_id,
        &payload.message_type,
        payload.session_id.as_deref(),
    )
    .await?;
    
    let message_response: MessageResponse = message.into();
    
    // Send confirmation to sender with the created message ID
    let confirmation = WebSocketMessage::MessageResponse {
        payload: message_response.clone(),
    };
    send_to_user(peer_map, sender_id, &confirmation).await;
    
    // Route metadata to recipient via WebSocket
    // The encrypted content is handled separately by clients
    let ws_message = WebSocketMessage::MessageResponse {
        payload: message_response.clone(),
    };
    send_to_user(peer_map, payload.recipient_id, &ws_message).await;
    
    Ok(())
}

async fn handle_call_request(
    payload: CallRequestPayload,
    caller_id: Uuid,
    peer_map: &PeerMap,
    state: &AppState,
) -> anyhow::Result<()> {
    // Check if caller already has an active call
    if let Ok(Some(_)) = crate::services::CallService::get_active_call(state.db.pool(), caller_id).await {
        return Ok(()); // Already in a call
    }
    
    // Check if recipient already has an active call
    if let Ok(Some(_)) = crate::services::CallService::get_active_call(state.db.pool(), payload.recipient_id).await {
        // Recipient is busy, create call with busy status
        let call = crate::services::CallService::create_call(
            state.db.pool(),
            caller_id,
            payload.recipient_id,
            &payload.call_type,
        )
        .await?;
        
        let _ = crate::services::CallService::update_call_status(
            state.db.pool(),
            &call.call_id,
            "busy",
        )
        .await;
        
        // Send busy response to caller
        let response = WebSocketMessage::CallResponseFull {
            payload: CallResponse {
                call_id: call.call_id.clone(),
                response: "busy".to_string(),
                timestamp: chrono::Utc::now(),
            },
        };
        send_to_user(peer_map, caller_id, &response).await;
        return Ok(());
    }
    
    // Create call in database
    let call = crate::services::CallService::create_call(
        state.db.pool(),
        caller_id,
        payload.recipient_id,
        &payload.call_type,
    )
    .await?;
    
    // Send call request to recipient
    let call_request = WebSocketMessage::CallRequestFull {
        payload: CallRequest {
            call_id: call.call_id.clone(),
            caller_id,
            recipient_id: payload.recipient_id,
            call_type: payload.call_type,
            timestamp: chrono::Utc::now(),
        },
    };
    send_to_user(peer_map, payload.recipient_id, &call_request).await;
    
    Ok(())
}

async fn handle_call_response(
    payload: CallResponsePayload,
    responder_id: Uuid,
    peer_map: &PeerMap,
    state: &AppState,
) -> anyhow::Result<()> {
    // Get call from database
    let call = match crate::services::CallService::get_call_by_id(state.db.pool(), &payload.call_id).await? {
        Some(call) => call,
        None => return Ok(()), // Call not found
    };
    
    // Verify responder is the recipient
    if call.recipient_id != responder_id {
        return Ok(()); // Not authorized
    }
    
    match payload.response.as_str() {
        "accept" => {
            // Accept call
            let _ = crate::services::CallService::accept_call(state.db.pool(), &payload.call_id).await;
            
            // Send response to caller
            let response = WebSocketMessage::CallResponseFull {
                payload: CallResponse {
                    call_id: payload.call_id.clone(),
                    response: "accept".to_string(),
                    timestamp: chrono::Utc::now(),
                },
            };
            send_to_user(peer_map, call.caller_id, &response).await;
        }
        "reject" | "busy" => {
            // Reject or busy
            let _ = crate::services::CallService::update_call_status(
                state.db.pool(),
                &payload.call_id,
                &payload.response,
            )
            .await;
            
            // Send response to caller
            let response = WebSocketMessage::CallResponseFull {
                payload: CallResponse {
                    call_id: payload.call_id.clone(),
                    response: payload.response.clone(),
                    timestamp: chrono::Utc::now(),
                },
            };
            send_to_user(peer_map, call.caller_id, &response).await;
        }
        "end" => {
            // End call
            let _ = crate::services::CallService::end_call(state.db.pool(), &payload.call_id).await;
            
            // Notify both parties
            let response = WebSocketMessage::CallResponseFull {
                payload: CallResponse {
                    call_id: payload.call_id.clone(),
                    response: "end".to_string(),
                    timestamp: chrono::Utc::now(),
                },
            };
            send_to_user(peer_map, call.caller_id, &response).await;
            send_to_user(peer_map, call.recipient_id, &response).await;
        }
        _ => {}
    }
    
    Ok(())
}

async fn handle_typing_indicator(
    payload: TypingIndicator,
    _user_id: Uuid,
    peer_map: &PeerMap,
) -> anyhow::Result<()> {
    let ws_message = WebSocketMessage::TypingIndicator { payload };
    // Send to conversation participants
    // This is simplified - in production, get conversation participants
    broadcast_to_all(peer_map, &ws_message).await;
    Ok(())
}

async fn handle_read_receipt(
    payload: ReadReceipt,
    reader_id: Uuid,
    state: &AppState,
) -> anyhow::Result<()> {
    MessageService::mark_as_read(state.db.pool(), payload.message_id, reader_id).await?;
    Ok(())
}

async fn handle_heartbeat(user_id: Uuid, peer_map: &PeerMap) -> anyhow::Result<()> {
    let response = WebSocketMessage::HeartbeatResponse {
        payload: HeartbeatPayload {
            timestamp: chrono::Utc::now(),
        },
    };
    send_to_user(peer_map, user_id, &response).await;
    Ok(())
}

async fn send_to_user(peer_map: &PeerMap, user_id: Uuid, message: &WebSocketMessage) {
    let peers = peer_map.read().await;
    if let Some(tx) = peers.get(&user_id) {
        if let Ok(json) = serde_json::to_string(message) {
            let _ = tx.send(json);
        }
    }
}

async fn broadcast_to_all(peer_map: &PeerMap, message: &WebSocketMessage) {
    let peers = peer_map.read().await;
    if let Ok(json) = serde_json::to_string(message) {
        for tx in peers.values() {
            let _ = tx.send(json.clone());
        }
    }
}

async fn handle_presence_update(
    payload: PresenceUpdate,
    user_id: Uuid,
    peer_map: &PeerMap,
    state: &AppState,
) -> anyhow::Result<()> {
    // Update presence in database
    let _ = crate::services::PresenceService::update_presence(
        state.db.pool(),
        user_id,
        &payload.status,
    )
    .await?;
    
    // Broadcast to all connected users
    let update = WebSocketMessage::PresenceUpdate { payload };
    broadcast_to_all(peer_map, &update).await;
    
    Ok(())
}

async fn broadcast_presence_update(
    peer_map: &PeerMap,
    user_id: Uuid,
    status: &str,
    state: &AppState,
) {
    // Update in database
    if let Ok(_) = crate::services::PresenceService::update_presence(
        state.db.pool(),
        user_id,
        status,
    )
    .await
    {
        let update = WebSocketMessage::PresenceUpdate {
            payload: PresenceUpdate {
                user_id,
                status: status.to_string(),
                last_seen: chrono::Utc::now(),
            },
        };
        
        // Broadcast to all connected users
        broadcast_to_all(peer_map, &update).await;
    }
}

fn get_peer_map() -> PeerMap {
    use std::sync::OnceLock;
    static PEER_MAP: OnceLock<PeerMap> = OnceLock::new();
    PEER_MAP
        .get_or_init(|| Arc::new(RwLock::new(HashMap::new())))
        .clone()
}

