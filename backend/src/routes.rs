use axum::{
    extract::{Extension, Request},
    http::StatusCode,
    middleware::Next,
    response::Response,
    routing::{get, post},
    Router,
};

use crate::handlers;
use crate::services::AuthService;
use crate::AppState;

pub fn create_api_routes() -> Router {
    // NOTE: Rate limiting sera implémenté avec un middleware personnalisé
    // ou une bibliothèque externe (ex: tower-governor avec Redis en production)
    // Pour l'instant, la validation des données est la priorité
    
    let public_routes = Router::new()
        .route("/auth/register", post(handlers::register))
        .route("/auth/login", post(handlers::login));
    
    let protected_routes = Router::new()
        .route("/auth/me", get(handlers::get_me))
        .route("/users/search", get(handlers::search_users))
        .route("/users/find-by-email", get(handlers::find_user_by_email))
        .route("/conversations", get(handlers::get_conversations))
        .route("/conversations", post(handlers::create_conversation))
        .route("/conversations/:id/messages", get(handlers::get_messages))
        .route("/messages/:id/read", post(handlers::mark_message_read))
        .route("/messages/:id/content", post(handlers::store_encrypted_content))
        .route("/messages/:id/content", get(handlers::get_encrypted_content))
        .route("/stories", get(handlers::get_stories))
        .route("/stories", post(handlers::create_story))
        .route("/stories/:id/view", post(handlers::view_story))
        .route("/channels", get(handlers::get_channels))
        .route("/channels", post(handlers::create_channel))
        .route("/channels/:id/messages", get(handlers::get_channel_messages))
        .route("/calls", post(handlers::start_call))
        .route("/calls/history", get(handlers::get_call_history))
        .route("/calls/active", get(handlers::get_active_call))
        .route("/presence", post(handlers::update_presence))
        .route("/presence/:id", get(handlers::get_presence))
        .layer(axum::middleware::from_fn(auth_middleware));
    
    Router::new()
        .merge(public_routes)
        .merge(protected_routes)
}

async fn auth_middleware(
    mut request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    use uuid::Uuid;
    
    // Skip auth for public routes
    let path = request.uri().path().to_string(); // Clone the path to avoid borrow issues
    // Les routes sont montées sous /api, donc le path complet est /api/auth/...
    if path.starts_with("/api/auth/register") || path.starts_with("/api/auth/login") {
        return Ok(next.run(request).await);
    }
    
    let auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .and_then(|s| s.strip_prefix("Bearer "));
    
    if let Some(token) = auth_header {
        let state = request
            .extensions()
            .get::<std::sync::Arc<AppState>>()
            .ok_or_else(|| {
                tracing::error!("AppState not found in extensions");
                StatusCode::INTERNAL_SERVER_ERROR
            })?;
        
        match AuthService::verify_token(token, &state.config.jwt_secret) {
            Ok(user_id) => {
                // In Axum 0.7, insert the value directly (not the Extension wrapper)
                // The Extension extractor will wrap it automatically
                request.extensions_mut().insert(user_id);
                tracing::info!("✅ Authenticated user: {} for path: {}", user_id, path);
                return Ok(next.run(request).await);
            }
            Err(e) => {
                tracing::warn!("❌ Token verification failed for path {}: {:?}", path, e);
                tracing::warn!("   Token (first 20 chars): {}", &token[..token.len().min(20)]);
                return Err(StatusCode::UNAUTHORIZED);
            }
        }
    }
    
    tracing::warn!("❌ No authorization header found for path: {}", path);
    Err(StatusCode::UNAUTHORIZED)
}

