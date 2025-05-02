use axum::Router;
use std::net::SocketAddr;
use tracing_subscriber::FmtSubscriber;

mod routes;
mod types;
mod storage;
mod federation;

#[tokio::main]
async fn main() {
    FmtSubscriber::builder().init();

    let app = Router::new()
        .merge(routes::threads::routes())
        .merge(routes::credentials::routes());

    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    tracing::info!("Starting AgoraNet API on http://{}", addr);
    
    axum_server::bind(addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
} 