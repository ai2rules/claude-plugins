---
description: Prove whether the ai2rules guard is live in this Claude Code session, and show its recent decisions. The proof is the status command's own tool call passing through the hook.
disable-model-invocation: true
---

# ai2rules status

"Registered" is not "live". This check proves it with its own tool call: the hook
logs a call before the call runs, so the status command looks in the log for the
marker its own command line starts with.

1. Pick a random 8-digit number N yourself (a new one each time; do not reuse one
   from earlier in the conversation).

2. Run exactly this, as ONE command, with N in both places and nothing before
   `echo`. With a Bash tool:

   ```bash
   echo ai2rules-probe-N; bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" guard status --probe N
   ```

   Without one (Windows without Git Bash), with the PowerShell tool:

   ```powershell
   echo ai2rules-probe-N; powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" guard status --probe N
   ```

3. Relay the first line it printed (LIVE, NOT LIVE, REGISTERED or OFF) word for
   word, then the reasons under it and the recent decisions. Do not soften or
   upgrade the verdict: NOT LIVE means this session is not governed, whatever the
   settings say.

## If you are Codex, not Claude Code

`${CLAUDE_PLUGIN_ROOT}` is not set for you: the plugin root is the folder two
levels above this `SKILL.md` (`…/skills/status/SKILL.md` → `…`). Pick N as in
step 1 and run exactly one command, with `--host codex`, inside the sandbox as
usual. It only reads, and the hook sees the command before it runs whether or not
it is sandboxed. On Windows (PowerShell):

```powershell
echo ai2rules-probe-N; powershell -NoProfile -ExecutionPolicy Bypass -File "<plugin root>/bin/harness.ps1" guard status --host codex --probe N
```

On macOS and Linux:

```bash
echo ai2rules-probe-N; bash "<plugin root>/bin/harness.sh" guard status --host codex --probe N
```

If it fails because the `harness` binary is not installed yet, run the ai2rules
guard skill first: it installs the binary outside the sandbox with the person's
approval. Then relay the first line word for word, as in step 3. When it names
the hook as not trusted, tell the person how: start `codex`, choose *Review hooks*
(or type `/hooks`) and trust the ai2rules entries; in the desktop app, Settings >
Hooks.
