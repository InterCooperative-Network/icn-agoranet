# AgoraNet

The deliberation layer for the Intercooperative Network (ICN). AgoraNet is a device-aware web interface that synchronizes federated proposal discussions, guardian votes, identity recovery, and anchored decisions to a DAG (Directed Acyclic Graph).

## Features

- Federated deliberation threads
- Verifiable Credential linking
- DAG anchoring support
- DID-authenticated messaging
- Mobile-first design for ICN Wallet UI integration

## API Endpoints

- `/api/threads` - List all deliberation threads
- `/api/threads/credential-link` - Link a Verifiable Credential to a thread
- `/api/threads/credential-links` - List credential links for threads

## Development

### Prerequisites

- Rust 2021 edition or later
- PostgreSQL database

### Setup

1. Clone the repository
2. Install dependencies:

```bash
cargo build
```

3. Run the development server:

```bash
cargo run
```

The API will be available at `http://localhost:8080`.

## Architecture

AgoraNet is built using:

- Axum - Rust web framework
- SQLx - SQL toolkit for Rust
- libp2p - P2P networking for federation
- CID & Multihash - Content-addressable storage

## License

Copyright (c) 2023 Intercooperative Network
