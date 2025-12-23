# Build stage
FROM rust:latest as builder

WORKDIR /app

# Install dependencies for PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy manifest files
COPY Cargo.toml ./

# Copy source code
COPY src ./src
COPY migrations ./migrations

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/target/release/kisse-backend /app/kisse-backend

# Copy migrations (ensure they're in the right place)
COPY --from=builder /app/migrations ./migrations

# Verify migrations are present
RUN ls -la ./migrations/ || echo "WARNING: migrations directory not found"

EXPOSE 8080

# Use exec form to ensure proper signal handling
CMD ["./kisse-backend"]

