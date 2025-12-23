use sqlx::{postgres::PgPoolOptions, PgPool};
use tracing;

pub struct Database {
    pool: PgPool,
}

impl Database {
    pub async fn new(database_url: &str) -> anyhow::Result<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(10)
            .connect(database_url)
            .await?;
        
        tracing::info!("✅ Connected to database");
        
        Ok(Database { pool })
    }
    
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }
    
    pub async fn migrate(&self) -> anyhow::Result<()> {
        // sqlx::migrate! requires a string literal at compile time
        // The migrations directory is copied to /app/migrations in Docker
        // and ./migrations in local development
        // We use ./migrations which should work in both cases:
        // - In Docker: working dir is /app, so ./migrations = /app/migrations
        // - In local: working dir is backend/, so ./migrations = backend/migrations
        sqlx::migrate!("./migrations")
            .run(self.pool())
            .await
            .map_err(|e| {
                tracing::error!("❌ Failed to run migrations: {:?}", e);
                tracing::error!("   Current working directory might be wrong");
                tracing::error!("   Expected migrations at: ./migrations");
                e
            })?;
        
        tracing::info!("✅ Database migrations completed");
        Ok(())
    }
}

impl Clone for Database {
    fn clone(&self) -> Self {
        Database {
            pool: self.pool.clone(),
        }
    }
}

