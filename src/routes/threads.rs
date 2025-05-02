use axum::{
    Json, 
    Router, 
    routing::get,
    extract::State,
    http::StatusCode,
};
use serde::Deserialize;
use sqlx::PgPool;
use crate::storage::ThreadRepository;
use crate::types::thread::ThreadResponse;

// Thread creation request
#[derive(Debug, Deserialize)]
pub struct CreateThreadRequest {
    pub title: String,
    pub proposal_cid: Option<String>,
}

// Define the route handlers
pub fn routes() -> Router<PgPool> {
    Router::new()
        .route("/api/threads", get(list_threads).post(create_thread))
}

// Get all threads handler
async fn list_threads(
    State(pool): State<PgPool>
) -> Result<Json<Vec<ThreadResponse>>, StatusCode> {
    let thread_repo = ThreadRepository::new(pool);
    
    match thread_repo.list_threads().await {
        Ok(threads) => {
            let responses: Vec<ThreadResponse> = threads.into_iter()
                .map(|thread| thread.into())
                .collect();
            Ok(Json(responses))
        },
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

// Create thread handler
async fn create_thread(
    State(pool): State<PgPool>,
    Json(create_req): Json<CreateThreadRequest>,
) -> Result<Json<ThreadResponse>, StatusCode> {
    let thread_repo = ThreadRepository::new(pool);
    
    let proposal_cid_ref = create_req.proposal_cid.as_deref();
    
    match thread_repo.create_thread(&create_req.title, proposal_cid_ref).await {
        Ok(thread) => Ok(Json(thread.into())),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
} 