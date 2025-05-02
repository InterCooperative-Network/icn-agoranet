use sqlx::PgPool;
use crate::types::thread::Thread;
use super::{Result, StorageError};
use uuid::Uuid;

pub struct ThreadRepository {
    pool: PgPool,
}

impl ThreadRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn list_threads(&self) -> Result<Vec<Thread>> {
        let threads = sqlx::query_as!(
            Thread,
            r#"
            SELECT id, title, proposal_cid, created_at, updated_at
            FROM threads
            ORDER BY created_at DESC
            "#
        )
        .fetch_all(&self.pool)
        .await
        .map_err(StorageError::Database)?;

        Ok(threads)
    }

    pub async fn get_thread(&self, id: Uuid) -> Result<Thread> {
        let thread = sqlx::query_as!(
            Thread,
            r#"
            SELECT id, title, proposal_cid, created_at, updated_at
            FROM threads
            WHERE id = $1
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(StorageError::Database)?
        .ok_or(StorageError::NotFound)?;

        Ok(thread)
    }
    
    pub async fn find_thread_by_proposal_cid(&self, proposal_cid: &str) -> Result<Thread> {
        let thread = sqlx::query_as!(
            Thread,
            r#"
            SELECT id, title, proposal_cid, created_at, updated_at
            FROM threads
            WHERE proposal_cid = $1
            "#,
            proposal_cid
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(StorageError::Database)?
        .ok_or(StorageError::NotFound)?;

        Ok(thread)
    }

    pub async fn create_thread(&self, title: &str, proposal_cid: Option<&str>) -> Result<Thread> {
        let id = Uuid::new_v4();
        
        let thread = sqlx::query_as!(
            Thread,
            r#"
            INSERT INTO threads (id, title, proposal_cid)
            VALUES ($1, $2, $3)
            RETURNING id, title, proposal_cid, created_at, updated_at
            "#,
            id,
            title,
            proposal_cid
        )
        .fetch_one(&self.pool)
        .await
        .map_err(StorageError::Database)?;

        Ok(thread)
    }
    
    pub async fn update_thread(&self, id: Uuid, title: &str) -> Result<Thread> {
        let thread = sqlx::query_as!(
            Thread,
            r#"
            UPDATE threads
            SET title = $1, updated_at = NOW()
            WHERE id = $2
            RETURNING id, title, proposal_cid, created_at, updated_at
            "#,
            title,
            id
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(StorageError::Database)?
        .ok_or(StorageError::NotFound)?;

        Ok(thread)
    }
} 