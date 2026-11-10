# ai2rules plugins for Claude Code

```text
/plugin marketplace add ai2rules/claude-plugins
/plugin install ai2rules@ai2rules
```

| Plugin | What it is |
|---|---|
| [`ai2rules`](plugins/ai2rules/) | A local audit of how Claude Code has been used on this machine, and a hook that logs every decision or asks before what cannot be undone. |

The plugins hold no kernel code: they run `harness`, a single binary published on
npm, downloaded once and checked against the hash pinned in each plugin's
`binaries.lock`.

This directory is the source of the public repository `ai2rules/claude-plugins`;
the copy there is made from it, never edited by hand.

License: MIT OR Apache-2.0.
