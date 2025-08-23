#!/usr/bin/env bash
set -euo pipefail

echo "Setting up PostgreSQL for ElizaOS (simple version)..."

# Check if PostgreSQL is running
if ! sudo service postgresql status >/dev/null 2>&1; then
    echo "Starting PostgreSQL..."
    sudo service postgresql start
fi

# Try to create eliza user using postgres user
echo "Attempting to create eliza user and database..."

# Method 1: Try using postgres user directly
if command -v psql >/dev/null 2>&1; then
    echo "Trying to connect as postgres user..."
    
    # Try to create user and database
    if sudo -u postgres psql -c "CREATE USER eliza WITH SUPERUSER PASSWORD 'eliza_secure_pass';" 2>/dev/null; then
        echo "✅ Created eliza user"
    else
        echo "⚠️  Could not create eliza user (might already exist)"
    fi
    
    if sudo -u postgres createdb -O eliza eliza 2>/dev/null; then
        echo "✅ Created eliza database"
    else
        echo "⚠️  Could not create eliza database (might already exist)"
    fi
else
    echo "❌ psql not found"
    exit 1
fi

# Test connection
echo "Testing PostgreSQL connection..."
if PGPASSWORD=eliza_secure_pass psql -h localhost -U eliza -d eliza -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ PostgreSQL setup successful!"
    echo "Connection string: postgresql://eliza:eliza_secure_pass@localhost:5432/eliza"
    exit 0
else
    echo "❌ PostgreSQL connection test failed"
    echo "Trying alternative setup..."
    
    # Alternative: Try to use postgres user directly
    if psql -U postgres -h localhost -c "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ Can connect as postgres user"
        echo "You may need to manually create the eliza user and database"
        echo "Run: sudo -u postgres psql -c \"CREATE USER eliza WITH SUPERUSER PASSWORD 'eliza_secure_pass';\""
        echo "Run: sudo -u postgres createdb -O eliza eliza"
    else
        echo "❌ Cannot connect to PostgreSQL"
        exit 1
    fi
fi
