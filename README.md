# AgoraNet

AgoraNet is the deliberation platform for the Intercooperative Network (ICN), providing proposal discussion, credential linking, and governance deliberation.

## Features

- Proposal-centric discussion threads
- Credential linking (connecting governance credentials to discussion threads)
- Federation-aware proposal visibility
- Integration with the ICN runtime and wallet

## Credential Linking

AgoraNet includes a powerful feature for linking Verifiable Credentials from the ICN wallet to proposal discussion threads. This allows:

1. Users to prove their participation in governance
2. Threads to show governance actions (votes, finalizations, etc.)
3. Governance credentials to reference associated discussion

### API Endpoints

- `POST /api/threads/credential-link` - Link a credential to a thread
- `GET /api/threads/credential-links` - List all credentials linked to a thread

## Development

### Prerequisites

- Rust 1.70+
- Cargo

### Setup

```bash
git clone https://github.com/intercooperative/icn-agoranet.git
cd icn-agoranet
cargo build
```

### Running

```bash
cargo run
```

The API server will start on http://localhost:8080

## Integration

AgoraNet integrates with the ICN ecosystem:

- **ICN Wallet**: Links credentials to AgoraNet threads
- **ICN Runtime**: Provides receipts and proposal info
- **ICN Dev Node**: Helps with federation onboarding
