use actix_web::{web, App, HttpServer, middleware};
use actix_cors::Cors;
use serde::{Serialize, Deserialize};
use std::sync::Mutex;
use std::collections::HashMap;

mod api;
mod models;
mod database;

use crate::database::Database;
use crate::api::{credential_linking, thread};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize logger
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    
    // Create database instance
    let db = web::Data::new(Mutex::new(Database::new()));
    
    log::info!("Starting AgoraNet server on http://127.0.0.1:8080");
    
    // Start HTTP server
    HttpServer::new(move || {
        // Configure CORS
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);
        
        App::new()
            .app_data(db.clone())
            .wrap(middleware::Logger::default())
            .wrap(cors)
            .service(
                web::scope("/api")
                    .configure(credential_linking::configure_routes)
                    .configure(thread::configure_routes)
            )
            .route("/", web::get().to(|| async { "AgoraNet API Server" }))
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
} 