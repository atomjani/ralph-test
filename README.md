# Ralph-tui OpenCode Integration Test

This project demonstrates Ralph-tui integration with OpenCode AI agent.

## Setup

1. Install Ralph-tui:
   ```bash
   bun install -g ralph-tui
   ```

2. Configure OpenCode with OpenRouter:
   ```bash
   # Create ~/.config/opencode/opencode.json
   {
     "$schema": "https://opencode.ai/config.json",
     "model": "openrouter/anthropic/claude-3.5-sonnet"
   }
   
   # Set environment variables before running ralph-tui
   export OPENAI_API_BASE="https://openrouter.ai/api/v1"
   export OPENAI_API_KEY="your-openrouter-api-key"
   ```

3. Initialize project:
   ```bash
   ./ralph.sh init
   ```

## Usage

```bash
# Check agent health (requires API key)
OPENAI_API_BASE="https://openrouter.ai/api/v1" OPENAI_API_KEY="your-key" ./ralph.sh doctor

# Create a new PRD
OPENAI_API_BASE="https://openrouter.ai/api/v1" OPENAI_API_KEY="your-key" ./ralph.sh prd

# Run tasks
OPENAI_API_BASE="https://openrouter.ai/api/v1" OPENAI_API_KEY="your-key" ./ralph.sh run --prd ./prd.json

# Run headless (for CI/CD)
OPENAI_API_BASE="https://openrouter.ai/api/v1" OPENAI_API_KEY="your-key" ./ralph.sh run-headless --prd ./prd.json --iterations 10

# View status
./ralph.sh status

# View logs
./ralph.sh logs
./ralph.sh logs 5  # iteration 5
```

## Configuration

Edit `.ralph-tui/config.toml`:
```toml
tracker = "json"
agent = "opencode"
maxIterations = 10
```

## Files

- `ralph.sh` - Helper script for common operations
- `prd.json` - Task definitions
- `.ralph-tui/config.toml` - Ralph configuration

## Tested Commands

| Command | Status |
|---------|--------|
| `ralph-tui --version` | ✓ |
| `ralph-tui plugins agents` | ✓ (7 agents) |
| `ralph-tui plugins trackers` | ✓ (4 trackers) |
| `ralph-tui config show` | ✓ |
| `ralph-tui skills list` | ✓ (4 skills) |
| `ralph-tui skills install` | ✓ |
| `ralph-tui template show` | ✓ |
| `ralph-tui doctor` | Requires API key with credits |
| `ralph-tui create-prd` | Requires API key with credits |
| `ralph-tui run` | Requires API key with credits |

## Notes

- OpenRouter API requires credits for the API to work
- The "Session not found" error in preflight is a known issue with OpenCode in non-interactive mode
- For production use, consider using Claude Code as the agent instead
