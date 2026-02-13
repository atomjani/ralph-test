#!/bin/bash
# Ralph-tui helper script for managing AI agent workflows
# This script provides convenient commands for Ralph-tui operations

set -e

RALPH_PROJECT="${RALPH_PROJECT:-.}"
RALPH_AGENT="${RALPH_AGENT:-opencode}"

# OpenRouter configuration (set your API key here)
OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}"
if [ -n "$OPENROUTER_API_KEY" ]; then
    export OPENAI_API_BASE="https://openrouter.ai/api/v1"
    export OPENAI_API_KEY="$OPENROUTER_API_KEY"
fi

show_help() {
    cat << EOF
Ralph-tui Helper Script

Usage: ralph.sh [command] [options]

Commands:
    init            Initialize Ralph-tui in current directory
    run             Start Ralph execution with TUI
    run-headless    Start Ralph in headless mode
    status          Check current session status
    doctor          Run agent health check
    prd             Create new PRD interactively
    tasks           Show current task list
    logs [n]        View logs (default: latest)
    setup           Re-run setup wizard
    config          Show current configuration
    help            Show this help message

Environment Variables:
    RALPH_PROJECT       Project directory (default: current dir)
    RALPH_AGENT         Agent to use (default: opencode)
    OPENROUTER_API_KEY  OpenRouter API key (for OpenCode)

Examples:
    OPENROUTER_API_KEY=sk-... ralph.sh init
    OPENROUTER_API_KEY=sk-... ralph.sh doctor
    OPENROUTER_API_KEY=sk-... ralph.sh run --prd ./prd.json
    ralph.sh tasks
    ralph.sh logs 3

EOF
}

cmd_init() {
    echo "Initializing Ralph-tui..."
    cd "$RALPH_PROJECT"
    ralph-tui setup
}

cmd_run() {
    cd "$RALPH_PROJECT"
    ralph-tui run --agent "$RALPH_AGENT" "$@"
}

cmd_run_headless() {
    cd "$RALPH_PROJECT"
    ralph-tui run --headless --agent "$RALPH_AGENT" "$@"
}

cmd_status() {
    cd "$RALPH_PROJECT"
    ralph-tui status "$@"
}

cmd_doctor() {
    ralph-tui doctor
}

cmd_prd() {
    cd "$RALPH_PROJECT"
    ralph-tui create-prd --agent "$RALPH_AGENT" "$@"
}

cmd_tasks() {
    cd "$RALPH_PROJECT"
    if [ -f prd.json ]; then
        cat prd.json | jq -r '.tasks[] | "[\(.status)] \(.id): \(.title)"'
    else
        echo "No prd.json found in $RALPH_PROJECT"
        exit 1
    fi
}

cmd_logs() {
    cd "$RALPH_PROJECT"
    if [ -n "$1" ]; then
        ralph-tui logs --iteration "$1"
    else
        ralph-tui logs
    fi
}

cmd_setup() {
    cd "$RALPH_PROJECT"
    ralph-tui setup
}

cmd_config() {
    cd "$RALPH_PROJECT"
    ralph-tui config show
}

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
    init) cmd_init "$@" ;;
    run) cmd_run "$@" ;;
    run-headless) cmd_run_headless "$@" ;;
    status) cmd_status "$@" ;;
    doctor) cmd_doctor "$@" ;;
    prd) cmd_prd "$@" ;;
    tasks) cmd_tasks "$@" ;;
    logs) cmd_logs "$@" ;;
    setup) cmd_setup "$@" ;;
    config) cmd_config "$@" ;;
    help|--help|-h) show_help ;;
    *) echo "Unknown command: $COMMAND"; show_help; exit 1 ;;
esac
