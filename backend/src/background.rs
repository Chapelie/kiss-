use crate::services::*;
use crate::AppState;
use chrono::Utc;
use sqlx::PgPool;
use std::sync::Arc;
use std::time::Duration;

/// Démarre les tâches en arrière-plan
pub async fn start_background_tasks(state: Arc<AppState>) {
    let db = state.db.clone();
    
    // Tâche 1: Timeout pour appels pending (toutes les 30 secondes)
    let db_clone = db.clone();
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(30));
        loop {
            interval.tick().await;
            if let Err(e) = timeout_pending_calls(db_clone.pool()).await {
                tracing::error!("Erreur lors du timeout des appels pending: {}", e);
            }
        }
    });
    
    // Tâche 2: Nettoyage contenu expiré (toutes les heures)
    let db_clone = db.clone();
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(3600));
        loop {
            interval.tick().await;
            if let Err(e) = cleanup_expired_content(db_clone.pool()).await {
                tracing::error!("Erreur lors du nettoyage du contenu expiré: {}", e);
            }
        }
    });
    
    // Tâche 3: Mise à jour automatique last_seen et marquer offline après timeout (toutes les 5 minutes)
    let db_clone = db.clone();
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(300));
        loop {
            interval.tick().await;
            // Mettre à jour last_seen pour les utilisateurs en ligne
            if let Err(e) = update_online_users_last_seen(db_clone.pool()).await {
                tracing::error!("Erreur lors de la mise à jour last_seen: {}", e);
            }
            // Marquer offline les utilisateurs qui n'ont pas été vus depuis 5 minutes
            if let Err(e) = crate::services::PresenceService::mark_offline_after_timeout(
                db_clone.pool(),
                5, // 5 minutes timeout
            )
            .await
            {
                tracing::error!("Erreur lors du marquage offline: {}", e);
            }
        }
    });
    
    tracing::info!("✅ Tâches en arrière-plan démarrées");
}

/// Marque les appels pending comme missed après 60 secondes
async fn timeout_pending_calls(pool: &PgPool) -> anyhow::Result<()> {
    let timeout_seconds = 60;
    let cutoff_time = Utc::now() - chrono::Duration::seconds(timeout_seconds);
    
    let updated = sqlx::query(
        r#"
        UPDATE calls
        SET status = 'missed', updated_at = NOW()
        WHERE status = 'pending'
        AND created_at < $1
        "#
    )
    .bind(cutoff_time)
    .execute(pool)
    .await?;
    
    if updated.rows_affected() > 0 {
        tracing::info!("⏰ {} appels pending marqués comme missed", updated.rows_affected());
    }
    
    Ok(())
}

/// Nettoie le contenu chiffré expiré
async fn cleanup_expired_content(pool: &PgPool) -> anyhow::Result<()> {
    let deleted = EncryptedContentService::cleanup_expired(pool).await?;
    
    if deleted > 0 {
        tracing::info!("🧹 {} contenus expirés supprimés", deleted);
    }
    
    Ok(())
}

/// Met à jour automatiquement last_seen pour les utilisateurs en ligne
async fn update_online_users_last_seen(pool: &PgPool) -> anyhow::Result<()> {
    let updated = sqlx::query(
        r#"
        UPDATE user_presence
        SET last_seen = NOW(), updated_at = NOW()
        WHERE status = 'online'
        AND last_seen < NOW() - INTERVAL '5 minutes'
        "#
    )
    .execute(pool)
    .await?;
    
    if updated.rows_affected() > 0 {
        tracing::debug!("🔄 {} utilisateurs en ligne mis à jour", updated.rows_affected());
    }
    
    Ok(())
}

