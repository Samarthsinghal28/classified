#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace"
AGENT_DIR="$ROOT/packages/agentserver"
GAME_DIR="$ROOT/packages/game"
DEVCONTAINER_DIR="$ROOT/.devcontainer"

echo "Preparing devcontainer automation..."

setup_postgres_user_and_db() {
  echo "Setting up PostgreSQL user and database..."
  
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
  
  echo "✅ PostgreSQL setup complete"
}

install_postgres_direct() {
  echo "Setting up PostgreSQL in container..."
  
  # Check if postgresql is already installed
  if command -v psql >/dev/null 2>&1; then
    echo "PostgreSQL is already installed, checking if it's running"
    if sudo service postgresql status >/dev/null 2>&1; then
      echo "PostgreSQL is already running"
    else
      echo "Starting existing PostgreSQL installation"
      sudo service postgresql start
    fi
  else
    # Install PostgreSQL from scratch
    echo "PostgreSQL not found, installing..."
    sudo apt update
    sudo apt install -y postgresql-16 postgresql-contrib-16
    sudo service postgresql start
  fi
  
  # Configure PostgreSQL to allow local connections
  echo "Configuring PostgreSQL authentication..."
  sudo sed -i "s/local   all             all                                     peer/local   all             all                                     trust/" /etc/postgresql/16/main/pg_hba.conf
  sudo sed -i "s/#local   all             postgres                                peer/local   all             postgres                                trust/" /etc/postgresql/16/main/pg_hba.conf
  sudo service postgresql restart
  
  # Setup user and database
  if setup_postgres_user_and_db; then
    echo "PostgreSQL is properly configured with eliza user and database"
    return 0
  else
    echo "Failed to configure PostgreSQL"
    return 1
  fi
}

wait_for_port() {
  host="$1"; port="$2"; retries=30
  for i in $(seq 1 $retries); do
    if timeout 1 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
      return 0
    fi
    sleep 1
  done
  return 1
}

start_db_compose() {
  echo "Attempting to start DB via docker-compose..."
  if command -v docker >/dev/null 2>&1 || command -v podman >/dev/null 2>&1; then
    (cd "$ROOT/.devcontainer" && docker compose up -d db) && return 0 || return 1
  fi
  return 1
}

ensure_env() {
  envfile="$AGENT_DIR/.env"
  if [ ! -f "$envfile" ]; then
    echo "Creating default .env for agentserver"
    cat > "$envfile" <<EOF
USE_POSTGRESQL=true
DISABLE_PGLITE=true
DATABASE_URL=postgresql://eliza:eliza_secure_pass@localhost:5432/eliza
POSTGRES_URL=postgresql://eliza:eliza_secure_pass@localhost:5432/eliza
PORT=7777
NODE_ENV=development
EOF
  else
    echo ".env already exists, updating to use PostgreSQL..."
    sed -i 's/USE_POSTGRESQL=false/USE_POSTGRESQL=true/' "$envfile"
    sed -i 's/DISABLE_PGLITE=false/DISABLE_PGLITE=true/' "$envfile"
  fi
}

start_services() {
  echo "Starting agentserver and web frontend in background"
  
  # Check if Postgres is available before starting agentserver
  if wait_for_port localhost 5432; then
    echo "Postgres is available, starting agentserver with external DB"
    # Use dev:external-db to skip postgres:start step since we handle DB ourselves
    (cd "$AGENT_DIR" && setsid bun run dev:external-db >/tmp/agentserver.log 2>&1 &)
  else
    echo "Postgres not available, attempting to start agentserver with internal postgres setup"
    # Try regular dev command which includes postgres:start 
    (cd "$AGENT_DIR" && setsid bun run dev >/tmp/agentserver.log 2>&1 &)
  fi
  
  # Start Vite frontend
  (cd "$GAME_DIR" && setsid bun vite dev --host 0.0.0.0 >/tmp/game-frontend.log 2>&1 &)
  echo "Started services; logs: /tmp/agentserver.log and /tmp/game-frontend.log"
}

main() {
  echo "Running devcontainer start automation"
  ensure_env

  if start_db_compose; then
    echo "docker-compose started DB. Waiting for Postgres..."
    if wait_for_port localhost 5432; then
      echo "Postgres is available"
    else
      echo "Postgres did not become available in time"
    fi
  else
    echo "docker/podman not available or failed."
    
    # Check if postgres is already running
    if wait_for_port localhost 5432; then
      echo "Postgres is already available on localhost:5432"
      # Still need to setup user and database
      if setup_postgres_user_and_db; then
        echo "PostgreSQL user and database configured"
      else
        echo "Failed to configure PostgreSQL user and database"
        return 1
      fi
    else
      echo "Installing PostgreSQL directly in container..."
      if install_postgres_direct; then
        # Wait for it to be ready
        if wait_for_port localhost 5432; then
          echo "Postgres is now available"
        else
          echo "Failed to start PostgreSQL"
          return 1
        fi
      else
        echo "Failed to setup PostgreSQL"
        return 1
      fi
    fi
  fi

  start_services
  echo "Devcontainer automation complete. Backend: http://localhost:7777, Frontend: http://localhost:5173"
  echo "Check logs with: tail -f /tmp/agentserver.log /tmp/game-frontend.log"
}

main "$@"
