---
description: List the commands of the ai2rules plugin and what each one does. Runs nothing.
disable-model-invocation: true
---

# ai2rules help

Where Claude Code runs the plugin's mod (`hooks/commands.ts`, Claude Code 2.1.287 and
later), the mod answers `/ai2rules:help` itself and you never see this. You are
reading it because mods do not run here, so the same page comes through you.

Run nothing. Show the person exactly this page, in a code block, and add nothing:
no summary, no advice.

```text
/ai2rules:audit [folders] [--project DIR]
    Read the Claude Code history and settings of this machine and write a
    local HTML report: what the agents did, what a governance kernel would
    have asked or refused, risky settings, and secrets in past sessions
    (their kind and place, never their values). It changes nothing else.

/ai2rules:guard observe | seatbelt | off
    Turn the guard on or off for every Claude Code session on this machine.
      observe   log every decision; block nothing
      seatbelt  ask before what cannot be undone: a push, a delete, a
                credential read, a CI definition, a shell send (curl, scp)
      off       remove the hook; the log is kept
    A change applies to sessions started after it.

/ai2rules:status
    Prove whether the guard is live in this session, and show its recent
    decisions.

/ai2rules:about
    What is installed and where ai2rules is configured: versions, the
    binary, the guard mode, the settings files, the decision logs.

/ai2rules:console [stop]
    Open the policy console on http://127.0.0.1:8790/: Allow / Ask / Off
    switches for what the agent may do, and a live feed of decisions. It
    runs in the background; stop closes it. The world stays as you left it.

/ai2rules:connect [email | stop]
    Connect this machine to your organisation fleet centre, if it has one:
    your work email, then the link the centre mails you to confirm. No
    key or password. The centre can show and set policy; decisions stay
    on this machine. stop ends the connection here; the machine stays
    enrolled, and only your admin disconnects it for good.

/ai2rules:help
    This page.

A usual start: audit, then guard observe, then status in a new session.
Everything runs on this machine. The only network access is the download
of the pinned harness binary from registry.npmjs.org (on the first run,
and again when a plugin update pins another version), and connect.
More: https://github.com/ai2rules/claude-plugins
```

## If you are Codex, not Claude Code

The slash commands on that page are Claude Code's. Do not show the page. Tell the
person that in Codex the same things are the ai2rules skills: audit, guard
(`observe` and `off` only: a Codex hook cannot ask, so there is no `seatbelt`
there yet) and status; `about` has no Codex form yet, `connect` needs
Claude Code's plugin configuration, and the console is `harness console` in a
terminal.
