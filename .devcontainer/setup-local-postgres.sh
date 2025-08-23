#!/usr/bin/env bash
set -euo pipefail

echo "Setting up local PostgreSQL for ElizaOS..."

# Check if PostgreSQL is running
if ! netstat -tlnp | grep -q ":5432.*LISTEN"; then
    echo "❌ PostgreSQL is not running on port 5432"
    echo "Please ensure PostgreSQL is started"
    exit 1
fi

echo "PostgreSQL is running on port 5432"

# Try to create eliza user using different methods
echo "Attempting to create eliza user..."

# Method 1: Try using postgres user with trust authentication
if psql -h localhost -U postgres -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ Connected as postgres user"
    
    # Create eliza user
    if psql -h localhost -U postgres -c "SELECT 1 FROM pg_roles WHERE rolname='eliza';" | grep -q 1; then
        echo "eliza user already exists"
    else
        echo "Creating eliza user..."
        psql -h localhost -U postgres -c "CREATE USER eliza WITH SUPERUSER PASSWORD 'eliza_secure_pass';"
    fi
    
    # Create eliza database
    if psql -h localhost -U postgres -lqt | cut -d \| -f 1 | grep -qw eliza; then
        echo "eliza database already exists"
    else
        echo "Creating eliza database..."
        psql -h localhost -U postgres -c "CREATE DATABASE eliza OWNER eliza;"
    fi
    
    echo "✅ PostgreSQL setup complete"
    exit 0
fi

# Method 2: Try using current user
echo "Trying to connect as current user..."
if psql -h localhost -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ Connected as current user"
    
    # Create eliza user
    if psql -h localhost -c "SELECT 1 FROM pg_roles WHERE rolname='eliza';" | grep -q 1; then
        echo "eliza user already exists"
    else
        echo "Creating eliza user..."
        psql -h localhost -c "CREATE USER eliza WITH SUPERUSER PASSWORD 'eliza_secure_pass';"
    fi
    
    # Create eliza database
    if psql -h localhost -lqt | cut -d \| -f 1 | grep -qw eliza; then
        echo "eliza database already exists"
    else
        echo "Creating eliza database..."
        psql -h localhost -c "CREATE DATABASE eliza OWNER eliza;"
    fi
    
    echo "✅ PostgreSQL setup complete"
    exit 0
fi

echo "❌ Could not connect to PostgreSQL with any method"
echo "Please check PostgreSQL configuration and ensure it allows local connections"
exit 1
