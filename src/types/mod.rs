// Types module for AgoraNet
// Will contain data structures and serialization/deserialization logic

// Thread related types
pub mod thread {
    use serde::{Serialize, Deserialize};
    use chrono::{DateTime, Utc};
    use uuid::Uuid;

    #[derive(Debug, Serialize, Deserialize)]
    pub struct Thread {
        pub id: Uuid,
        pub title: String,
        pub proposal_cid: Option<String>,
        pub created_at: DateTime<Utc>,
        pub updated_at: DateTime<Utc>,
    }
}

// Credential related types
pub mod credential {
    use serde::{Serialize, Deserialize};
    use chrono::{DateTime, Utc};
    use uuid::Uuid;

    #[derive(Debug, Serialize, Deserialize)]
    pub struct CredentialLink {
        pub id: Uuid,
        pub thread_id: Uuid,
        pub credential_cid: String,
        pub linked_by: String, // DID
        pub created_at: DateTime<Utc>,
    }
} 