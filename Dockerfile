# Build stage
FROM rust:1.76 AS builder

WORKDIR /app

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Create dummy source to build dependencies
RUN mkdir -p src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copy actual source code
COPY src/ src/
COPY migrations/ migrations/

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the binary and other necessary files
COPY --from=builder /app/target/release/icn-agoranet /app/icn-agoranet
COPY --from=builder /app/migrations /app/migrations

# Set runtime environment variables
ENV RUST_LOG="info"

# Expose the API port
EXPOSE 3001

# Run the binary
CMD ["/app/icn-agoranet"] 