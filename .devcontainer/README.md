# DevContainer Automation

This devcontainer is configured to automatically start the PostgreSQL database and ElizaOS services when a Codespace or devcontainer starts.

## What happens automatically:

1. **Database Setup**: Tries to start PostgreSQL via docker-compose. If Docker isn't available (common in Codespaces), it detects if PostgreSQL is already installed and running.

2. **Environment Configuration**: Creates `packages/agentserver/.env` with PostgreSQL connection settings if it doesn't exist.

3. **Service Startup**: 
   - Starts the AgentServer backend on port 7777 using `bun run dev:external-db` (bypasses internal PostgreSQL setup)
   - Starts the Game frontend on port 5173 using `bun vite dev`

4. **Logs**: Service logs are written to `/tmp/agentserver.log` and `/tmp/game-frontend.log`

## Port Forwarding

The devcontainer automatically forwards these ports:
- 5432: PostgreSQL Database
- 7777: AgentServer API  
- 5173: Game Frontend
- 2222: SSH Server

## Manual Commands

If you need to restart services manually:

```bash
# Stop current services
pkill -f "bun.*dev"

# Restart automation
.devcontainer/prepare-and-start.sh

# Or start services individually
cd packages/agentserver && bun run dev:external-db
cd packages/game && bun vite dev --host 0.0.0.0

# Check logs
tail -f /tmp/agentserver.log /tmp/game-frontend.log
```

## Troubleshooting

- **PostgreSQL not available**: The script will attempt to use existing PostgreSQL installation if available
- **Services not starting**: Check logs in `/tmp/agentserver.log` and `/tmp/game-frontend.log`  
- **Port conflicts**: Ensure ports 5432, 7777, and 5173 are not in use by other processes

## New Script Command

The automation uses `bun run dev:external-db` which bypasses the internal PostgreSQL setup script and directly runs the AgentServer assuming PostgreSQL is available externally.
