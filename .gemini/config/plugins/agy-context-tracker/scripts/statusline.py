#!/usr/bin/env python3
"""Statusline generator for Antigravity CLI.

Mirrors pi's powerline-footer (default preset, omarchy theme):
  model | git branch (+staged *unstaged ?untracked) | context used/total (pct)

Single line, rendered above the prompt input box.
"""

import glob
import hashlib
import json
import math
import os
import sqlite3
import subprocess
import sys
import tempfile
import time

DEFAULT_WINDOW = 1_048_576
PRO_WINDOW = 2_097_152
SETTINGS_FILE = os.path.expanduser("~/.gemini/antigravity-cli/settings.json")
BRAIN_DIR = os.path.expanduser("~/.gemini/antigravity-cli/brain")
CONV_DIR = os.path.expanduser("~/.gemini/antigravity-cli/conversations")
GIT_CACHE_TTL = 5.0  # seconds, mirrors pi's async 1s polling without blocking

# Omarchy palette (matches pi omarchy theme + user's powerline-footer
# theme.json overrides: model=muted, gitClean=muted, gitDirty=warning,
# context=dim/warning/error, separator=borderMuted).
C_MUTED = (133, 133, 133)  # #858585 model, clean git
C_DIM = (94, 94, 94)  # #5e5e5e context normal
C_SEP = (65, 65, 65)  # #414141 borderMuted separators
C_TEXT = (212, 212, 212)  # #d4d4d4
C_WARN = (255, 199, 153)  # #ffc799 context >70%, dirty git, unstaged
C_ERROR = (255, 128, 128)  # #ff8080 context >90%
C_GREEN = (153, 255, 228)  # #99ffe4 staged counts


def get_model_context_window(model_name: str) -> int:
    """Return context window size based on model name."""
    name = (model_name or "").lower()
    if "claude" in name:
        return 200_000
    if "gpt-4" in name:
        return 128_000
    if "pro" in name or "2m" in name:
        return PRO_WINDOW
    return DEFAULT_WINDOW


def clean_model_display_name(raw_name: str) -> str:
    """Format a clean model name for badge display."""
    if not raw_name:
        return "Gemini 3.8 Flash"
    name = raw_name.split("(")[0].strip()
    if name.lower().startswith("gemini-"):
        parts = name.split("-")
        return f"Gemini {parts[1]} {parts[2].capitalize()}"
    return name


def format_token_count(tokens: int) -> str:
    """Format token count with k or M suffix."""
    if tokens >= 1_000_000:
        return f"{tokens / 1_000_000:.1f}M"
    if tokens >= 1_000:
        return f"{tokens / 1_000:.1f}k"
    return str(max(0, tokens))


def is_plain_mode() -> bool:
    """Check if color styling should be suppressed."""
    return bool(os.environ.get("NO_COLOR") or os.environ.get("AGY_PLAIN_STATUS"))


def has_nerd_fonts() -> bool:
    """Nerd Font heuristic, same as pi-powerline-footer."""
    if os.environ.get("POWERLINE_NERD_FONTS") == "1":
        return True
    if os.environ.get("POWERLINE_NERD_FONTS") == "0":
        return False
    if os.environ.get("GHOSTTY_RESOURCES_DIR"):
        return True
    term = (os.environ.get("TERM_PROGRAM") or os.environ.get("TERM") or "").lower()
    return any(
        t in term for t in ("iterm", "wezterm", "kitty", "ghostty", "alacritty", "kaku")
    )


def _ansi(rgb: tuple[int, int, int], text: str, bold: bool = False) -> str:
    r, g, b = rgb
    return f"\033[38;2;{r};{g};{b}m{'\033[1m' if bold else ''}{text}\033[0m"


def resolve_cwd(stdin_data: dict) -> str:
    """Best-effort working directory from hook payload, else process cwd."""
    for key in (
        "cwd",
        "workingDirectory",
        "working_directory",
        "currentDirectory",
        "projectDir",
        "dir",
        "sessionCwd",
        "workspaceRoot",
    ):
        val = stdin_data.get(key)
        if isinstance(val, str) and val and os.path.isdir(val):
            return val
    try:
        return os.getcwd()
    except OSError:
        return os.path.expanduser("~")


def _git_cache_path(cwd: str) -> str:
    digest = hashlib.sha256(cwd.encode("utf-8", "ignore")).hexdigest()[:16]
    return os.path.join(tempfile.gettempdir(), f"agy-statusline-git-{digest}.json")


def get_git_info(cwd: str) -> dict | None:
    """Branch + staged/unstaged/untracked counts, file-cached for GIT_CACHE_TTL.

    Returns None when not inside a git repo (or git missing/slow).
    """
    cache_path = _git_cache_path(cwd)
    try:
        if (
            os.path.exists(cache_path)
            and time.time() - os.path.getmtime(cache_path) < GIT_CACHE_TTL
        ):
            with open(cache_path, encoding="utf-8") as f:
                data = json.load(f)
            return data if isinstance(data, dict) and data.get("branch") else None
    except (OSError, json.JSONDecodeError, ValueError):
        pass

    info: dict | None = None
    try:
        top = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=1,
            check=False,
        )
        if top.returncode != 0:
            return None
        branch = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=1,
            check=False,
        )
        name = branch.stdout.strip() if branch.returncode == 0 else ""
        if not name:
            return None
        staged = unstaged = untracked = 0
        st = subprocess.run(
            ["git", "status", "--porcelain=v1", "--untracked-files=normal"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=1,
            check=False,
        )
        if st.returncode == 0:
            for line in st.stdout.splitlines():
                if not line or len(line) < 2:
                    continue
                x, y = line[0], line[1]
                if x == "?" and y == "?":
                    untracked += 1
                else:
                    if x not in (" ", "?"):
                        staged += 1
                    if y not in (" ", "?"):
                        unstaged += 1
        info = {
            "branch": name,
            "staged": staged,
            "unstaged": unstaged,
            "untracked": untracked,
        }
        try:
            with open(cache_path, "w", encoding="utf-8") as f:
                json.dump(info, f)
        except OSError:
            pass
    except (OSError, subprocess.SubprocessError, ValueError):
        return None
    return info


def format_git_segment(git: dict | None, styled: bool) -> str:
    """Pi-style git segment: branch icon + name, dirty-colored, with * + ? flags."""
    if not git or not git.get("branch"):
        return ""
    branch = git["branch"]
    dirty = bool(git.get("staged") or git.get("unstaged") or git.get("untracked"))
    icon = "\uf126 " if has_nerd_fonts() else "⎇ "
    if not styled or is_plain_mode():
        flags = ""
        if git.get("unstaged"):
            flags += f" *{git['unstaged']}"
        if git.get("staged"):
            flags += f" +{git['staged']}"
        if git.get("untracked"):
            flags += f" ?{git['untracked']}"
        return f"{icon}{branch}{flags}"
    branch_rgb = C_WARN if dirty else C_MUTED
    seg = _ansi(branch_rgb, f"{icon}{branch}", bold=True)
    if git.get("unstaged"):
        seg += f" {_ansi(C_WARN, f'*{git['unstaged']}')}"
    if git.get("staged"):
        seg += f" {_ansi(C_GREEN, f'+{git['staged']}')}"
    if git.get("untracked"):
        seg += f" {_ansi(C_MUTED, f'?{git['untracked']}')}"
    return seg


def format_context_segment(tokens: int, window: int, styled: bool = True) -> str:
    """Pi-style context segment: used/total (pct), threshold-colored."""
    used_str = format_token_count(tokens)
    total_str = format_token_count(window)
    pct = (tokens / window * 100.0) if window > 0 else 0.0
    icon = "\uf1c0 " if has_nerd_fonts() else "◫ "
    text = f"{used_str}/{total_str} ({pct:.1f}%)"
    if not styled or is_plain_mode():
        return f"{icon}{text}" if icon.strip() else text
    if pct > 90.0:
        rgb = C_ERROR  # pi contextError
    elif pct > 70.0:
        rgb = C_WARN  # pi contextWarn
    else:
        rgb = C_DIM  # pi context
    return _ansi(rgb, f"{icon}{text}", bold=pct > 70.0)


def format_model_segment(model_name: str, styled: bool = True) -> str:
    """Pi-style model segment: muted display name."""
    display = clean_model_display_name(model_name)
    if not styled or is_plain_mode():
        return f"[{display}]"
    return _ansi(C_MUTED, f"[{display}]", bold=True)


def format_status_badge(
    model_name: str,
    tokens: int,
    window: int,
    styled: bool = True,
    git: dict | None = None,
    cwd_label: str = "",
) -> str:
    """Format pi-powerline-style statusline: model | git | context (| dir fallback)."""
    if not styled or is_plain_mode():
        parts = [format_model_segment(model_name, styled=False)]
        git_seg = format_git_segment(git, styled=False)
        if git_seg:
            parts.append(git_seg)
        elif cwd_label:
            parts.append(cwd_label)
        parts.append(
            f"{format_token_count(tokens)} / {format_token_count(window)} "
            f"({(tokens / window * 100.0) if window > 0 else 0.0:.1f}%)"
        )
        return " | ".join(parts)

    sep = _ansi(C_SEP, " | ")
    parts = [format_model_segment(model_name)]
    git_seg = format_git_segment(git, styled=True)
    if git_seg:
        parts.append(git_seg)
    elif cwd_label:
        parts.append(_ansi(C_DIM, cwd_label))
    parts.append(format_context_segment(tokens, window))
    return sep.join(parts)


def extract_step_tokens(step: dict) -> tuple[int, int]:
    """Extract explicit tokens or character count from a step dictionary."""
    try:
        explicit = step.get("total_tokens") or step.get("tokens") or 0
        chars = len(step.get("content", "") or "")
        chars += len(step.get("thinking", "") or "")
        if step.get("tool_calls"):
            chars += len(json.dumps(step["tool_calls"]))
        return int(explicit), chars
    except (TypeError, ValueError):
        return 0, 0


def parse_transcript_tokens(file_path: str) -> int:
    """Calculate total tokens from a JSONL transcript file."""
    if not os.path.exists(file_path):
        return 0
    total_chars, max_explicit = 0, 0
    try:
        with open(file_path, encoding="utf-8", errors="ignore") as f:
            for line in f:
                if not line.strip():
                    continue
                try:
                    exp, ch = extract_step_tokens(json.loads(line))
                    max_explicit = max(max_explicit, exp)
                    total_chars += ch
                except json.JSONDecodeError:
                    total_chars += len(line)
    except OSError:
        return max(max_explicit, math.ceil(total_chars / 4.0))
    return max(max_explicit, math.ceil(total_chars / 4.0))


def estimate_sqlite_tokens(db_path: str) -> int:
    """Estimate token count from SQLite conversation database."""
    if not os.path.exists(db_path):
        return 0
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        cur.execute("SELECT SUM(length(step_payload)) FROM steps")
        row = cur.fetchone()
        conn.close()
        total_bytes = row[0] if (row and row[0]) else 0
        return math.ceil(total_bytes / 4.0)
    except sqlite3.Error:
        return 0


def find_latest_file(pattern: str) -> str | None:
    """Find most recently modified file matching glob pattern."""
    files = glob.glob(pattern)
    if not files:
        return None
    return max(files, key=os.path.getmtime)


def read_active_model_from_settings() -> str:
    """Read active model configured in settings.json."""
    if not os.path.exists(SETTINGS_FILE):
        return "Gemini 3.8 Flash"
    try:
        with open(SETTINGS_FILE, encoding="utf-8") as f:
            data = json.load(f)
            return data.get("model", "Gemini 3.8 Flash")
    except (json.JSONDecodeError, OSError):
        return "Gemini 3.8 Flash"


def resolve_active_file() -> tuple[str, str]:
    """Locate the active transcript.jsonl or SQLite db path."""
    latest_transcript = find_latest_file(
        os.path.join(BRAIN_DIR, "*", ".system_generated", "logs", "transcript.jsonl")
    )
    if latest_transcript:
        return "jsonl", latest_transcript
    latest_db = find_latest_file(os.path.join(CONV_DIR, "*.db"))
    if latest_db:
        return "sqlite", latest_db
    return "none", ""


def resolve_active_context(stdin_data: dict) -> tuple[str, int, int]:
    """Determine model name, token count, and context window."""
    model_name = stdin_data.get("modelName") or read_active_model_from_settings()
    window = get_model_context_window(model_name)
    transcript_path = stdin_data.get("transcriptPath")
    if transcript_path and os.path.exists(transcript_path):
        tokens = parse_transcript_tokens(transcript_path)
        return model_name, tokens, window
    file_type, path = resolve_active_file()
    if file_type == "jsonl":
        tokens = parse_transcript_tokens(path)
    elif file_type == "sqlite":
        tokens = estimate_sqlite_tokens(path)
    else:
        tokens = 0
    return model_name, tokens, window


def parse_stdin_safely() -> dict:
    """Parse stdin JSON safely if available."""
    if sys.stdin.isatty():
        return {}
    try:
        raw = sys.stdin.read().strip()
        return json.loads(raw) if raw else {}
    except (json.JSONDecodeError, OSError):
        return {}


def main():
    """Main entrypoint for CLI statusline output."""
    stdin_data = parse_stdin_safely()
    model_name, tokens, window = resolve_active_context(stdin_data)
    cwd = resolve_cwd(stdin_data)
    git = get_git_info(cwd)
    cwd_label = "" if git else (os.path.basename(os.path.abspath(cwd)) or cwd)
    print(format_status_badge(model_name, tokens, window, git=git, cwd_label=cwd_label))


if __name__ == "__main__":
    main()
