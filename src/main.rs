use axum::Router;
use std::net::SocketAddr;
use tracing_subscriber::{FmtSubscriber, EnvFilter};
use dotenvy::dotenv;
use std::error::Error;
use std::sync::Arc;

mod routes;
mod types;
mod storage;
mod federation;

#[tokio::main]
async fn main() {
    // Load environment variables from .env file
    dotenv().ok();
    
    // Initialize logging with environment-based filters
    FmtSubscriber::builder()
        .with_env_filter(EnvFilter::from_default_env())
        .init();
        
    if let Err(e) = run().await {
        tracing::error!("Application error: {}", e);
        std::process::exit(1);
    }
}

async fn run() -> Result<(), Box<dyn Error>> {
    // Display the database URL (with password redacted)
    let db_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let display_url = if db_url.contains('@') {
        // Simple redaction - not foolproof but good enough for logs
        let parts: Vec<&str> = db_url.splitn(2, '@').collect();
        let auth_parts: Vec<&str> = parts[0].splitn(2, ':').collect();
        format!("{}:****@{}", auth_parts[0], parts[1])
    } else {
        "[redacted]".to_string()
    };
    tracing::info!("Using database connection: {}", display_url);

    // Create database connection pool
    tracing::info!("Creating database pool...");
    let pool = storage::create_db_pool().await?;
    tracing::info!("Database connection pool created successfully");
    
    // Initialize federation (if enabled)
    let federation_enabled = std::env::var("ENABLE_FEDERATION")
        .unwrap_or_else(|_| "false".to_string())
        .parse::<bool>()
        .unwrap_or(false);
    
    let federation = if federation_enabled {
        tracing::info!("Initializing federation module...");
        let fed = federation::Federation::new(pool.clone()).await?;
        
        // Start the federation
        fed.start().await?;
        tracing::info!("Federation module started");
        
        Some(Arc::new(fed))
    } else {
        tracing::info!("Federation module disabled");
        None
    };
    
    tracing::info!("Starting AgoraNet API...");

    // Create the Axum application with routes, passing the DB pool
    let app = Router::new()
        .merge(routes::threads::routes())
        .merge(routes::credentials::routes())
        .with_state(pool);

    // Bind to the configured address and start the server
    let port = std::env::var("PORT").unwrap_or_else(|_| "3001".to_string())
        .parse::<u16>().unwrap_or(3001);
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    tracing::info!("Listening on http://{}", addr);
    
    axum_server::bind(addr)
        .serve(app.into_make_service())
        .await?;
        
    // Shutdown the federation if it was started
    if let Some(fed) = federation {
        tracing::info!("Stopping federation module...");
        fed.stop().await?;
        tracing::info!("Federation module stopped");
    }
    
    tracing::info!("Server shutdown gracefully");
    Ok(())
} 