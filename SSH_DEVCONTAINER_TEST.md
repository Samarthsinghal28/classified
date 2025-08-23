# SSH-Preserving Devcontainer Test

This directory contains a minimal devcontainer configuration designed to test whether we can preserve SSH access while using devcontainers.

## Problem Statement

Previous attempts to create devcontainer configurations for ElizaOS have resulted in loss of SSH access to the Codespace. This makes development difficult since you prefer SSH access for your workflow.

## Test Strategy

1. **Minimal First**: Start with the most minimal devcontainer possible
2. **SSH Preservation**: Focus on maintaining SSH access above all else
3. **Incremental Addition**: Only add dependencies after confirming SSH works
4. **Quick Validation**: Use test script to quickly verify functionality

## Current Test Configuration

The `.devcontainer/devcontainer.json` file contains:

- **Base Image**: `mcr.microsoft.com/devcontainers/base:ubuntu` (same as Codespaces default)
- **User Preservation**: Explicitly sets `remoteUser` and `containerUser` to `codespace`
- **UID Preservation**: `updateRemoteUserUID: false` to avoid user conflicts
- **Minimal Features**: Only basic common-utils, no heavy dependencies
- **Port Forwarding**: Pre-configured for ElizaOS ports (5432, 7777, 5173)

## Testing Process

### Step 1: Baseline Test (DONE)

```bash
./test-ssh-devcontainer.sh
```

**Current Baseline Results:**

- ✅ SSH connection active (`::1 49306 ::1 2222`)
- ✅ User: `codespace`
- ✅ SSH service running
- ✅ Internet connectivity
- ✅ Workspace writable
- ✅ Git available (v2.50.1)
- ✅ Node.js available (v22.17.0)
- ❌ Bun not installed (expected)

### Step 2: Rebuild Container

**In VS Code Command Palette (`Ctrl+Shift+P`):**

```
> Dev Containers: Rebuild Container
```

### Step 3: Post-Rebuild Verification

After rebuild, SSH back in and run:

```bash
./test-ssh-devcontainer.sh
```

**Expected Results:**

- ✅ SSH should still work
- ✅ User should still be `codespace`
- ✅ Workspace should still be accessible
- ✅ Basic tools should still work

### Step 4: If Successful, Add Dependencies

Only if SSH is preserved, we'll add:

- PostgreSQL (via docker-compose sidecar)
- Bun installation
- Rust/Cargo
- Tauri CLI

## Troubleshooting

### If SSH Breaks After Rebuild

**Symptoms:**

- Cannot SSH into the Codespace
- Connection refused or timeout
- User changed or permissions lost

**Possible Causes:**

1. **User Mismatch**: Container created different user than `codespace`
2. **SSH Daemon**: SSH service not running in container
3. **Port Conflicts**: Port 22 not properly forwarded
4. **Permission Issues**: Home directory or SSH keys not accessible

**Solutions:**

1. Check the devcontainer logs in VS Code
2. Try accessing via VS Code web interface
3. Modify `.devcontainer/devcontainer.json` to be even more minimal
4. Use `"image": "mcr.microsoft.com/devcontainers/universal:2"` if base Ubuntu fails

### If SSH Works, Dependencies Fail

This is the preferred failure mode - we can add dependencies incrementally:

1. **Add PostgreSQL**: Use docker-compose sidecar
2. **Add Bun**: Use postCreateCommand or features
3. **Add Rust**: Use devcontainer features
4. **Test Each Step**: Run test script after each addition

## Success Criteria

✅ **SSH Access Preserved**: Can still SSH into Codespace after rebuild
✅ **User Identity Maintained**: Still running as `codespace` user  
✅ **Workspace Access**: Can read/write files in `/workspaces/classified`
✅ **Network Connectivity**: Can access internet and GitHub
✅ **Port Forwarding**: Ports 5432, 7777, 5173 are forwarded

## Next Steps

1. **Test the minimal config** (rebuild container)
2. **Verify SSH still works** (run test script)
3. **If successful**: Add PostgreSQL via docker-compose
4. **If successful**: Add Bun, Rust, Tauri incrementally
5. **If any step fails**: Roll back and debug that specific addition

## Files Created

- `.devcontainer/devcontainer.json` - Minimal SSH-preserving configuration
- `test-ssh-devcontainer.sh` - Test script to verify functionality
- `SSH_DEVCONTAINER_TEST.md` - This documentation

## Important Notes

- **Don't install heavy dependencies yet** - Focus on SSH preservation first
- **Test after each change** - Incremental approach prevents wasting time
- **Document what breaks SSH** - So we can avoid those patterns
- **Keep VS Code access** - As backup if SSH fails

The goal is to prove we can use devcontainers without losing SSH, then build up from there.
