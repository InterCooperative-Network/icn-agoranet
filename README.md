# AgoraNet - ICN Deliberation Layer

AgoraNet is the deliberation layer for the Intercooperative Network (ICN), providing APIs for managing discussion threads, messages, reactions, and credential links. AgoraNet serves as the backend for ICN Wallet's deliberation features.

## Features

- **Thread Management**: Create, retrieve, and list deliberation threads
- **Messaging**: Post messages, replies, and react to messages in threads
- **Credential Integration**: Link verifiable credentials to threads for context and authorization
- **Federation**: Synchronize content across multiple nodes in a permissioned network
- **Runtime Integration**: Automatically create threads for proposals from the ICN Runtime
- **DID Authentication**: Secure access with DID-based JWT authentication

## Getting Started

### Prerequisites

- Rust (1.70+)
- PostgreSQL (15+)
- Docker & Docker Compose (for containerized deployment)

### Installation

1. Clone the repository:
```sh
git clone https://github.com/intercooperative-network/agoranet.git
cd agoranet
```

2. Set up the database:
```sh
# Create PostgreSQL database
createdb agoranet

# Run migrations
cargo install sqlx-cli --no-default-features --features rustls,postgres
DATABASE_URL=postgres://username:password@localhost/agoranet sqlx migrate run
```

3. Configure environment variables (create a `.env` file):
```
DATABASE_URL=postgres://username:password@localhost/agoranet
PORT=3001
RUST_LOG=info
ENABLE_FEDERATION=false
ENABLE_RUNTIME_CLIENT=false
```

4. Build and run:
```sh
cargo build --release
./target/release/agoranet
```

### Docker Deployment

1. Build and run using Docker Compose:
```sh
docker-compose up -d
```

2. For production deployment, use the provided Docker Compose file with environment-specific settings:
```sh
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Configuration

AgoraNet can be configured using environment variables:

### Core Settings
- `DATABASE_URL`: PostgreSQL connection string
- `PORT`: API server port (default: 3001)
- `RUST_LOG`: Logging level (error, warn, info, debug, trace)
- `DB_MAX_CONNECTIONS`: Maximum database connections (default: 20)
- `RUN_MIGRATIONS`: Whether to run migrations on startup (default: true)

### Federation Settings
- `ENABLE_FEDERATION`: Enable federation support (default: false)
- `FEDERATION_BOOTSTRAP_PEERS`: Comma-separated list of peers to connect to
- `FEDERATION_LISTEN_ADDR`: libp2p listening address (default: /ip4/0.0.0.0/tcp/4001)
- `FEDERATION_MAX_CONNECTIONS`: Maximum peer connections (default: 50)

### Runtime Client Settings
- `ENABLE_RUNTIME_CLIENT`: Enable Runtime integration (default: false)
- `RUNTIME_API_URL`: URL of the Runtime API (default: http://localhost:3000)
- `RUNTIME_POLL_INTERVAL`: Poll interval in milliseconds (default: 5000)

## API Documentation

AgoraNet provides a comprehensive RESTful API for thread and message management:

- **API Documentation**: Available at `/swagger-ui/` when the server is running
- **API Endpoints**: See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for details

## Development

### Running Tests

Run the test suite:
```sh
cargo test
```

Run integration tests:
```sh
./scripts/integration_test.sh
```

Perform load testing (requires k6):
```sh
k6 run scripts/load_test.js
```

### Database Migrations

Create a new migration:
```sh
sqlx migrate add <migration_name>
```

Run migrations:
```sh
sqlx migrate run
```

Revert the latest migration:
```sh
sqlx migrate revert
```

## Architecture

AgoraNet consists of the following components:

- **API Server**: Axum-based HTTP server exposing the REST API
- **Storage Layer**: PostgreSQL-backed storage for threads, messages, and metadata
- **Federation Module**: libp2p implementation for peer-to-peer synchronization
- **Runtime Client**: Integration with ICN Runtime for proposal tracking
- **Authentication**: DID-based JWT authentication and authorization system

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

AgoraNet is developed as part of the Intercooperative Network (ICN) initiative.
