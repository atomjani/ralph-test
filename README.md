# Ralph-tui OpenCode Integration Test

This project demonstrates Ralph-tui integration with OpenCode AI agent using free models from OpenRouter.

## Working Free Models

Tested and working with OpenRouter free tier:
- `z-ai/glm-4.5-air:free` - Completely free, works via API (recommended)
- `qwen/qwen-coder-32b-instruct` - Cheap coding model

## Setup

1. Install Ralph-tui:
   ```bash
   bun install -g ralph-tui
   ```

2. Configure OpenCode with OpenRouter free model:
   ```bash
   # Create ~/.config/opencode/opencode.json
   {
     "$schema": "https://opencode.ai/config.json",
     "model": "z-ai/glm-4.5-air:free"
   }
   
   # Set environment variables
   export OPENAI_API_BASE="https://openrouter.ai/api/v1"
   export OPENAI_API_KEY="your-openrouter-api-key"
   ```

3. Initialize project:
   ```bash
   ./ralph.sh init
   ```

## Known Issues

### CLI Authentication Required
Both OpenCode and Claude Code require interactive login - they don't work with API keys in headless mode:
- **OpenCode**: "Session not found" error in non-interactive mode
- **Claude Code**: Requires `claude auth login` (web-based)

### Solutions:
1. **Use Claude Code** - Run `claude auth login` interactively
2. **Add credits to OpenRouter** - Paid models work with OpenCode
3. **Use different agent** - Some agents like droid/gemini might work

## API Test (Works!)

The free model works when called directly via API:
```bash
curl -X POST "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "z-ai/glm-4.5-air:free",
    "max_tokens": 50,
    "messages": [{"role": "user", "content": "say hi"}]
  }'
# Returns: {"choices":[{"message":{"content":"Hello!"}}],"usage":{"cost":0}}'
```

## Usage

```bash
# Check agent health
OPENAI_API_BASE="https://openrouter.ai/api/v1" OPENAI_API_KEY="your-key" ./ralph.sh doctor

# Create a new PRD
OPENAI_API_BASE="https://openrouter.ai/api/v1" OPENAI_API_KEY="your-key" ./ralph.sh prd

# Run tasks (requires CLI auth or paid API)
./ralph.sh run --prd ./prd.json

# View status
./ralph.sh status
```

## Configuration

Edit `.ralph-tui/config.toml`:
```toml
tracker = "json"
agent = "opencode"  # or "claude"
maxIterations = 10
```

## Files

- `ralph.sh` - Helper script for common operations
- `prd.json` - Task definitions (userStories format)
- `.ralph-tui/config.toml` - Ralph configuration

## Tested Commands

| Command | Status |
|---------|--------|
| `ralph-tui --version` | ✓ 0.7.1 |
| `ralph-tui plugins agents` | ✓ (7 agents) |
| `ralph-tui plugins trackers` | ✓ (4 trackers) |
| `ralph-tui config show` | ✓ |
| `ralph-tui skills list/install` | ✓ |
| `ralph-tui template show` | ✓ |
| OpenRouter API (curl) | ✓ Free model works! |
| `ralph-tui run` | ✗ CLI auth required |

## Summary

- **OpenRouter free model works via API** (z-ai/glm-4.5-air:free)
- **Ralph-tui CLI integration requires paid API or Claude Code login**
- Project is ready for GitHub push once authenticated
