import type { Register } from 'claude-code'

// `/ai2rules:about` (AI2-240, D125): what is installed and where ai2rules is
// configured, shown with no model turn. A Claude Code mod answers the command
// itself; the facts come from `harness guard about`, run through the same
// bootstrap as every other command, so this file holds no logic of its own.
//
// It hooks no tool call: the plugin still ships no tool hook (D117). Where mods
// do not run (Claude Code before 2.1.287, `disableAllHooks`, a folder not yet
// trusted, an organisation that allows only managed mods), the skill of the
// same name in `skills/about/` answers instead, with a model turn.
//
// No escaped backslash in this file: Claude Code 2.1.318's module parser reads
// one inside a string literal as an unterminated string, and refuses the module.

const NL = String.fromCharCode(10)
const BACKSLASH = String.fromCharCode(92)

// Claude Code draws a command's text as markdown. Read that way, a Windows path
// loses the separator before a dot (the one in front of `.claude`), and a
// backticked command loses its backticks. A fenced block is drawn as written;
// the fence is one backtick longer than the longest run in the text.
//
// The fence has to open a line of its own. Claude Code puts the plugin's name in
// front of the answer, so a fence that starts the text sits in the middle of the
// first line and is not a fence at all (plugin 0.2.1 did that, and the page was
// still read as markdown). So every answer starts with a line of words, `lead`,
// and the block follows it.
const fenced = (lead: string, s: string): string => {
  const runs = s.match(/`+/g) ?? []
  const longest = runs.reduce((n, r) => Math.max(n, r.length), 0)
  const fence = '`'.repeat(Math.max(3, longest + 1))
  return [lead, fence + 'text', s, fence].join(NL)
}

const LEAD = 'what is installed and where it is configured:'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    try {
      await $.command.register({
        name: 'ai2rules:about',
        description:
          'Show the installed plugin and harness versions, the binary, the guard mode, where ai2rules is configured and the decision logs. No model turn.',
      })
    } catch {
      // The skill of the same name already lists the command; the hook below
      // still answers it.
    }
    return next(e)
  })

  on('command.run', { command: 'ai2rules:about' }, async $ => {
    const root = $.plugin.root
    // A drive letter or a backslash in the plugin's folder means Windows.
    const windows = /^[A-Za-z]:/.test(root) || root.includes(BACKSLASH)
    const tail = ['guard', 'about', '--plugin-root', root]
    // PowerShell on Windows: always there, unlike Git Bash, and never WSL's bash.
    const argv = windows
      ? ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', `${root}/bin/harness.ps1`, ...tail]
      : ['bash', `${root}/bin/harness.sh`, ...tail]
    try {
      // The first run downloads the pinned binary once: allow it time.
      const r = await $.process.run(argv, { timeoutMs: 180_000 })
      // The bootstrap's own lines (the one-time install) come first, as they happened.
      const out = [r.stderr.trimEnd(), r.stdout.trimEnd()].filter(s => s !== '').join(NL)
      if (r.exitCode === 0) return { text: fenced(LEAD, out) }
      return {
        text: [
          fenced(LEAD, out),
          '',
          `harness exited with ${r.exitCode}. A harness older than the one that added "guard about" cannot answer this; /ai2rules:status still works.`,
        ].join(NL),
      }
    } catch (err) {
      // A spawn error can carry a path: fenced like the page.
      return { text: fenced(`could not run ${argv[0]}:`, String(err)) }
    }
  })
}
