use actix_web::{post, get, web, HttpResponse, Responder};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use std::sync::Mutex;
use crate::models::thread::{Thread, ThreadStatus};
use crate::database::Database;

#[derive(Debug, Deserialize)]
pub struct CreateThreadRequest {
    /// Title of the thread
    pub title: String,
    
    /// Content/body of the thread
    pub content: String,
    
    /// DID of the author
    pub author_did: String,
    
    /// Optional proposal ID that this thread is about
    pub proposal_id: Option<String>,
    
    /// Optional federation ID
    pub federation_id: Option<String>,
    
    /// Optional tags for the thread
    pub tags: Option<Vec<String>>,
}

/// Create a new thread
#[post("/threads")]
pub async fn create_thread(
    db: web::Data<Mutex<Database>>,
    req: web::Json<CreateThreadRequest>,
) -> impl Responder {
    let mut db = db.lock().unwrap();
    
    // Generate a unique ID for the thread
    let thread_id = Uuid::new_v4().to_string();
    
    // Create the new thread
    let mut thread = Thread::new(
        thread_id,
        req.title.clone(),
        req.content.clone(),
        req.author_did.clone(),
        req.proposal_id.clone(),
    );
    
    // Add optional fields
    if let Some(federation_id) = &req.federation_id {
        thread.federation_id = Some(federation_id.clone());
    }
    
    if let Some(tags) = &req.tags {
        for tag in tags {
            thread.add_tag(tag.clone());
        }
    }
    
    // Store the thread
    db.threads.push(thread.clone());
    
    // Return the created thread
    HttpResponse::Created().json(thread)
}

#[derive(Debug, Deserialize)]
pub struct GetThreadsQuery {
    /// Filter by proposal ID
    pub proposal_id: Option<String>,
    
    /// Filter by federation ID
    pub federation_id: Option<String>,
    
    /// Filter by author DID
    pub author_did: Option<String>,
    
    /// Filter by thread status
    pub status: Option<String>,
    
    /// Maximum number of threads to return
    pub limit: Option<usize>,
    
    /// Skip the first N threads
    pub offset: Option<usize>,
}

/// Get a list of threads with optional filtering
#[get("/threads")]
pub async fn get_threads(
    db: web::Data<Mutex<Database>>,
    query: web::Query<GetThreadsQuery>,
) -> impl Responder {
    let db = db.lock().unwrap();
    
    // Filter threads based on query parameters
    let mut filtered_threads: Vec<&Thread> = db.threads.iter()
        .filter(|thread| {
            // Filter by proposal ID if provided
            if let Some(proposal_id) = &query.proposal_id {
                if let Some(thread_proposal_id) = &thread.proposal_id {
                    if proposal_id != thread_proposal_id {
                        return false;
                    }
                } else {
                    return false;
                }
            }
            
            // Filter by federation ID if provided
            if let Some(federation_id) = &query.federation_id {
                if let Some(thread_federation_id) = &thread.federation_id {
                    if federation_id != thread_federation_id {
                        return false;
                    }
                } else {
                    return false;
                }
            }
            
            // Filter by author DID if provided
            if let Some(author_did) = &query.author_did {
                if &thread.author_did != author_did {
                    return false;
                }
            }
            
            // Filter by status if provided
            if let Some(status) = &query.status {
                match status.as_str() {
                    "open" => if thread.status != ThreadStatus::Open { return false; },
                    "closed" => if thread.status != ThreadStatus::Closed { return false; },
                    "archived" => if thread.status != ThreadStatus::Archived { return false; },
                    "hidden" => if thread.status != ThreadStatus::Hidden { return false; },
                    _ => {}
                }
            }
            
            true
        })
        .collect();
    
    // Apply pagination
    let offset = query.offset.unwrap_or(0);
    let limit = query.limit.unwrap_or(20);
    
    if offset < filtered_threads.len() {
        let end = std::cmp::min(offset + limit, filtered_threads.len());
        filtered_threads = filtered_threads[offset..end].to_vec();
    } else {
        filtered_threads.clear();
    }
    
    // Clone the threads for the response
    let threads: Vec<Thread> = filtered_threads.iter().map(|&t| t.clone()).collect();
    
    HttpResponse::Ok().json(threads)
}

/// Get a specific thread by ID
#[get("/threads/{thread_id}")]
pub async fn get_thread(
    db: web::Data<Mutex<Database>>,
    path: web::Path<String>,
) -> impl Responder {
    let thread_id = path.into_inner();
    let db = db.lock().unwrap();
    
    // Find the thread
    match db.threads.iter().find(|t| t.id == thread_id) {
        Some(thread) => HttpResponse::Ok().json(thread),
        None => HttpResponse::NotFound().json(serde_json::json!({
            "error": "Thread not found"
        }))
    }
}

/// Register thread API routes
pub fn configure_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(create_thread)
       .service(get_threads)
       .service(get_thread);
} 