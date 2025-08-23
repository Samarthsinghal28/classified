#!/usr/bin/env bash
set -euo pipefail

echo "Installing PostgreSQL 16 and pgvector into the container (interactive; may require sudo)"
if [ "$(id -u)" -ne 0 ]; then
  echo "This script should be run with sudo. Re-running with sudo..."
  exec sudo bash "$0" "$@"
fi

apt-get update
apt-get install -y wget ca-certificates lsb-release gnupg
wget -qO - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
apt-get update
apt-get install -y postgresql-16 postgresql-client-16 postgresql-server-dev-16 build-essential

echo "Installing pgvector"
apt-get install -y postgresql-16-pgvector || (
  # try building from source as fallback
  git clone https://github.com/pgvector/pgvector.git /tmp/pgvector && \
  cd /tmp/pgvector && make && make install
)

echo "Finished. Start Postgres with: sudo service postgresql start"
