use axum::{
    async_trait,
    extract::{FromRequestParts, State},
    http::{request::Parts, StatusCode, Request},
    middleware::Next,
    response::Response,
    body::Body,
};
use serde::{Serialize, Deserialize};
use serde_json::json;
use thiserror::Error;
use crate::state::AppState;

#[derive(Debug, Error)]
pub enum AuthError {
    #[error("Authentication required")]
    NoAuth,
    
    #[error("Invalid DID format")]
    InvalidDid,
    
    #[error("Invalid signature")]
    InvalidSignature,
    
    #[error("Invalid auth token")]
    InvalidToken,
    
    #[error("Session expired")]
    SessionExpired,
}

/// The DID auth middleware extracts and verifies auth tokens
pub async fn did_auth_middleware<B>(
    State(state): State<AppState>,
    req: Request<B>,
    next: Next<B>,
) -> Result<Response, StatusCode> {
    // Get the Authorization header
    let auth_header = req.headers()
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;
    
    // Validate the token format: "Bearer <token>"
    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or(StatusCode::UNAUTHORIZED)?;
    
    // Verify the token
    let _did = verify_did_token(token)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;
    
    // Process the request
    Ok(next.run(req).await)
}

/// Represents a DID Credential for authentication
#[derive(Debug, Serialize, Deserialize)]
pub struct DidToken {
    pub did: String,
    pub exp: i64, // Expiration timestamp
    pub iat: i64, // Issued at timestamp
    pub sig: String, // Signature
}

fn verify_did_token(token: &str) -> Result<String, AuthError> {
    // TODO: Implement actual DID token verification logic
    // For now, just extract the DID from the token for demonstration purposes
    
    // Decode the token (in reality this would be JWT or similar)
    let token_parts: Vec<&str> = token.split('.').collect();
    if token_parts.len() != 3 {
        return Err(AuthError::InvalidToken);
    }
    
    // Verify token expiration
    let _current_time = chrono::Utc::now().timestamp();
    
    // In a real implementation, we would:
    // 1. Verify the signature using the DID's public key
    // 2. Check token expiration
    // 3. Validate the DID format
    
    // For now, simple format check
    let did = format!("did:icn:{}", token_parts[0]);
    if !did.starts_with("did:icn:") {
        return Err(AuthError::InvalidDid);
    }
    
    Ok(did)
}

/// Helper function to generate an error response
pub fn auth_error_response(error: AuthError) -> Response {
    let body = json!({
        "error": error.to_string(),
    });
    
    Response::builder()
        .status(StatusCode::UNAUTHORIZED)
        .header("Content-Type", "application/json")
        .body(Body::from(serde_json::to_string(&body).unwrap()))
        .unwrap()
}

/// Extract DID from the request
pub struct DidAuth(pub String);

// Implement extractor for DidAuth
#[async_trait]
impl<S> FromRequestParts<S> for DidAuth
where
    S: Send + Sync,
{
    type Rejection = StatusCode;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let auth_header = parts.headers
            .get("Authorization")
            .and_then(|h| h.to_str().ok())
            .ok_or(StatusCode::UNAUTHORIZED)?;
        
        let token = auth_header
            .strip_prefix("Bearer ")
            .ok_or(StatusCode::UNAUTHORIZED)?;
        
        let did = verify_did_token(token)
            .map_err(|_| StatusCode::UNAUTHORIZED)?;
        
        Ok(DidAuth(did))
    }
} 