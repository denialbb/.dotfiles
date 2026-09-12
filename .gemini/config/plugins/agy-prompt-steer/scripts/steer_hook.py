#!/usr/bin/env python3
"""PreInvocation hook for agy-prompt-steer plugin.

Detects live user input typed into the agy prompt during active turns
and injects them as high-priority user steering steps.
"""

import json
import os
import sys
from pathlib import Path


def get_history_path() -> Path:
    custom = os.environ.get("AGY_HISTORY_PATH")
    if custom:
        return Path(custom)
    return Path.home() / ".gemini" / "antigravity-cli" / "history.jsonl"


def get_state_path(conv_id: str) -> Path:
    state_dir = Path(os.environ.get("AGY_STEER_STATE_DIR", "/tmp"))
    return state_dir / f"agy-steer-state-{conv_id}.json"


def read_state(state_path: Path) -> dict:
    if not state_path.is_file():
        return {}
    try:
        return json.loads(state_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def save_state(state_path: Path, state: dict) -> None:
    try:
        state_path.parent.mkdir(parents=True, exist_ok=True)
        temp_file = state_path.with_suffix(".tmp")
        temp_file.write_text(json.dumps(state, indent=2), encoding="utf-8")
        temp_file.replace(state_path)
    except OSError:
        pass


def clean_message_text(raw_text: str) -> str:
    text = raw_text.strip()
    if text.startswith("/steer "):
        return text[7:].strip()
    if text.startswith("/steer\t"):
        return text[7:].strip()
    return text


def is_steering_message(entry: dict) -> bool:
    text = entry.get("display", "").strip()
    if not text:
        return False
    if text.startswith("/steer"):
        return True
    return entry.get("type") != "slash_command"


def read_history_entries(history_path: Path, conv_id: str) -> list[dict]:
    if not history_path.is_file():
        return []
    entries = []
    try:
        with history_path.open("r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    item = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if item.get("conversationId") == conv_id:
                    entries.append(item)
    except OSError:
        return []
    return entries


def normalize_user_text(raw: str) -> str:
    text = raw.strip()
    if "<USER_REQUEST>" in text:
        start = text.find("<USER_REQUEST>") + len("<USER_REQUEST>")
        end = text.find("</USER_REQUEST>", start)
        if end != -1:
            text = text[start:end].strip()
    return text


def read_transcript_user_inputs(transcript_path: Path | None) -> set[str]:
    if not transcript_path or not transcript_path.is_file():
        return set()
    seen = set()
    try:
        with transcript_path.open("r", encoding="utf-8", errors="replace") as f:
            for line in f:
                try:
                    data = json.loads(line)
                    if data.get("type") == "USER_INPUT":
                        content = data.get("content", "")
                        if content:
                            seen.add(content.strip())
                            seen.add(normalize_user_text(content))
                except json.JSONDecodeError:
                    continue
    except OSError:
        return set()
    return seen


def extract_transcript_messages(hook_input: dict) -> set[str] | None:
    raw = hook_input.get("transcriptPath")
    return read_transcript_user_inputs(Path(raw)) if raw else None


def is_already_in_transcript(text: str, transcript_msgs: set[str] | None) -> bool:
    if not transcript_msgs:
        return False
    clean = clean_message_text(text)
    norm = normalize_user_text(text)
    for msg in transcript_msgs:
        if clean == msg or norm == msg or norm in msg or msg in norm:
            return True
    return False


def find_unseen_inputs(
    entries: list[dict],
    last_seen_ts: int,
    transcript_msgs: set[str] | None = None,
) -> tuple[list[dict], int]:
    unseen = []
    max_ts = last_seen_ts
    for e in entries:
        ts = e.get("timestamp", 0)
        if ts > max_ts and is_steering_message(e):
            text = e.get("display", "").strip()
            if is_already_in_transcript(text, transcript_msgs):
                max_ts = max(max_ts, ts)
                continue
            unseen.append(e)
            max_ts = max(max_ts, ts)
    return unseen, max_ts


def format_inject_steps(messages: list[str]) -> list[dict]:
    return [{"userMessage": msg} for msg in messages]


def purge_history_entries(history_path: Path, conv_id: str, timestamps: set[int]) -> None:
    """Remove consumed entries from history.jsonl so they are not reprocessed."""
    if not history_path.is_file() or not timestamps:
        return
    try:
        lines = []
        with history_path.open("r", encoding="utf-8", errors="replace") as f:
            for line in f:
                stripped = line.strip()
                if not stripped:
                    continue
                try:
                    item = json.loads(stripped)
                    if item.get("conversationId") == conv_id and item.get("timestamp") in timestamps:
                        continue
                except json.JSONDecodeError:
                    pass
                lines.append(stripped)
        temp_file = history_path.with_suffix(".tmp")
        temp_file.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
        temp_file.replace(history_path)
    except OSError:
        pass


def check_turn_duplicate(
    transcript_msgs: set[str] | None,
    injected_prompts: list[str],
) -> tuple[str | None, list[str]]:
    """Check if current turn request was already executed via live steering."""
    if not transcript_msgs or not injected_prompts:
        return None, injected_prompts
    for prompt in injected_prompts:
        clean = clean_message_text(prompt)
        norm = normalize_user_text(prompt)
        for msg in transcript_msgs:
            if clean == msg or norm == msg or norm in msg or msg in norm:
                remaining = [p for p in injected_prompts if p != prompt]
                return prompt, remaining
    return None, injected_prompts


def process_steering(
    hook_input: dict,
    history_path: Path | None = None,
    state_path: Path | None = None,
) -> dict:
    conv_id = hook_input.get("conversationId")
    if not conv_id:
        return {"injectSteps": []}

    h_path = history_path or get_history_path()
    s_path = state_path or get_state_path(conv_id)
    state = read_state(s_path)
    last_seen_ts = state.get("last_seen_timestamp", 0)
    injected_prompts = list(state.get("injected_prompts", []))
    transcript_msgs = extract_transcript_messages(hook_input)
    inv_num = hook_input.get("invocationNum", 1)

    # Check if a turn-end popped duplicate arrived
    if inv_num <= 1:
        dup_prompt, remaining = check_turn_duplicate(transcript_msgs, injected_prompts)
        if dup_prompt:
            state["injected_prompts"] = remaining
            save_state(s_path, state)
            return {
                "injectSteps": [
                    {
                        "ephemeralMessage": (
                            f"[STEERING ALREADY APPLIED]: The instruction '{dup_prompt}' was already injected "
                            "and executed mid-turn. Output a concise 1-line acknowledgment and finish."
                        )
                    }
                ]
            }

    entries = read_history_entries(h_path, conv_id)
    unseen, new_max_ts = find_unseen_inputs(entries, last_seen_ts, transcript_msgs)

    if unseen:
        consumed_ts = {e.get("timestamp") for e in unseen if e.get("timestamp")}
        purge_history_entries(h_path, conv_id, consumed_ts)
        new_prompts = [clean_message_text(e.get("display", "")) for e in unseen]
        injected_prompts.extend(new_prompts)
        state["injected_prompts"] = injected_prompts
        state["last_seen_timestamp"] = new_max_ts
        save_state(s_path, state)
        return {"injectSteps": format_inject_steps(new_prompts)}

    if new_max_ts > last_seen_ts:
        state["last_seen_timestamp"] = new_max_ts
        save_state(s_path, state)

    return {"injectSteps": []}


def main() -> None:
    try:
        hook_input = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError, ValueError):
        hook_input = {}
    result = process_steering(hook_input)
    sys.stdout.write(json.dumps(result) + "\n")
    sys.stdout.flush()


if __name__ == "__main__":
    main()
