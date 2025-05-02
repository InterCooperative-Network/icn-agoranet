use axum::{
    Json, 
    Router, 
    routing::{get, post},
    extract::State,
    http::StatusCode,
    middleware,
};
use serde::{Serialize, Deserialize};
use sqlx::PgPool;
use crate::storage::ThreadRepository;
use crate::types::thread::{Thread, ThreadResponse};
use crate::auth::{did_auth_middleware, DidAuth};
use crate::state::AppState;
use uuid::Uuid;

// Thread creation request
#[derive(Debug, Deserialize)]
pub struct CreateThreadRequest {
    pub title: String,
    pub proposal_cid: Option<String>,
}

// Define the route handlers
pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/api/threads", get(list_threads))
        .route("/api/threads/:id", get(get_thread))
        .route("/api/threads", post(create_thread))
        .layer(middleware::from_fn_with_state::<AppState, _>(did_auth_middleware))
}

// Get all threads handler
async fn list_threads(
    State(state): State<AppState>
) -> Result<Json<Vec<ThreadResponse>>, StatusCode> {
    let thread_repo = ThreadRepository::new(state.db_pool);
    
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

// Get a specific thread by ID
async fn get_thread(
    State(state): State<AppState>,
    axum::extract::Path(id): axum::extract::Path<String>,
) -> Result<Json<ThreadResponse>, StatusCode> {
    let thread_repo = ThreadRepository::new(state.db_pool);
    
    let id = Uuid::parse_str(&id)
        .map_err(|_| StatusCode::BAD_REQUEST)?;
    
    match thread_repo.get_thread(id).await {
        Ok(thread) => Ok(Json(thread.into())),
        Err(crate::storage::StorageError::NotFound) => Err(StatusCode::NOT_FOUND),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

// Create thread handler (requires authentication)
async fn create_thread(
    State(state): State<AppState>,
    auth: DidAuth,
    Json(create_req): Json<CreateThreadRequest>,
) -> Result<Json<ThreadResponse>, StatusCode> {
    let thread_repo = ThreadRepository::new(state.db_pool.clone());
    
    let proposal_cid_ref = create_req.proposal_cid.as_deref();
    
    match thread_repo.create_thread(&create_req.title, proposal_cid_ref).await {
        Ok(thread) => {
            // Announce the new thread to the federation if enabled
            if let Some(federation) = state.federation() {
                if let Err(e) = federation.announce_thread(&thread.id.to_string()).await {
                    tracing::warn!("Failed to announce thread: {}", e);
                    // Don't return an error, as the thread was created successfully
                }
            }
            
            Ok(Json(thread.into()))
        },
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
} 