#!/usr/bin/env bash
set -euo pipefail

# Configurations
CONFIG_FILE="$HOME/.config/agent-notify.conf"
DEFAULT_TOPIC="denial-agent-alerts"
NTFY_URL="https://ntfy.sh"

# Load config if exists
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

# Topic priority: Env var > Config file > Default
TOPIC="${NTFY_TOPIC:-${DEFAULT_TOPIC}}"

# Usage helper
usage() {
    echo "Usage: $0 [agent] [state] [tool_name] [tool_cmd]"
    echo "States: running, needs-input, done, off"
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

AGENT="$1"
STATE="$2"

TOOL_NAME=""
TOOL_CMD=""

# 1. Check if positional arguments are passed for tool name and command (e.g. from Pi or OpenCode)
if [ "$#" -ge 3 ]; then
    TOOL_NAME="$3"
    if [ "$#" -ge 4 ]; then
        TOOL_CMD="$4"
    fi
fi

# 2. If not passed as positional, check if stdin has JSON (e.g. from Claude or Antigravity)
if [ -z "$TOOL_NAME" ] && [ ! -t 0 ]; then
    # Read stdin non-blocking using Python
    PARSED=$(python3 -c '
import sys, json

def format_questions(args):
    if not isinstance(args, dict):
        return None
    q_list = args.get("questions")
    if not q_list or not isinstance(q_list, list):
        return None
    parts = []
    for q in q_list:
        if not isinstance(q, dict):
            continue
        q_text = q.get("question")
        options = q.get("options") or []
        if q_text:
            parts.append(q_text)
        for opt in options:
            parts.append(f"- {opt}")
    return "\n".join(parts) if parts else None

try:
    content = sys.stdin.read().strip()
    if content:
        data = json.loads(content)
        if "tool_name" in data:
            tool = data["tool_name"]
            tool_input = data.get("tool_input", {})
            q_formatted = format_questions(tool_input) if isinstance(tool_input, dict) else None
            if q_formatted:
                cmd = q_formatted
            elif isinstance(tool_input, dict):
                cmd = tool_input.get("command") or tool_input.get("path") or tool_input.get("CommandLine") or json.dumps(tool_input)
            else:
                cmd = str(tool_input)
            print(f"{tool}|{cmd}")
        elif "toolCall" in data:
            tool = data["toolCall"].get("name")
            args = data["toolCall"].get("args", {})
            q_formatted = format_questions(args)
            if q_formatted:
                cmd = q_formatted
            else:
                cmd = args.get("CommandLine") or args.get("Target") or args.get("path") or json.dumps(args)
            print(f"{tool}|{cmd}")
except Exception:
    pass
' 2>/dev/null || echo "")

    if [ -n "$PARSED" ]; then
        TOOL_NAME="${PARSED%%|*}"
        TOOL_CMD="${PARSED#*|}"
    fi
fi

# Helper to resolve target pane
resolve_pane() {
    local agent="$1"
    if [ -n "${TMUX_PANE:-}" ]; then
        echo "$TMUX_PANE"
        return
    fi
    local mapped_pane
    mapped_pane=$(tmux show-environment -g "TMUX_AGENT_ACTIVE_PANE_${agent}" 2>/dev/null | sed 's/^[^=]*=//' || true)
    if [ -n "$mapped_pane" ]; then
        echo "$mapped_pane"
        return
    fi
    tmux display-message -p '#{pane_id}' 2>/dev/null || echo ""
}

# 1. Update tmux-agent-indicator state (optional - skip silently if not installed)
INDICATOR_SCRIPT=""
for candidate in "$HOME/.config/tmux/plugins/tmux-agent-indicator/scripts/agent-state.sh" "$HOME/.tmux/plugins/tmux-agent-indicator/scripts/agent-state.sh"; do
    if [ -f "$candidate" ]; then
        INDICATOR_SCRIPT="$candidate"
        break
    fi
done
if [ -n "$INDICATOR_SCRIPT" ]; then
    # Always reset running state first if transitioning to running to trigger animation
    if [ "$STATE" = "running" ]; then
        bash "$INDICATOR_SCRIPT" --agent "$AGENT" --state off >/dev/null 2>&1 || true
    fi
    bash "$INDICATOR_SCRIPT" --agent "$AGENT" --state "$STATE" >/dev/null 2>&1 || true
fi

# 2. Send ntfy.sh notification if state is needs-input (with a 2-second debounce/confirmation check)
if [ "$STATE" = "needs-input" ]; then
    (
        # Sleep for 2 seconds to see if state is transient (e.g. auto-approved tool)
        sleep 2
        
        # Verify the state is STILL needs-input before notifying
        if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
            PANE_ID=$(resolve_pane "$AGENT")
            if [ -n "$PANE_ID" ]; then
                CURRENT_STATE=$(tmux show-environment -g "TMUX_AGENT_PANE_${PANE_ID}_STATE" 2>/dev/null | sed 's/^[^=]*=//' || true)
                if [ "$CURRENT_STATE" != "needs-input" ]; then
                    # The state has changed, meaning it was an auto-approved or already handled prompt. Exit without notifying.
                    exit 0
                fi
            fi
        fi

        # Send the notification
        TITLE="$AGENT asks for attention:"
        MESSAGE="$AGENT asks for attention:"
        
        if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
            SESSION_NAME=$(tmux display-message -p '#S' 2>/dev/null || echo "unknown")
            PANE_ID=$(resolve_pane "$AGENT")
            CWD=""
            if [ -n "$PANE_ID" ]; then
                CWD=$(tmux display-message -p -t "$PANE_ID" '#{pane_current_path}' 2>/dev/null || echo "")
            fi
            if [ -n "$CWD" ]; then
                CWD="${CWD/#$HOME/\~}"
                MESSAGE="[$SESSION_NAME] $CWD"
            else
                MESSAGE="[$SESSION_NAME]"
            fi
        fi

        # Append tool / command details if available
        if [ -n "$TOOL_NAME" ]; then
            MESSAGE="${MESSAGE}
<${TOOL_NAME}>"
            if [ -n "$TOOL_CMD" ]; then
                # Trim command if it's too long
                if [ ${#TOOL_CMD} -gt 150 ]; then
                    TOOL_CMD="${TOOL_CMD:0:147}..."
                fi
                MESSAGE="${MESSAGE}
${TOOL_CMD}"
            fi
        fi

        curl -s \
            -H "Title: $TITLE" \
            -H "Priority: high" \
            -H "Tags: $AGENT,ai" \
            -d "$MESSAGE" \
            "$NTFY_URL/$TOPIC" >/dev/null 2>&1
    ) &
fi

# 3. Record starting commit on running state
if [ "$STATE" = "running" ]; then
    PANE_ID=""
    CWD=""
    if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
        PANE_ID=$(resolve_pane "$AGENT")
        if [ -n "$PANE_ID" ]; then
            CWD=$(tmux display-message -p -t "$PANE_ID" '#{pane_current_path}' 2>/dev/null || echo "")
        fi
    fi
    if [ -z "$CWD" ]; then
        CWD="$PWD"
    fi
    
    COMMIT_FILE="/tmp/agent-notify-${AGENT}-${PANE_ID:-default}-start-commit"
    if [ ! -f "$COMMIT_FILE" ]; then
        if [ -n "$CWD" ] && [ -d "$CWD" ] && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            START_COMMIT=$(git -C "$CWD" rev-parse HEAD 2>/dev/null || echo "")
            if [ -n "$START_COMMIT" ]; then
                echo "$START_COMMIT" > "$COMMIT_FILE"
            fi
        fi
    fi
fi

# 4. Clean up starting commit on off state
if [ "$STATE" = "off" ]; then
    PANE_ID=""
    if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
        PANE_ID=$(resolve_pane "$AGENT")
    fi
    rm -f "/tmp/agent-notify-${AGENT}-${PANE_ID:-default}-start-commit"
fi

# 5. Send ntfy.sh notification if state is done
if [ "$STATE" = "done" ]; then
    (
        CWD=""
        PANE_ID=""
        if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
            PANE_ID=$(resolve_pane "$AGENT")
            if [ -n "$PANE_ID" ]; then
                CWD=$(tmux display-message -p -t "$PANE_ID" '#{pane_current_path}' 2>/dev/null || echo "")
            fi
        fi
        if [ -z "$CWD" ]; then
            CWD="$PWD"
        fi

        # Find starting commit
        START_COMMIT=""
        COMMIT_FILE="/tmp/agent-notify-${AGENT}-${PANE_ID:-default}-start-commit"
        if [ -f "$COMMIT_FILE" ]; then
            START_COMMIT=$(cat "$COMMIT_FILE" 2>/dev/null || echo "")
            rm -f "$COMMIT_FILE"
        fi

        COMMITS=""
        if [ -n "$CWD" ] && [ -d "$CWD" ] && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            CURRENT_COMMIT=$(git -C "$CWD" rev-parse HEAD 2>/dev/null || echo "")
            if [ -n "$START_COMMIT" ] && [ -n "$CURRENT_COMMIT" ] && [ "$START_COMMIT" != "$CURRENT_COMMIT" ]; then
                if git -C "$CWD" merge-base --is-ancestor "$START_COMMIT" "$CURRENT_COMMIT" >/dev/null 2>&1; then
                    COMMITS=$(git -C "$CWD" log --oneline "${START_COMMIT}..${CURRENT_COMMIT}" 2>/dev/null || echo "")
                fi
            fi
        fi

        CWD="${CWD/#$HOME/\~}"

        TITLE="$AGENT is done working"
        MESSAGE="$AGENT has finished working."

        if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
            SESSION_NAME=$(tmux display-message -p '#S' 2>/dev/null || echo "unknown")
            if [ -n "$CWD" ]; then
                MESSAGE="[$SESSION_NAME] $AGENT is done
$CWD"
            else
                MESSAGE="[$SESSION_NAME] $AGENT is done"
            fi
        fi

        if [ -n "$COMMITS" ]; then
            MESSAGE="${MESSAGE}

Commits:
${COMMITS}"
        fi

        curl -s \
            -H "Title: $TITLE" \
            -H "Priority: default" \
            -H "Tags: $AGENT,done,ai" \
            -d "$MESSAGE" \
            "$NTFY_URL/$TOPIC" >/dev/null 2>&1
    ) &
fi
