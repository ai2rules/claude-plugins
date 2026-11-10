---
description: Show what ai2rules has installed and where it is configured — plugin and harness versions, the binary, the guard mode, the settings files that register an ai2rules hook, and the decision logs. Read-only.
disable-model-invocation: true
---

# ai2rules about

Where Claude Code runs the plugin's mod (`hooks/commands.ts`, Claude Code 2.1.287 and
later), the mod answers `/ai2rules:about` itself and you never see this. You are
reading it because mods do not run here, so the same facts come through you.

Run exactly one command. With a Bash tool:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" guard about --plugin-root "${CLAUDE_PLUGIN_ROOT}"
```

Without one (Windows without Git Bash), with the PowerShell tool:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" guard about --plugin-root "${CLAUDE_PLUGIN_ROOT}"
```

Relay what it printed, verbatim, in a code block. Add nothing: no summary, no
advice. If it failed, show the error as it is.

## If you are Codex, not Claude Code

This page describes the Claude Code plugin and its guard; `guard about --host codex`
is refused. Do not run anything. Tell the person that `/ai2rules:status` (with
`--host codex`, as that skill says) shows the Codex guard, and that `about` has no
Codex form yet.
