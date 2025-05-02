use axum::{Json, Router, routing::get};
use serde::Serialize;

pub fn routes() -> Router {
    Router::new().route("/api/threads", get(list_threads))
}

#[derive(Serialize)]
struct Thread {
    id: String,
    title: String,
    proposal_cid: Option<String>,
}

async fn list_threads() -> Json<Vec<Thread>> {
    Json(vec![
        Thread {
            id: "thread-1".to_string(),
            title: "Guardian Recovery Proposal".to_string(),
            proposal_cid: Some("bafy...".to_string()),
        }
    ])
} 