// Storage module for AgoraNet
// Will handle database connections and persistence

use sqlx::postgres::PgPool;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum StorageError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("Item not found")]
    NotFound,
    
    #[error("Unexpected error: {0}")]
    Other(String),
}

pub struct Storage {
    pool: PgPool,
}

impl Storage {
    pub async fn new(database_url: &str) -> Result<Self, StorageError> {
        let pool = PgPool::connect(database_url)
            .await
            .map_err(StorageError::Database)?;
            
        Ok(Self { pool })
    }
    
    // Thread storage operations would go here
    
    // Credential link storage operations would go here
} 