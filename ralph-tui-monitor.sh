#!/bin/bash
# Ralph TUI Monitor - Interactive TUI

RALPH_DIR="${RALPH_DIR:-$HOME/ralph-test}"
SESSION_FILE="$RALPH_DIR/.ralph-tui/session.json"
ITERATIONS_DIR="$RALPH_DIR/.ralph-tui/iterations"

HEIGHT=20
WIDTH=70

draw_header() {
    local title="$1"
    local len=${#title}
    local pad=$(( (WIDTH - len - 2) / 2 ))
    printf "┌%s┐\n" "$(printf '─%.0s' $(seq 1 $((WIDTH-2))))"
    printf "│%${pad}s%s%${pad}s│\n" "" "$title" ""
    printf "├%s┤\n" "$(printf '─%.0s' $(seq 1 $((WIDTH-2))))"
}

draw_footer() {
    printf "└%s┘\n" "$(printf '─%.0s' $(seq 1 $((WIDTH-2))))"
}

draw_box() {
    local content="$1"
    local lines=()
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$content"
    
    for line in "${lines[@]}"; do
        printf "│ %-66s │\n" "$line"
    done
}

get_status() {
    if [ ! -f "$SESSION_FILE" ]; then
        echo "No session"
        return
    fi
    jq -r '.status' "$SESSION_FILE" 2>/dev/null
}

get_tasks() {
    if [ ! -f "$SESSION_FILE" ]; then
        echo ""
        return
    fi
    jq -r '.trackerState.tasks[] | "\(.id)|\(.status)|\(.title)"' "$SESSION_FILE" 2>/dev/null
}

get_active() {
    if [ ! -f "$SESSION_FILE" ]; then
        echo ""
        return
    fi
    jq -r '.activeTaskIds[]' "$SESSION_FILE" 2>/dev/null
}

get_history() {
    if [ ! -f "$SESSION_FILE" ]; then
        echo ""
        return
    fi
    jq -r '.iterations[] | "\(.iteration)|\(.status)|\(.taskId)|\(.durationMs)"' "$SESSION_FILE" 2>/dev/null
}

get_session_info() {
    if [ ! -f "$SESSION_FILE" ]; then
        echo "Session ID:    N/A"
        echo "Status:        N/A"
        echo "Agent:         N/A"
        echo "Progress:      N/A"
        echo "Tasks:         N/A"
        return
    fi
    
    local status session_id agent current max tasks_done total cwd
    status=$(jq -r '.status' "$SESSION_FILE" 2>/dev/null)
    session_id=$(jq -r '.sessionId' "$SESSION_FILE" 2>/dev/null | cut -c1-8)
    agent=$(jq -r '.agentPlugin' "$SESSION_FILE" 2>/dev/null)
    current=$(jq -r '.currentIteration' "$SESSION_FILE" 2>/dev/null)
    max=$(jq -r '.maxIterations' "$SESSION_FILE" 2>/dev/null)
    tasks_done=$(jq -r '.tasksCompleted' "$SESSION_FILE" 2>/dev/null)
    total=$(jq -r '.trackerState.totalTasks' "$SESSION_FILE" 2>/dev/null)
    cwd=$(jq -r '.cwd' "$SESSION_FILE" 2>/dev/null)
    
    echo "Session ID:    ${session_id:-N/A}"
    echo "Status:        ${status:-N/A}"
    echo "Agent:         ${agent:-N/A}"
    echo "Progress:      Iteration ${current:-0} / ${max:-0}"
    echo "Tasks:         ${tasks_done:-0} / ${total:-0} completed"
    echo "Working Dir:   ${cwd:-$RALPH_DIR}"
}

show_status() {
    clear
    draw_header "RALPH TUI MONITOR"
    
    echo ""
    get_session_info | while read -r line; do
        printf "│ %-66s │\n" "$line"
    done
    
    echo ""
    printf "│ %-66s │\n" "═══ Active Tasks ═══"
    
    local active_tasks
    active_tasks=$(get_active)
    if [ -n "$active_tasks" ]; then
        for task_id in $active_tasks; do
            local title status
            title=$(jq -r ".trackerState.tasks[] | select(.id == \"$task_id\") | .title" "$SESSION_FILE" 2>/dev/null)
            status=$(jq -r ".trackerState.tasks[] | select(.id == \"$task_id\") | .status" "$SESSION_FILE" 2>/dev/null)
            printf "│   ▶ %-10s %-53s │\n" "$task_id" "${title:0:50}"
        done
    else
        printf "│   %-64s │\n" "(none)"
    fi
    
    echo ""
    draw_footer
    echo ""
    echo "  [R]econnect  [W]atch  [Q]uit"
}

show_tasks() {
    clear
    draw_header "TASK LIST"
    echo ""
    
    local tasks
    tasks=$(get_tasks)
    
    if [ -z "$tasks" ]; then
        printf "│ %-66s │\n" "No tasks found"
        echo ""
        draw_footer
        return
    fi
    
    while IFS='|' read -r id status title; do
        case "$status" in
            completed)   icon="✓" ;;
            in_progress) icon="◐" ;;
            open)        icon="○" ;;
            failed)      icon="✗" ;;
            blocked)     icon="■" ;;
            *)           icon="?" ;;
        esac
        printf "│  %s  %-8s  %-53s │\n" "$icon" "$id" "${title:0:50}"
    done <<< "$tasks"
    
    echo ""
    draw_footer
}

show_history() {
    clear
    draw_header "ITERATION HISTORY"
    echo ""
    
    local history
    history=$(get_history)
    
    if [ -z "$history" ]; then
        printf "│ %-66s │\n" "No iterations yet"
        echo ""
        draw_footer
        return
    fi
    
    while IFS='|' read -r iter status task_id duration; do
        case "$status" in
            success)  icon="✓" ;;
            failed)   icon="✗" ;;
            running)  icon="◐" ;;
            *)        icon="?" ;;
        esac
        dur_sec=$((duration / 1000))
        printf "│  %s  Iter %s | %s | %ss%38s │\n" "$icon" "$iter" "$task_id" "$dur_sec" ""
    done <<< "$history"
    
    echo ""
    draw_footer
}

show_running() {
    clear
    draw_header "RUNNING PROCESSES"
    echo ""
    
    printf "│ %-66s │\n" "Ralph TUI:"
    if pgrep -f "ralph-tui" > /dev/null 2>&1; then
        ps aux | grep -E "[r]alph-tui" | head -3 | while read -r line; do
            printf "│   %-64s │\n" "${line:0:64}"
        done
    else
        printf "│   %-64s │\n" "(not running)"
    fi
    
    echo ""
    printf "│ %-66s │\n" "OpenCode:"
    if pgrep -f "opencode" > /dev/null 2>&1; then
        ps aux | grep -E "[o]pencode" | head -3 | while read -r line; do
            printf "│   %-64s │\n" "${line:0:64}"
        done
    else
        printf "│   %-64s │\n" "(not running)"
    fi
    
    echo ""
    draw_footer
}

watch_mode() {
    local key
    while true; do
        show_status
        echo " Watching... (Press Q to quit)"
        read -t 2 -n 1 key 2>/dev/null
        if [[ "$key" == "q" ]] || [[ "$key" == "Q" ]]; then
            break
        fi
    done
}

connect_tui() {
    cd "$RALPH_DIR"
    if command -v ralph-tui &> /dev/null; then
        ralph-tui run --prd ./prd.json
    else
        echo "ralph-tui not found. Install with: bun install -g ralph-tui"
        read -p "Press Enter to continue..."
    fi
}

check_project() {
    if [ ! -d "$RALPH_DIR/.ralph-tui" ]; then
        echo "Error: Not a Ralph project: $RALPH_DIR"
        echo "Run 'ralph-tui setup' first"
        exit 1
    fi
}

main() {
    check_project
    
    local view="status"
    local key
    
    while true; do
        case "$view" in
            status) show_status ;;
            tasks)  show_tasks ;;
            history) show_history ;;
            running) show_running ;;
        esac
        
        echo ""
        echo -n "  [S]tatus  [T]asks  [H]istory  [P]rocesses  [R]econnect  [W]atch  [Q]uit: "
        read -n 1 key
        
        case "$key" in
            s|S) view="status" ;;
            t|T) view="tasks" ;;
            h|H) view="history" ;;
            p|P) view="running" ;;
            r|R) connect_tui ;;
            w|W) watch_mode ;;
            q|Q) exit 0 ;;
        esac
    done
}

main "$@"
