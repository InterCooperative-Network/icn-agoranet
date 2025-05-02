// Types module for AgoraNet
// Will contain data structures and serialization/deserialization logic

// Thread related types
pub mod thread {
    use serde::{Serialize, Deserialize};
    use chrono::{DateTime, Utc};
    use uuid::Uuid;
    use sqlx::FromRow;

    #[derive(Debug, Serialize, Deserialize, FromRow)]
    pub struct Thread {
        pub id: Uuid,
        pub title: String,
        pub proposal_cid: Option<String>,
        pub created_at: DateTime<Utc>,
        pub updated_at: DateTime<Utc>,
    }
    
    // Thread response shape for API endpoints
    #[derive(Debug, Serialize)]
    pub struct ThreadResponse {
        pub id: String,
        pub title: String,
        pub proposal_cid: Option<String>,
        pub created_at: DateTime<Utc>,
    }
    
    impl From<Thread> for ThreadResponse {
        fn from(thread: Thread) -> Self {
            Self {
                id: thread.id.to_string(),
                title: thread.title,
                proposal_cid: thread.proposal_cid,
                created_at: thread.created_at,
            }
        }
    }
}

// Credential related types
pub mod credential {
    use serde::{Serialize, Deserialize};
    use chrono::{DateTime, Utc};
    use uuid::Uuid;
    use sqlx::FromRow;

    #[derive(Debug, Serialize, Deserialize, FromRow)]
    pub struct CredentialLink {
        pub id: Uuid,
        pub thread_id: Uuid,
        pub credential_cid: String,
        pub linked_by: String, // DID
        pub created_at: DateTime<Utc>,
    }
    
    // Credential link response for API endpoints
    #[derive(Debug, Serialize)]
    pub struct CredentialLinkResponse {
        pub id: String,
        pub thread_id: String,
        pub credential_cid: String,
        pub linked_by: String,
        pub timestamp: i64,
    }
    
    impl From<CredentialLink> for CredentialLinkResponse {
        fn from(link: CredentialLink) -> Self {
            Self {
                id: link.id.to_string(),
                thread_id: link.thread_id.to_string(),
                credential_cid: link.credential_cid,
                linked_by: link.linked_by,
                timestamp: link.created_at.timestamp(),
            }
        }
    }
} 