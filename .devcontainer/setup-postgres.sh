#!/usr/bin/env bash
set -euo pipefail

echo "Setting up PostgreSQL for ElizaOS (devcontainer version)..."

# Check if we're in a devcontainer environment
if [ -f /.dockerenv ] || [ "$DOCKER_CONTAINER" = "true" ]; then
    echo "Running in devcontainer environment"
    
    # Wait for PostgreSQL service to be ready
    echo "Waiting for PostgreSQL service to be ready..."
    until pg_isready -h postgres -p 5432 -U eliza; do
        echo "PostgreSQL is not ready yet, waiting..."
        sleep 2
    done
    
    # Check if eliza database exists
    if ! psql -h postgres -U eliza -d eliza -c "SELECT 1;" >/dev/null 2>&1; then
        echo "Creating eliza database..."
        psql -h postgres -U eliza -d postgres -c "CREATE DATABASE eliza;"
    else
        echo "eliza database already exists"
    fi
    
    echo "✅ PostgreSQL setup complete for devcontainer"
else
    echo "Not in devcontainer environment, please use the devcontainer setup"
    exit 1
fi
