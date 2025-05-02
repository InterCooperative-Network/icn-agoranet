use axum::{
    Json, 
    Router, 
    routing::{post, get},
    extract::State,
    http::StatusCode,
};
use serde::Deserialize;
use sqlx::PgPool;
use crate::storage::CredentialLinkRepository;
use crate::types::credential::CredentialLinkResponse;

// Define public request and response types
#[derive(Deserialize, Debug)]
pub struct CredentialLinkRequest {
    pub thread_id: String,
    pub credential_cid: String,
    pub signer_did: String,
}

// Define the route handlers
pub fn routes() -> Router<PgPool> {
    Router::new()
        .route("/api/threads/credential-link", post(link_credential))
        .route("/api/threads/credential-links", get(list_links))
}

// Create a credential link
async fn link_credential(
    State(pool): State<PgPool>,
    Json(req): Json<CredentialLinkRequest>
) -> Result<Json<CredentialLinkResponse>, StatusCode> {
    let link_repo = CredentialLinkRepository::new(pool);
    
    match link_repo.create_credential_link(&req).await {
        Ok(link) => Ok(Json(link.into())),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

// List credential links
async fn list_links(
    State(pool): State<PgPool>
) -> Result<Json<Vec<CredentialLinkResponse>>, StatusCode> {
    let link_repo = CredentialLinkRepository::new(pool);
    
    match link_repo.list_credential_links().await {
        Ok(links) => {
            let responses: Vec<CredentialLinkResponse> = links.into_iter()
                .map(|link| link.into())
                .collect();
            Ok(Json(responses))
        },
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
} 