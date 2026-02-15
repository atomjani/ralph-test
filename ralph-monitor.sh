#!/bin/bash
# Ralph TUI Monitor Script
# Shows running processes, task status, and provides reconnection

set -e

RALPH_DIR="${RALPH_DIR:-$HOME/ralph-test}"
SESSION_FILE="$RALPH_DIR/.ralph-tui/session.json"
SESSION_META="$RALPH_DIR/.ralph-tui/session-meta.json"
ITERATIONS_DIR="$RALPH_DIR/.ralph-tui/iterations"

show_help() {
    cat << EOF
Ralph TUI Monitor Script

Usage: ralph-monitor.sh [command] [options]

Commands:
    status          Show current session status (default)
    tasks           Show all tasks with their status
    running         Show currently running processes
    active          Show active task
    history         Show iteration history
    logs [task]     Show logs for a task
    connect         Reconnect to Ralph TUI
    watch           Watch mode (continuous monitoring)
    help            Show this help

Options:
    -d, --dir       Ralph project directory (default: ~/ralph-test)

Examples:
    ralph-monitor.sh status
    ralph-monitor.sh tasks
    ralph-monitor.sh running
    ralph-monitor.sh watch
    ralph-monitor.sh connect
    ralph-monitor.sh -d /path/to/project status

EOF
}

check_project() {
    if [ ! -d "$RALPH_DIR/.ralph-tui" ]; then
        echo "Error: Not a Ralph project directory: $RALPH_DIR"
        echo "Run 'ralph-tui setup' first or specify correct directory with -d"
        exit 1
    fi
}

cmd_status() {
    check_project
    
    if [ ! -f "$SESSION_FILE" ]; then
        echo "No active session found"
        exit 1
    fi
    
    echo "═══════════════════════════════════════════════════════"
    echo "  Ralph TUI Session Status"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    STATUS=$(jq -r '.status' "$SESSION_FILE" 2>/dev/null || echo "unknown")
    SESSION_ID=$(jq -r '.sessionId' "$SESSION_FILE" 2>/dev/null || echo "N/A")
    STARTED=$(jq -r '.startedAt' "$SESSION_FILE" 2>/dev/null | cut -d'T' -f2 | tr -d 'Z' | cut -d'.' -f1)
    CURRENT=$(jq -r '.currentIteration' "$SESSION_FILE" 2>/dev/null || echo "0")
    MAX=$(jq -r '.maxIterations' "$SESSION_FILE" 2>/dev/null || echo "0")
    TASKS_DONE=$(jq -r '.tasksCompleted' "$SESSION_FILE" 2>/dev/null || echo "0")
    TOTAL=$(jq -r '.trackerState.totalTasks' "$SESSION_FILE" 2>/dev/null || echo "0")
    AGENT=$(jq -r '.agentPlugin' "$SESSION_FILE" 2>/dev/null || echo "unknown")
    CWD=$(jq -r '.cwd' "$SESSION_FILE" 2>/dev/null || echo "$RALPH_DIR")
    
    echo "  Session ID:    $SESSION_ID"
    echo "  Status:        $STATUS"
    echo "  Agent:         $AGENT"
    echo "  Working Dir:   $CWD"
    echo "  Started:       $STARTED"
    echo "  Progress:      Iteration $CURRENT / $MAX"
    echo "  Tasks:         $TASKS_DONE / $TOTAL completed"
    echo ""
    
    ACTIVE_TASKS=$(jq -r '.activeTaskIds[]' "$SESSION_FILE" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
    if [ -n "$ACTIVE_TASKS" ]; then
        echo "  Active:        $ACTIVE_TASKS"
    fi
    echo ""
}

cmd_tasks() {
    check_project
    
    if [ ! -f "$SESSION_FILE" ]; then
        echo "No session found"
        exit 1
    fi
    
    echo "═══════════════════════════════════════════════════════"
    echo "  Task List"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    TOTAL=$(jq -r '.trackerState.totalTasks' "$SESSION_FILE" 2>/dev/null || echo "0")
    echo "Total tasks: $TOTAL"
    echo ""
    
    jq -r '.trackerState.tasks[] | "\(.id)|\(.status)|\(.title)"' "$SESSION_FILE" 2>/dev/null | while IFS='|' read -r id status title; do
        case "$status" in
            completed)   icon="✓" color="\033[0;32m" ;;
            in_progress) icon="◐" color="\033[0;33m" ;;
            open)        icon="○" color="\033[0;37m" ;;
            failed)      icon="✗" color="\033[0;31m" ;;
            blocked)     icon="■" color="\033[0;35m" ;;
            *)           icon="?" color="\033[0;37m" ;;
        esac
        printf "  ${color}${icon}\033[0m  %-8s  %s\n" "$id" "$title"
    done
    echo ""
}

cmd_running() {
    echo "═══════════════════════════════════════════════════════"
    echo "  Running Processes (Ralph & OpenCode)"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    echo "Ralph TUI processes:"
    if pgrep -f "ralph-tui" > /dev/null 2>&1; then
        ps aux | grep -E "[r]alph-tui|[r]alph" | head -10 | while read -r line; do
            echo "  $line"
        done
    else
        echo "  (none)"
    fi
    
    echo ""
    echo "OpenCode processes:"
    if pgrep -f "opencode" > /dev/null 2>&1; then
        ps aux | grep -E "[o]pencode" | head -10 | while read -r line; do
            echo "  $line"
        done
    else
        echo "  (none)"
    fi
    
    echo ""
    echo "Bun/Node processes ( Ralph might run on bun):"
    if pgrep -f "bun" > /dev/null 2>&1; then
        ps aux | grep -E "[b]un" | head -10 | while read -r line; do
            echo "  $line"
        done
    else
        echo "  (none)"
    fi
    echo ""
}

cmd_active() {
    check_project
    
    if [ ! -f "$SESSION_FILE" ]; then
        echo "No active session"
        exit 1
    fi
    
    STATUS=$(jq -r '.status' "$SESSION_FILE" 2>/dev/null)
    
    if [ "$STATUS" != "running" ]; then
        echo "Session is not running (status: $STATUS)"
        exit 1
    fi
    
    echo "═══════════════════════════════════════════════════════"
    echo "  Currently Working On"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    ACTIVE_IDS=$(jq -r '.activeTaskIds[]' "$SESSION_FILE" 2>/dev/null)
    
    for task_id in $ACTIVE_IDS; do
        TITLE=$(jq -r ".trackerState.tasks[] | select(.id == \"$task_id\") | .title" "$SESSION_FILE" 2>/dev/null)
        STATUS=$(jq -r ".trackerState.tasks[] | select(.id == \"$task_id\") | .status" "$SESSION_FILE" 2>/dev/null)
        
        echo "  Task:      $task_id"
        echo "  Title:     $TITLE"
        echo "  Status:    $STATUS"
        
        ITER_LOG=$(ls -t "$ITERATIONS_DIR/"*_"$task_id".log 2>/dev/null | head -1)
        if [ -n "$ITER_LOG" ]; then
            echo "  Log:       $ITER_LOG"
        fi
        echo ""
    done
}

cmd_history() {
    check_project
    
    if [ ! -f "$SESSION_FILE" ]; then
        echo "No session found"
        exit 1
    fi
    
    echo "═══════════════════════════════════════════════════════"
    echo "  Iteration History"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    
    ITER_COUNT=$(jq -r '.iterations | length' "$SESSION_FILE" 2>/dev/null || echo "0")
    
    if [ "$ITER_COUNT" -eq 0 ]; then
        echo "  No iterations yet"
        echo ""
        return
    fi
    
    jq -r '.iterations[] | "\(.iteration)|\(.status)|\(.taskId)|\(.taskTitle)|\(.durationMs)"' "$SESSION_FILE" 2>/dev/null | while IFS='|' read -r iter status task_id title duration; do
        case "$status" in
            success)  icon="✓" color="\033[0;32m" ;;
            failed)   icon="✗" color="\033[0;31m" ;;
            running)  icon="◐" color="\033[0;33m" ;;
            *)        icon="?" color="\033[0;37m" ;;
        esac
        dur_sec=$((duration / 1000))
        printf "  ${color}${icon}\033[0m  Iteration %s | %s | %s | %ss\n" "$iter" "$task_id" "$title" "$dur_sec"
    done
    echo ""
}

cmd_logs() {
    check_project
    
    TASK_ID="${1:-}"
    
    if [ -n "$TASK_ID" ]; then
        LOG_FILE=$(ls -t "$ITERATIONS_DIR/"*"_$TASK_ID".log 2>/dev/null | head -1)
        if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
            echo "No logs found for task: $TASK_ID"
            exit 1
        fi
        echo "Showing logs for $TASK_ID:"
        echo "───────────────────────────────────────────────────────"
        cat "$LOG_FILE"
    else
        echo "Recent log files:"
        ls -t "$ITERATIONS_DIR/"*.log 2>/dev/null | head -5 | while read -r log; do
            basename "$log"
        done
        echo ""
        echo "Usage: ralph-monitor.sh logs <task-id>"
    fi
}

cmd_connect() {
    check_project
    
    STATUS=$(jq -r '.status' "$SESSION_FILE" 2>/dev/null || echo "unknown")
    
    if [ "$STATUS" == "running" ]; then
        echo "Reconnecting to running Ralph TUI session..."
        echo ""
        cd "$RALPH_DIR"
        ralph-tui run --prd ./prd.json
    else
        echo "No running session. Starting new session..."
        echo ""
        cd "$RALPH_DIR"
        ralph-tui run --prd ./prd.json
    fi
}

cmd_watch() {
    check_project
    
    echo "Watching Ralph TUI session (Ctrl+C to exit)..."
    echo ""
    
    while true; do
        clear
        cmd_status
        cmd_tasks
        sleep 5
    done
}

PARAMS="$(getopt -o d:h -l dir:,help -n 'ralph-monitor.sh' -- "$@")"
eval set -- "$PARAMS"

while true; do
    case "$1" in
        -d|--dir)
            RALPH_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
    esac
done

COMMAND="${1:-status}"

case "$COMMAND" in
    status) cmd_status "$@" ;;
    tasks) cmd_tasks "$@" ;;
    running) cmd_running "$@" ;;
    active) cmd_active "$@" ;;
    history) cmd_history "$@" ;;
    logs) cmd_logs "$2" ;;
    connect) cmd_connect "$@" ;;
    watch) cmd_watch "$@" ;;
    help|--help|-h) show_help ;;
    *) echo "Unknown command: $COMMAND"; show_help; exit 1 ;;
esac
