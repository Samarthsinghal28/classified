#!/usr/bin/env bash
set -euo pipefail

echo "Starting ElizaOS Agent Server..."

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "src" ]; then
    echo "❌ Please run this script from the agentserver directory"
    exit 1
fi

# Check if PostgreSQL is ready
echo "Checking PostgreSQL connection..."
if ! pg_isready -h postgres -p 5432 -U eliza; then
    echo "❌ PostgreSQL is not ready. Please ensure the devcontainer is running properly."
    exit 1
fi

# Check if eliza database exists
if ! psql -h postgres -U eliza -d eliza -c "SELECT 1;" >/dev/null 2>&1; then
    echo "Creating eliza database..."
    psql -h postgres -U eliza -d postgres -c "CREATE DATABASE eliza;"
fi

# Start the agentserver
echo "✅ Starting agentserver..."
bun run dev
