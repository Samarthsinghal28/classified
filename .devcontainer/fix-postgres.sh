#!/usr/bin/env bash
set -euo pipefail

echo "Fixing PostgreSQL authentication for ElizaOS..."

# Check if PostgreSQL is running
if ! sudo service postgresql status >/dev/null 2>&1; then
    echo "Starting PostgreSQL..."
    sudo service postgresql start
fi

# Fix authentication to allow local connections without password
echo "Fixing PostgreSQL authentication..."
sudo sed -i "s/local   all             all                                     peer/local   all             all                                     trust/" /etc/postgresql/16/main/pg_hba.conf
sudo sed -i "s/#local   all             postgres                                peer/local   all             postgres                                trust/" /etc/postgresql/16/main/pg_hba.conf

# Restart PostgreSQL
echo "Restarting PostgreSQL..."
sudo service postgresql restart

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 3

# Now try to create the user and database
echo "Creating eliza user and database..."

# Create eliza user
sudo -u postgres psql -c "CREATE USER eliza WITH SUPERUSER PASSWORD 'eliza_secure_pass';" 2>/dev/null || echo "User eliza might already exist"

# Create eliza database
sudo -u postgres createdb -O eliza eliza 2>/dev/null || echo "Database eliza might already exist"

# Test connection
echo "Testing connection..."
if PGPASSWORD=eliza_secure_pass psql -h localhost -U eliza -d eliza -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ PostgreSQL setup successful!"
    echo "Connection string: postgresql://eliza:eliza_secure_pass@localhost:5432/eliza"
else
    echo "❌ Connection test failed"
    echo "Manual setup required:"
    echo "1. Run: sudo -u postgres psql"
    echo "2. In psql: CREATE USER eliza WITH SUPERUSER PASSWORD 'eliza_secure_pass';"
    echo "3. In psql: CREATE DATABASE eliza OWNER eliza;"
    echo "4. Exit psql: \\q"
fi
