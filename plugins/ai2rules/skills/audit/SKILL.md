---
description: Audit Claude Code on this machine and write a local HTML report — what the agents did, what a governance kernel would have asked or refused, risky settings, secrets in past sessions (never their values), and whether governance is actually on. Read-only; nothing leaves the machine.
argument-hint: "[transcript folders…] [--project DIR]"
disable-model-invocation: true
---

# ai2rules audit

Run the ai2rules audit for the person and show them where the report is. It reads
this machine's Claude Code session history (`~/.claude/projects`) and settings,
changes nothing, and writes one folder: a self-contained `report.html`, `audit.json`,
and a suggested world under `suggested-world/`.

1. Run exactly one command, with a 10-minute timeout (a long history takes a few
   minutes). If you have a Bash tool, use it:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" audit $ARGUMENTS
   ```

   If there is no Bash tool (Windows without Git Bash), use the PowerShell tool:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" audit $ARGUMENTS
   ```

   The first run downloads the `harness` binary once from registry.npmjs.org and
   checks its hash; it says so on stderr. That is the only network access.

2. Relay what the command printed: the path of `report.html` and its summary lines.
   Do not add findings of your own, and do not read secret values out of the
   history: the report deliberately names only their kind, session and line.

3. Show the report. Always give its path as a link to the local file
   (`[report.html](<path>)`), so an app that opens links in its own browser makes it
   one click. Then, if you have a tool that shows the person a local file inside the
   app you run in (in the Claude desktop app, the tool that sends a file to the person
   and renders it; or an app's own browser pane), open `report.html` with it right
   away, without asking: they ran the audit to read it. Open the file itself: never
   upload or publish it, and do not start a server for it, because the report stays
   on this machine. If you have no such tool (a terminal), offer to open it in the
   system browser instead (`start "" "<path>"` on Windows, `open` on macOS,
   `xdg-open` on Linux). Mention that
   `/ai2rules:guard observe` starts recording every decision from now on, and
   `/ai2rules:status` proves whether it is live.

If the command fails, show its error as it is. If it says a harness release is
not on npm yet, explain that the person can set `AI2RULES_HARNESS_FOR_PLUGIN` to a local
build of `harness`.

## If you are Codex, not Claude Code

The same audit reads Codex: its sessions (`~/.codex/sessions` and
`archived_sessions`, compressed ones included), its `config.toml` and its guard.
`${CLAUDE_PLUGIN_ROOT}` is not set for you; the plugin root is the folder two
levels above this `SKILL.md`. Run exactly one command, with `--host codex`, with a
10-minute timeout, and ask to run it outside the sandbox (escalated permissions),
saying why: it writes the report under `~/.codex/ai2rules/audit/`, which the
sandbox keeps read-only, and the first run downloads the `harness` binary once.
The person approves it. On Windows (PowerShell):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<plugin root>/bin/harness.ps1" audit --host codex
```

On macOS and Linux:

```bash
bash "<plugin root>/bin/harness.sh" audit --host codex
```

Then relay what it printed, as in step 2, and show the report as in step 3: the
path as a link to the local file, which the Codex app opens in its own browser with
one click, and the file opened right away if you have a tool that shows the person a
local file inside the app, never uploaded, published or served. Name the ai2rules
guard and status skills instead of the slash commands.
The suggested world is not built for Codex yet; the report says so.
