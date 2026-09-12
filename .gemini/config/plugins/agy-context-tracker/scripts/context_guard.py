#!/usr/bin/env python3
"""PreInvocation context guard hook for Antigravity CLI."""

import json
import os
import sys

# Ensure scripts directory is on path for sibling imports
SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from statusline import get_model_context_window, parse_transcript_tokens

CONTEXT_THRESHOLD = 0.80


def calculate_usage_percentage(tokens: int, window: int) -> float:
    """Calculate context usage percentage safely."""
    if window <= 0:
        return 0.0
    return (tokens / window) * 100.0


def format_number(val: int) -> str:
    """Format integer with thousands separator."""
    return f"{max(0, val):,}"


def build_warning_message(pct: float, tokens: int, window: int) -> str:
    """Construct ephemeral warning message string."""
    pct_str = f"{pct:.0f}%"
    t_str = format_number(tokens)
    w_str = format_number(window)
    return (
        f"WARNING: Context window usage is at {pct_str} ({t_str} / {w_str} tokens). "
        "Consider running /handoff or wrapping up tasks."
    )


def generate_guard_response(
    tokens: int, window: int, threshold: float = CONTEXT_THRESHOLD
) -> dict:
    """Produce hook result JSON based on token threshold check."""
    if window <= 0 or (tokens / window) <= threshold:
        return {"injectSteps": []}
    pct = calculate_usage_percentage(tokens, window)
    warning = build_warning_message(pct, tokens, window)
    return {"injectSteps": [{"ephemeralMessage": warning}]}


def parse_stdin_payload() -> dict:
    """Safely parse input JSON from stdin."""
    if sys.stdin.isatty():
        return {}
    try:
        content = sys.stdin.read().strip()
        return json.loads(content) if content else {}
    except (json.JSONDecodeError, OSError):
        return {}


def extract_tokens_and_window(payload: dict) -> tuple[int, int]:
    """Extract token count and model window from hook payload."""
    model_name = payload.get("modelName", "")
    window = get_model_context_window(model_name)
    transcript_path = payload.get("transcriptPath", "")
    if transcript_path and os.path.exists(transcript_path):
        tokens = parse_transcript_tokens(transcript_path)
    else:
        tokens = 0
    return tokens, window


def main():
    """Hook entrypoint executed by Antigravity CLI lifecycle."""
    payload = parse_stdin_payload()
    tokens, window = extract_tokens_and_window(payload)
    response = generate_guard_response(tokens, window)
    print(json.dumps(response))


if __name__ == "__main__":
    main()
