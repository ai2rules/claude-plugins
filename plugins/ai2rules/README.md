# ai2rules for Claude Code

Audit what your agent did, then put a seatbelt on it. Everything runs on your
machine; nothing is sent anywhere.

```text
/plugin marketplace add ai2rules/claude-plugins
/plugin install ai2rules@ai2rules
```

When Claude Code asks where to install it, pick **your user account** (user
scope), not a project. The plugin audits and guards the whole machine, so it
belongs to every session you open. A local or project install covers only the one
folder it was made in, and every git worktree is a separate folder: a session
opened in another folder, or in a fresh worktree of the same repository, does not
have the commands.

| Command | What it does | What it writes |
|---|---|---|
| `/ai2rules:audit` | Reads your Claude Code history and settings and writes a local report: what the agents did, what a governance kernel would have asked or refused, risky settings, secrets in past sessions (their kind and place, never the value), whether governance is on, how broad your policy is, and a policy drafted from how you actually work. | `~/.claude/ai2rules/audit/<time>/` |
| `/ai2rules:guard observe` | Every tool call is decided and logged. Nothing is blocked. | the hook entries in `~/.claude/settings.json`, `~/.claude/ai2rules/plugin/` |
| `/ai2rules:guard seatbelt` | Claude Code asks before a push, a delete, a credential read, a CI definition or a shell send (`curl`, `scp`, `gh pr create`, mail). Web reads are never asked about, and on the way out only a recognised credential shape is refused. Nothing else changes. | same |
| `/ai2rules:guard off` | Removes the hook. The log stays for the audit. | same |
| `/ai2rules:status` | Proves whether the hook is live in this session: its own tool call must pass through the hook. Shows recent decisions, and names any other ai2rules hook registered for the session (one `harness init` put in a project, your user settings or the managed policy), with whether this call passed through it. | nothing |

The guard is off until you turn it on, and a new setting applies to sessions
started after it.

## The one download

The commands run `harness`, the ai2rules kernel, a single binary. The first command
you run downloads it once from the npm registry
(`ai2rules-harness-<platform>-<version>.tgz`), checks its SHA-512 against
`binaries.lock` in this plugin, and installs it in `~/.claude/ai2rules/plugin/bin/`.
A package with another hash is refused. No Node.js or npm is needed: Git Bash, Linux
and macOS use `curl`, `tar` and `sha512sum`; Windows without Git Bash uses
PowerShell and the `tar.exe` Windows ships.

To use a binary of your own instead, set `AI2RULES_HARNESS` to its absolute path.

## Honest limits

- **A seatbelt, not a cage.** The hook lives in your own settings. The seatbelt
  refuses an agent's file edit to them, but an agent with a shell can reach them in
  ways a pattern list does not foresee. For a hook a user cannot remove, an
  administrator uses `harness init --managed`.
- **Shell commands are classified by pattern.** The kernel does not see what runs
  inside a process.
- **Data can leave through a web read.** `WebFetch` and `WebSearch` are never asked
  about, so a page that injects instructions can make the agent put file contents, a
  password with no token shape, or an encoded token into a URL or a search, unasked.
  Only a credential the session read, in a recognised shape, is refused. This is a
  deliberate trade: a seatbelt that refused every push after any web read was unusable.
- **MCP tools that send (mail, chat) are not named yet.** They go to Claude Code's
  own permission prompt.
- **The audit reads history, which shows only what happened.** A clean history says
  nothing about permissions never used; the report's settings and policy checks
  cover that side.

License: MIT OR Apache-2.0. More at [ai2rules.dev](https://ai2rules.dev).
