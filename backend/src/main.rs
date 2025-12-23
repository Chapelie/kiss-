use axum::{
    extract::Extension,
    routing::get,
    Router,
};
use std::sync::Arc;
use tokio::net::TcpListener;
use tower_http::cors::CorsLayer;
use tracing_subscriber;

mod config;
mod database;
mod handlers;
mod models;
mod routes;
mod security;
mod services;
mod websocket;
mod background;

use config::Config;
use database::Database;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    // Load environment variables
    dotenv::dotenv().ok();
    
    // Load configuration
    let config = Config::from_env()?;
    
    tracing::info!("🔧 Configuration loaded");
    tracing::info!("   Server: {}", config.server_address);
    tracing::info!("   Database: {}", config.database_url.split('@').nth(1).unwrap_or("***"));
    
    // Initialize database with retry logic
    let db = loop {
        match Database::new(&config.database_url).await {
            Ok(db) => break db,
            Err(e) => {
                tracing::warn!("⚠️ Failed to connect to database: {:?}", e);
                tracing::info!("   Retrying in 2 seconds...");
                tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
            }
        }
    };
    
    // Run migrations
    if let Err(e) = db.migrate().await {
        tracing::error!("❌ Migration failed: {:?}", e);
        return Err(e);
    }
    
    // Create shared state
    let app_state = Arc::new(AppState {
        db: db.clone(),
        config: config.clone(),
    });
    
    // Start background tasks
    background::start_background_tasks(app_state.clone()).await;
    
    // Build the application router
    let app = Router::new()
        .route("/health", get(health_check))
        .nest("/api", routes::create_api_routes())
        .route("/ws", get(websocket::handle_websocket))
        .layer(Extension(app_state))
        .layer(CorsLayer::permissive());
    
    // Start the server
    let listener = TcpListener::bind(&config.server_address).await?;
    tracing::info!("🚀 Server listening on {}", config.server_address);
    
    axum::serve(listener, app).await?;
    
    Ok(())
}

async fn health_check() -> &'static str {
    "OK"
}

#[derive(Clone)]
pub struct AppState {
    pub db: Database,
    pub config: Config,
}

