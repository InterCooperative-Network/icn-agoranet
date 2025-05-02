# AgoraNet - ICN Deliberation Layer

AgoraNet serves as the deliberation layer for the Intercooperative Network (ICN), providing a social context for governance actions. It's built with Rust using the Axum web framework and interfaces with the ICN Runtime and Wallet.

## Features

- **Thread Management**: Create and list deliberation threads for proposals
- **Credential Linking**: Associate Verifiable Credentials with deliberation threads
- **DID Authentication**: Secure API access using DID-based authentication
- **Federation**: Synchronize data across federated AgoraNet instances using libp2p
- **Runtime Integration**: Consume events from the ICN Runtime to create threads and update their status

## API Endpoints

### Threads

- `GET /api/threads` - List all threads
- `GET /api/threads/:id` - Get a specific thread by ID
- `POST /api/threads` - Create a new thread (requires authentication)

### Credential Links

- `GET /api/threads/credential-links` - List all credential links
- `GET /api/threads/:id/credential-links` - List credential links for a specific thread
- `POST /api/threads/credential-link` - Create a new credential link (requires authentication)

## Running AgoraNet

### Prerequisites

- Rust 1.76+
- PostgreSQL database
- Docker and Docker Compose (optional)

### Environment Variables

AgoraNet uses the following environment variables:

- `DATABASE_URL` - PostgreSQL connection string
- `PORT` - API server port (default: 3001)
- `RUST_LOG` - Logging level configuration
- `RUN_MIGRATIONS` - Whether to run migrations on startup (default: true)
- `ENABLE_FEDERATION` - Enable federation mode (default: false)
- `ENABLE_RUNTIME_CLIENT` - Enable Runtime client (default: false)
- `RUNTIME_API_ENDPOINT` - ICN Runtime API endpoint

### Running with Docker Compose

1. Clone the repository:
   ```
   git clone https://github.com/your-org/icn-agoranet.git
   cd icn-agoranet
   ```

2. Run using Docker Compose:
   ```
   docker-compose up -d
   ```

This will start PostgreSQL and AgoraNet services.

### Running Locally

1. Install dependencies:
   ```
   cargo build
   ```

2. Set up a PostgreSQL database and set the DATABASE_URL environment variable:
   ```
   export DATABASE_URL=postgres://agoranet:agoranet_password@localhost:5432/agoranet
   ```

3. Run the application:
   ```
   cargo run
   ```

## Development

### Running Tests

```
cargo test
```

### Database Migrations

Migrations are managed with SQLx and will run automatically on startup if `RUN_MIGRATIONS=true`.

## Federation

AgoraNet supports federation across multiple instances using libp2p. When federation is enabled:

1. Thread creations are announced to other nodes
2. Credential links are synchronized across the network
3. Peers discover each other using a DHT

## Integration with ICN Components

- **ICN Runtime**: AgoraNet listens for events from the Runtime to create threads for proposals
- **ICN Wallet**: The Wallet consumes AgoraNet's API to display threads and credential links

## DID Authentication

API endpoints that modify data require DID-based authentication using the following format:

```
Authorization: Bearer <token>
```

The token is expected to be a DID-signed JWT that includes the DID identifier.

## License

[MIT License](LICENSE)
