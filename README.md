# Ralph-tui OpenCode Integration

This project demonstrates Ralph-tui integration with OpenCode using OpenRouter.

## Setup

1. **Install Ralph-tui:**
   ```bash
   bun install -g ralph-tui
   ```

2. **Configure OpenCode with OpenRouter:**
   ```bash
   # Set environment variables (required for ralph-tui)
   export OPENAI_API_BASE="https://openrouter.ai/api/v1"
   export OPENAI_API_KEY="your-openrouter-api-key"
   
   # Or add to your ~/.bashrc / ~/.zshrc
   echo 'export OPENAI_API_BASE="https://openrouter.ai/api/v1"' >> ~/.bashrc
   echo 'export OPENAI_API_KEY="your-api-key"' >> ~/.bashrc
   ```

3. **Initialize project:**
   ```bash
   ralph-tui setup
   ```

## Configuration

### OpenCode Config (~/.config/opencode/opencode.json)
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "openrouter/anthropic/claude-sonnet-4-20250514"
}
```

### Ralph Config (.ralph-tui/config.toml)
```toml
tracker = "json"
agent = "opencode"
maxIterations = 10
```

## OpenRouter Free Models

Tested working via API:
- `z-ai/glm-4.5-air:free` - Totally free
- `deepseek/deepseek-r1-0528:free` - Reasoning model
- `qwen/qwen3-coder:free` - Coding focused

**Note:** OpenCode CLI has issues running in headless/non-interactive mode with any model.

## Usage

```bash
# Check system info
ralph-tui info

# List available agents
ralph-tui plugins agents

# Check configuration
ralph-tui config show

# Run in TUI mode (interactive)
ralph-tui run --prd ./prd.json

# Run headless (requires working agent)
ralph-tui run --prd ./prd.json --headless --iterations 1
```

## Important Notes

### OpenCode Limitations
- OpenCode CLI requires interactive TUI session - doesn't work in pure headless/CI mode
- Works: `opencode` (starts TUI), `ralph-tui run` (with TUI)
- Doesn't work: `opencode run "command"`, ralph-tui headless mode

### Solutions
1. **Use TUI mode** - Run `ralph-tui run` without `--headless`
2. **Add OpenRouter credits** - Paid models may work better
3. **Use Claude Code** - `bun add -g @anthropic-ai/claude-code`

## Project Structure

```
ralph-test/
├── .ralph-tui/
│   └── config.toml       # Ralph configuration
├── prd.json              # Task definitions
├── ralph.sh             # Helper script
└── README.md            # This file
```

## GitHub

Repository: https://github.com/atomjani/ralph-test

## Tested Commands

| Command | Status |
|---------|--------|
| `ralph-tui --version` | ✓ 0.7.1 |
| `ralph-tui plugins agents` | ✓ 7 agents |
| `ralph-tui plugins trackers` | ✓ 4 trackers |
| `ralph-tui config show` | ✓ |
| `ralph-tui skills list/install` | ✓ |
| OpenRouter API (curl) | ✓ |
| `ralph-tui run` (TUI) | Requires setup |
| `ralph-tui run --headless` | ✗ OpenCode limitation |
