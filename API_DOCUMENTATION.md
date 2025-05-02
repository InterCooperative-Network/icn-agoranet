# AgoraNet API Documentation

AgoraNet is the deliberation layer for the Intercooperative Network (ICN), providing APIs for managing threads, messages, reactions, and credential links.

## Authentication

All endpoints require DID-based authentication using a JWT-like token format.

**Authentication Header Format:**
```
Authorization: Bearer <token>
```

The token is a JWT with the following claims:
- `sub`: DID of the subject (required, must start with `did:icn:`)
- `iss`: DID of the issuer (usually the same as sub for self-signed tokens)
- `exp`: Expiration timestamp
- `iat`: Issued at timestamp
- `jti`: Optional JWT ID
- `nonce`: Optional nonce for preventing replay attacks

## Threads API

Threads are the main containers for deliberation in AgoraNet.

### List Threads

Retrieves a paginated list of deliberation threads.

**Endpoint:** `GET /api/threads`

**Query Parameters:**
- `limit` (optional): Maximum number of threads to return (default: 50, max: 100)
- `offset` (optional): Number of threads to skip (default: 0)  
- `search` (optional): Search term to filter threads by title
- `order_by` (optional): Sort order, one of: created_at_desc, created_at_asc, updated_at_desc, updated_at_asc

**Response:** 200 OK
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Thread Title",
    "proposal_cid": "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy",
    "created_at": "2023-05-20T12:34:56Z",
    "updated_at": "2023-05-20T12:34:56Z",
    "message_count": 5
  }
]
```

### Get Thread

Retrieves a specific thread by ID.

**Endpoint:** `GET /api/threads/:id`

**Path Parameters:**
- `id`: UUID of the thread

**Response:** 200 OK
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Thread Title",
  "proposal_cid": "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy",
  "created_at": "2023-05-20T12:34:56Z",
  "updated_at": "2023-05-20T12:34:56Z",
  "message_count": 5
}
```

### Create Thread

Creates a new deliberation thread.

**Endpoint:** `POST /api/threads`

**Request Body:**
```json
{
  "title": "New Thread Title",
  "proposal_cid": "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy"
}
```

**Response:** 201 Created
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "New Thread Title",
  "proposal_cid": "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy",
  "created_at": "2023-05-20T12:34:56Z",
  "updated_at": "2023-05-20T12:34:56Z"
}
```

## Messages API

Messages are the content posted in deliberation threads.

### List Messages

Lists messages in a specific thread with pagination.

**Endpoint:** `GET /api/threads/:thread_id/messages`

**Path Parameters:**
- `thread_id`: UUID of the thread

**Query Parameters:**
- `limit` (optional): Maximum number of messages to return (default: 50, max: 100)
- `offset` (optional): Number of messages to skip (default: 0)

**Response:** 200 OK
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "thread_id": "550e8400-e29b-41d4-a716-446655440000",
    "author_did": "did:icn:author",
    "content": "Message content",
    "reply_to": null,
    "is_system": false,
    "created_at": "2023-05-20T12:34:56Z",
    "reactions": [
      {
        "reaction_type": "👍",
        "count": 3
      }
    ]
  }
]
```

### Get Message

Retrieves a specific message.

**Endpoint:** `GET /api/threads/:thread_id/messages/:message_id`

**Path Parameters:**
- `thread_id`: UUID of the thread
- `message_id`: UUID of the message

**Response:** 200 OK
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "thread_id": "550e8400-e29b-41d4-a716-446655440000",
  "author_did": "did:icn:author",
  "content": "Message content",
  "reply_to": null,
  "is_system": false,
  "created_at": "2023-05-20T12:34:56Z",
  "reactions": [
    {
      "reaction_type": "👍",
      "count": 3
    }
  ]
}
```

### Create Message

Creates a new message in a thread.

**Endpoint:** `POST /api/threads/:thread_id/messages`

**Path Parameters:**
- `thread_id`: UUID of the thread

**Request Body:**
```json
{
  "content": "New message content",
  "reply_to": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response:** 201 Created
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "thread_id": "550e8400-e29b-41d4-a716-446655440000",
  "author_did": "did:icn:author",
  "content": "New message content",
  "reply_to": "550e8400-e29b-41d4-a716-446655440000",
  "is_system": false,
  "created_at": "2023-05-20T12:34:56Z"
}
```

### Delete Message

Deletes a message. Only the author or a moderator can delete messages.

**Endpoint:** `DELETE /api/threads/:thread_id/messages/:message_id`

**Path Parameters:**
- `thread_id`: UUID of the thread
- `message_id`: UUID of the message

**Response:** 204 No Content

## Reactions API

Reactions are emoji-based responses to messages.

### List Reactions

Lists all reactions for a message.

**Endpoint:** `GET /api/messages/:message_id/reactions`

**Path Parameters:**
- `message_id`: UUID of the message

**Response:** 200 OK
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "message_id": "550e8400-e29b-41d4-a716-446655440000",
    "author_did": "did:icn:author",
    "reaction_type": "👍",
    "created_at": "2023-05-20T12:34:56Z"
  }
]
```

### Add Reaction

Adds a reaction to a message.

**Endpoint:** `POST /api/messages/:message_id/reactions`

**Path Parameters:**
- `message_id`: UUID of the message

**Request Body:**
```json
{
  "reaction_type": "👍"
}
```

**Response:** 201 Created
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "message_id": "550e8400-e29b-41d4-a716-446655440000",
  "author_did": "did:icn:author",
  "reaction_type": "👍",
  "created_at": "2023-05-20T12:34:56Z"
}
```

### Remove Reaction

Removes a user's reaction from a message.

**Endpoint:** `DELETE /api/messages/:message_id/reactions/:reaction_type`

**Path Parameters:**
- `message_id`: UUID of the message
- `reaction_type`: Type of reaction to remove (e.g., "👍")

**Response:** 204 No Content

## Credential Links API

Credential links associate verifiable credentials with deliberation threads.

### List Credential Links

Lists all credential links for a thread.

**Endpoint:** `GET /api/threads/:thread_id/credential-links`

**Path Parameters:**
- `thread_id`: UUID of the thread

**Response:** 200 OK
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "thread_id": "550e8400-e29b-41d4-a716-446655440000",
    "credential_cid": "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy",
    "linked_by": "did:icn:user",
    "timestamp": 1684586096
  }
]
```

### Link Credential

Links a credential to a thread.

**Endpoint:** `POST /api/threads/:thread_id/credential-links`

**Path Parameters:**
- `thread_id`: UUID of the thread

**Request Body:**
```json
{
  "credential_cid": "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy"
}
```

**Response:** 201 Created
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "thread_id": "550e8400-e29b-41d4-a716-446655440000",
  "credential_cid": "bafybeihgzxz6mzfcw7hyb3zhb2du64mlazovyiulxhrbj3eg7mnhyy",
  "linked_by": "did:icn:user",
  "timestamp": 1684586096
}
```

## Error Responses

The API uses standard HTTP status codes for error responses:

- `400 Bad Request`: Invalid input or parameters
- `401 Unauthorized`: Missing or invalid authentication token
- `403 Forbidden`: Insufficient permissions for the operation
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource conflict (e.g., duplicate reaction)
- `500 Internal Server Error`: Server error

Error responses have the following format:
```json
{
  "error": "Error message describing the issue"
}
```

## Pagination

Endpoints that return lists support pagination through `limit` and `offset` query parameters:

- `limit`: Maximum number of items to return (default varies by endpoint)
- `offset`: Number of items to skip

## Authentication and Authorization

Authentication is required for all API endpoints and is performed using DID-based JWT tokens.

Authorization is role-based, with the following permissions:
- `ReadThread`: Allows reading threads and messages (all authenticated users)
- `CreateThread`: Allows creating new threads (all authenticated users)
- `PostMessage`: Allows posting messages in threads (all authenticated users)
- `ReactToMessage`: Allows adding reactions to messages (all authenticated users)
- `LinkCredential`: Allows linking credentials to threads (credential owners or moderators)
- `ModerateContent`: Allows moderation actions like deleting messages (moderators only)

## Federation

When federation is enabled, thread and message operations are propagated to other nodes in the network. This enables a federated deliberation layer where multiple nodes can participate in the same discussions. 