use axum::Router;
use std::net::SocketAddr;
use tracing_subscriber::{FmtSubscriber, EnvFilter};
use dotenvy::dotenv;
use std::error::Error;

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
    
    tracing::info!("Starting AgoraNet API...");

    // Create the Axum application with routes, passing the DB pool
    let app = Router::new()
        .merge(routes::threads::routes())
        .merge(routes::credentials::routes())
        .with_state(pool);

    // Bind to the configured address and start the server
    let addr = SocketAddr::from(([0, 0, 0, 0], 3001));
    tracing::info!("Listening on http://{}", addr);
    
    axum_server::bind(addr)
        .serve(app.into_make_service())
        .await?;
        
    tracing::info!("Server shutdown gracefully");
    Ok(())
} 