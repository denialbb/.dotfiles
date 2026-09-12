# Live Prompt Steering Directives

When you receive an injected user message beginning with `[LIVE USER STEERING]:`, the user has actively typed a directive into the Antigravity prompt while you were working.

## Execution Rules
1. **Absolute Priority**: Live steering directives take precedence over previous instructions, prior plans, or in-flight intentions.
2. **Immediate Pivot**: If your current plan contradicts the steering message, immediately cease following the old approach and align your next steps with the steering directive.
3. **No Dismissal**: Never ignore or defer a live steering instruction. Acknowledge and integrate the correction into your reasoning and subsequent tool calls.
4. **Clarification**: If the steering directive is ambiguous in the context of the current task, ask a clarifying question or take the safest non-destructive interpretation that honors the intent.
