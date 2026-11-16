---
description: Open the ai2rules policy console for this machine: a local page whose Allow / Ask / Off switches change what the agent may do on its next tool call, with a live feed of the kernel's decisions. It runs in the background on http://127.0.0.1:8790/, the address a fleet centre reaches it through.
argument-hint: "[stop]"
disable-model-invocation: true
---

# ai2rules console

The person asked for the policy console: a page on this machine, served on
`127.0.0.1:8790` only, that edits the world the governing hook reads and shows the
hook's decisions as they come. If this machine is connected to a fleet centre
(`/ai2rules:connect`), the centre reaches the same page through the connector.

If `$ARGUMENTS` is the word `stop`, go straight to "Stopping" below. Otherwise run
exactly one command. With a Bash tool:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" console --background
```

Without one (Windows without Git Bash), with the PowerShell tool:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" console --background
```

It starts the console for the folder this session works in, as a process of its
own, and returns once the page answers. Read its lines and take the first that fits:

- It says it "replaced the console": a console of an older harness ran on the port
  (from an earlier release, started before the plugin was updated). It was stopped and
  one of this release runs in its place, on the same world. Tell the person so, naming
  both releases as the line does, then go on as the next point says.
- It says the console "runs in the background": tell the person to open
  <http://127.0.0.1:8790/> in their browser. Relay the line naming the world, in
  its words: it says whose world the switches change (this project's own, or the
  plugin's guard world, which applies to every session of this user and which a
  `/ai2rules:guard` switch rewrites). With the guard's world it adds a line on
  what binds; relay that too, word for word: in observe mode nothing is blocked,
  and in seatbelt a tool switched Off is refused, so No shell binds (a seatbelt an
  older harness set up says it leaves Off to Claude Code until an update or
  `/ai2rules:guard seatbelt` writes its answers). Emergency stop binds in both
  modes: until Resume, every action that changes anything is refused, and reading
  goes on. Say that a change applies at the agent's next tool
  call, and that the console runs until `/ai2rules:console stop` or a restart of
  the computer.
- It says a console "already runs": relay the address, the harness release it names (if
  it names one) and the world it names. If
  that world is not the one the person means (another project's), offer to stop it
  and start one here: on yes, run the stop below, then the start above again. A console
  with no world names "none" and its project instead: if that project is not this
  folder, make the same offer.
- It says the world is "none": the guard is off and this folder has no world of its
  own, so the console runs for its Audit view only (D154). Tell the person to open
  <http://127.0.0.1:8790/>: it opens on Audit, where "Run audit" reads what the agents
  on this machine have done, and changes nothing. To set what the agent may do there
  are two ways; let them choose: the plugin's guard for every session of this user
  (`/ai2rules:guard observe` logs and blocks nothing, `/ai2rules:guard seatbelt` asks
  before what cannot be undone), or a world of this project's own (`harness init` in a
  terminal here). The page shows that policy as soon as there is one, with no restart.
  Run neither yourself.
- It says it "cannot listen" on the port: another program holds 8790. Relay it.
- Anything else: relay it word for word and stop.

The console only edits a world. Whether a switch binds depends on the hook that
reads it, and the page itself does not show the guard's mode: say what the
command printed about it. Do not claim the agent is stopped from something
because a switch is Off; `/ai2rules:status` proves whether the hook is live in
this session.

## Stopping

Only when `$ARGUMENTS` is `stop`. Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" console --stop
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" console --stop
```

- It says it "stopped the console": tell the person the page is closed. The world
  and the hook are unchanged: the agent keeps working under the policy as it was
  left. A fleet centre shows this machine's console as not running until it is
  started again.
- It says "no console runs": there was nothing to stop.
- Anything else: relay it word for word.

## If you are Codex, not Claude Code

Run nothing. Tell the person to start it in a terminal of their own, in the project
folder: `harness console` (it keeps that terminal), or `harness console
--background` (it returns, and `harness console --stop` ends it).
