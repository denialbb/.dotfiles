// tmux-agent-indicator plugin for OpenCode.
// Install to ~/.config/opencode/plugins/ or .opencode/plugins/ (project-level).
// Tracks session state and calls agent-state.sh to update tmux pane visuals.

export const TmuxAgentIndicator = async ({ $ }) => {
  const dir = process.env.TMUX_AGENT_INDICATOR_DIR
    || `${process.env.HOME}/.tmux/plugins/tmux-agent-indicator`;
  const script = `${process.env.HOME}/.local/bin/agent-notify.sh`;

  let lastState = "off";
  let idleAt = 0;

  const setState = async (state, tool = "", cmd = "") => {
    if (state === lastState && state !== "needs-input") return;
    lastState = state;
    try {
      if (state === "running") {
        await $`bash ${script} opencode off`;
      }
      if (state === "needs-input") {
        await $`bash ${script} opencode ${state} ${tool} ${cmd}`;
      } else {
        await $`bash ${script} opencode ${state}`;
      }
    } catch {
      // non-fatal: tmux may not be available
    }
  };

  return {
    event: async ({ event }) => {
      if (event.type === "session.status"
          && event.properties.status.type === "busy") {
        // Guard: don't override done/error if idle fired recently (race condition)
        if (Date.now() - idleAt < 2000) return;
        await setState("running");
      }

      if (event.type === "permission.updated"
          || event.type === "permission.asked") {
        const tool = event.properties?.tool?.type || "unknown";
        const command = event.properties?.tool?.command || event.properties?.reason || "";
        await setState("needs-input", tool, command);
      }

      if (event.type === "session.idle") {
        idleAt = Date.now();
        await setState("done");
      }

      if (event.type === "session.error") {
        idleAt = Date.now();
        await setState("done");
      }
    },
    "permission.ask": async (event) => {
      const tool = event?.tool || "unknown";
      const command = event?.command || event?.reason || "";
      await setState("needs-input", tool, command);
    },
    "tool.execute.before": async (input) => {
      if (input.tool === "question") {
        await setState("needs-input", input.tool, input.question || "");
      }
    },
  };
};
