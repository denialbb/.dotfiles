# Context Awareness and Budget Management Rules

## 1. Context Budget Monitoring
- Monitor context window usage indicators emitted by `agy-context-tracker`.
- Context window baseline: 1,048,576 tokens (Gemini 3.8/1.5 Flash) or 2,097,152 tokens (Gemini Pro).
- If an ephemeral warning message indicates context usage exceeds 80%:
  - Stop launching exploratory subagents or reading unbounded files.
  - Summarize completed work and outstanding tasks immediately.
  - Recommend or execute `/handoff` to preserve session continuity before reaching context saturation.

## 2. Token Conservation Discipline
- Prefer targeted reads (`grep_search`, `find_by_name`, sliced `view_file` ranges) over whole-directory dumps or reading large binary/log files.
- Keep tool responses focused; avoid echoing large outputs back into conversation turns.
- Adopt concise communication style to maximize available reasoning tokens.
