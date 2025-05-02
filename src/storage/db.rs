use sqlx::postgres::{PgPool, PgPoolOptions};
use tracing::info;

pub async fn create_db_pool() -> Result<PgPool, sqlx::Error> {
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set in environment variables");
    
    info!("Connecting to database...");
    
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;
    
    info!("Database connection established");
    
    Ok(pool)
} 