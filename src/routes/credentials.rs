use axum::{Json, Router, routing::{post, get}};
use serde::{Serialize, Deserialize};

pub fn routes() -> Router {
    Router::new()
        .route("/api/threads/credential-link", post(link_credential))
        .route("/api/threads/credential-links", get(list_links))
}

#[derive(Deserialize)]
struct CredentialLinkRequest {
    thread_id: String,
    credential_cid: String,
    signer_did: String,
}

#[derive(Serialize)]
struct CredentialLink {
    thread_id: String,
    credential_cid: String,
    linked_by: String,
    timestamp: i64,
}

async fn link_credential(Json(req): Json<CredentialLinkRequest>) -> Json<CredentialLink> {
    Json(CredentialLink {
        thread_id: req.thread_id,
        credential_cid: req.credential_cid,
        linked_by: req.signer_did,
        timestamp: chrono::Utc::now().timestamp(),
    })
}

async fn list_links() -> Json<Vec<CredentialLink>> {
    Json(vec![CredentialLink {
        thread_id: "thread-1".to_string(),
        credential_cid: "bafy...".to_string(),
        linked_by: "did:icn:indv:xyz".to_string(),
        timestamp: chrono::Utc::now().timestamp(),
    }])
} 