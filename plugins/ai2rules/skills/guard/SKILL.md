---
description: Turn the ai2rules guard on or off for every Claude Code session on this machine — observe (log every decision, block nothing) or seatbelt (ask before a push, a delete, a credential read, a CI definition or a shell send; web reads are never asked about).
argument-hint: "observe | seatbelt | off"
disable-model-invocation: true
---

# ai2rules guard

The person asked to switch the guard: `$ARGUMENTS`.

If that is not exactly one of `observe`, `seatbelt` or `off`, do not run anything.
Explain the choices in two lines and ask which they want:

- **observe**: the kernel decides every tool call and logs it; nothing is blocked
  and nothing is answered. Good for a week of evidence before enforcing.
- **seatbelt**: asks before what cannot be undone (a push, a delete, a credential
  file, a CI definition, a shell send such as `curl` or `scp`). Web reads are never
  asked about, and on the way out only a recognised credential shape is refused, so
  other data can still leave through a web request. Everything else is left to
  Claude Code.
- **off**: removes the hook. The log is kept for `/ai2rules:audit`.

Otherwise run exactly one command. With a Bash tool:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" guard $ARGUMENTS
```

Without one (Windows without Git Bash), with the PowerShell tool:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" guard $ARGUMENTS
```

While the seatbelt is on, Claude Code asks the person to approve this command
before it runs: the guard does not let an agent change its mode silently.

It edits only the hook entries in the person's own Claude Code `settings.json` and
the files under `~/.claude/ai2rules/plugin/`; everything else in `settings.json` is
kept. Relay what it printed. Then say plainly:

- Claude Code reads its hooks when a session starts, so the change applies to new
  sessions. To prove it is live, start a new session and run `/ai2rules:status`.
- It is a seatbelt, not a cage: the hook lives in the person's own settings, and an
  agent with a shell could edit them.

## If you are Codex, not Claude Code

Everything above is for Claude Code. In Codex the guard goes into
`~/.codex/hooks.json` instead, and only `observe` and `off` exist: a Codex hook
cannot ask, so `seatbelt` is not available there yet. If the person asked for
`seatbelt`, say so and offer `observe`.

`${CLAUDE_PLUGIN_ROOT}` is not set for you. The plugin root is the folder two
levels above this `SKILL.md` (`…/skills/guard/SKILL.md` → `…`). Run exactly one
command, with `--host codex`, and ask to run it outside the sandbox (escalated
permissions), saying why: the first run downloads the `harness` binary once from
registry.npmjs.org, and the command writes `~/.codex/hooks.json` and
`~/.codex/ai2rules/`, which the sandbox keeps read-only. The person approves it.
On Windows (PowerShell):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<plugin root>/bin/harness.ps1" guard observe --host codex
```

On macOS and Linux:

```bash
bash "<plugin root>/bin/harness.sh" guard observe --host codex
```

(`off` instead of `observe` to remove it.) Relay what it printed. Then say plainly:

- **Codex runs the hook only after the person trusts it.** Start `codex`, choose
  *Review hooks* on the "Hooks need review" screen (or type `/hooks`) and trust the
  ai2rules entries; in the desktop app, Settings > Hooks. Until then Codex skips it,
  and `codex exec` does not say so.
- Then start a new session and run the ai2rules status skill there to prove it is
  live.
