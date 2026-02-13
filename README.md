# Ralph-tui OpenCode Integration Test

This project demonstrates Ralph-tui integration with OpenCode AI agent.

## Setup

1. Install Ralph-tui:
   ```bash
   bun install -g ralph-tui
   ```

2. Configure OpenCode:
   ```bash
   # Set your API key
   export ANTHROPIC_API_KEY="your-api-key"
   
   # Or use OpenRouter
   export OPENROUTER_API_KEY="your-api-key"
   ```

3. Initialize project:
   ```bash
   ./ralph.sh init
   ```

## Usage

```bash
# Check agent health
./ralph.sh doctor

# Create a new PRD
./ralph.sh prd

# Run tasks
./ralph.sh run --prd ./prd.json

# Run headless (for CI/CD)
./ralph.sh run-headless --prd ./prd.json --iterations 10

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

- `ralph-tui --version` - ✓
- `ralph-tui plugins agents` - ✓
- `ralph-tui plugins trackers` - ✓
- `ralph-tui config show` - ✓
- `ralph-tui skills list` - ✓
- `ralph-tui skills install` - ✓
- `ralph-tui template show` - ✓
- `ralph-tui doctor` - Requires API key
- `ralph-tui create-prd` - Requires API key
- `ralph-tui run` - Requires API key
