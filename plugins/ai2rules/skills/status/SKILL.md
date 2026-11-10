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
