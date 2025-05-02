# AgoraNet

AgoraNet is the deliberation and social layer for the Intercooperative Network (ICN). It provides a backend API for managing proposal-centric discussion threads, linking governance credentials (Verifiable Credentials), and facilitating context-aware communication within the ICN ecosystem.

This backend is built with Rust using the Axum web framework and is designed to integrate seamlessly with the ICN Wallet (mobile/desktop agent) and the ICN Runtime (governance execution).

## 🎯 Core Purpose

* **Deliberation Hub:** Central point for discussing ICN proposals, mandates, and governance events.
* **Contextual Interface:** Links discussion threads directly to on-chain/DAG governance actions.
* **Federation Aware:** Designed to sync and surface relevant discussions across federated ICN instances (future).
* **Credential Linking:** Allows users to associate ICN VCs (e.g., votes, identity proofs) with discussion contributions.

## 🚀 Features (Current Scaffold)

* **Modular Structure:** Separated concerns for routes, types, storage (placeholder), and federation (placeholder).
* **Thread API:** Endpoint to list basic deliberation threads.
* **Credential Linking API:** Endpoints to link and view credential associations with threads.
* **Asynchronous Backend:** Built on Tokio and Axum for performance.

## ↔️ API Endpoints (v0.1)

* `GET /api/threads`
    * Lists active deliberation threads (currently hardcoded placeholders).
    * Response: `Json<Vec<Thread>>`
* `POST /api/threads/credential-link`
    * Links a Verifiable Credential (identified by its CID) to a specific thread.
    * Request Body: `Json<CredentialLinkRequest> { thread_id: String, credential_cid: String, signer_did: String }`
    * Response: `Json<CredentialLink>` (confirming the link)
* `GET /api/threads/credential-links`
    * Lists credentials linked to threads (currently hardcoded placeholders).
    * Response: `Json<Vec<CredentialLink>>`

## 🛠️ Development

### Prerequisites

* Rust (latest stable version recommended)
* Cargo

### Setup

```bash
# Clone the repository (if you haven't already)
# git clone <repository-url>
cd icn-agoranet

# Build the project
cargo build
```

### Running the Server

```bash
cargo run
```

The API server will start and listen on `http://0.0.0.0:3000` (accessible via `http://localhost:3000`).

## 🧩 Integration Points

* **ICN Wallet:** Will consume AgoraNet APIs to display discussion threads, allow users to post replies (future), and link credentials from the wallet.
* **ICN Runtime:** Events or receipts from the runtime (e.g., proposal execution, vote confirmations) can generate credentials that are then linked in AgoraNet threads.
* **Federation Layer (libp2p):** (Future) Will sync thread metadata and potentially messages across participating ICN nodes/federations.

## 🗺️ Next Steps

* Implement persistent storage for threads and links (e.g., using SQLx with PostgreSQL or a K/V store).
* Integrate DID-based authentication for posting messages/links.
* Develop the `federation` module for libp2p integration.
* Flesh out the `types` module with detailed structures for threads, messages, reactions, etc.
* Build the frontend UI (likely within the ICN Wallet context).
