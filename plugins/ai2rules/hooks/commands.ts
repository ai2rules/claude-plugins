import type { Register } from 'claude-code'

// The plugin's one hooks module (Claude Code takes one per plugin): it answers
// two of the plugin's commands itself, with no model turn, and hooks no tool
// call, so the plugin still ships no tool hook (D117).
//
// `/ai2rules:about` (AI2-240, D125): what is installed and where ai2rules is
// configured. The facts come from `harness guard about`, run through the same
// bootstrap as every other command, so this file holds no logic of its own.
//
// `/ai2rules:help` (AI2-246): the plugin's commands on one page. Fixed text:
// it runs nothing.
//
// Where mods do not run (Claude Code before 2.1.287, `disableAllHooks`, a folder
// not yet trusted, an organisation that allows only managed mods), the skills of
// the same names in `skills/about/` and `skills/help/` answer instead, with a
// model turn.
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

// The help page. A test keeps the page in `skills/help/SKILL.md` equal to it and
// fails when a command of the plugin is missing from it. No single quote inside
// a line: the test reads the lines as plain single-quoted strings.
// help:begin
const PAGE = [
  '/ai2rules:audit [folders] [--project DIR]',
  '    Read the Claude Code history and settings of this machine and write a',
  '    local HTML report: what the agents did, what a governance kernel would',
  '    have asked or refused, risky settings, and secrets in past sessions',
  '    (their kind and place, never their values). It changes nothing else.',
  '',
  '/ai2rules:guard observe | seatbelt | off',
  '    Turn the guard on or off for every Claude Code session on this machine.',
  '      observe   log every decision; block nothing',
  '      seatbelt  ask before what cannot be undone: a push, a delete, a',
  '                credential read, a CI definition, a shell send (curl, scp)',
  '      off       remove the hook; the log is kept',
  '    A change applies to sessions started after it.',
  '',
  '/ai2rules:status',
  '    Prove whether the guard is live in this session, and show its recent',
  '    decisions.',
  '',
  '/ai2rules:about',
  '    What is installed and where ai2rules is configured: versions, the',
  '    binary, the guard mode, the settings files, the decision logs.',
  '',
  '/ai2rules:connect [email | stop]',
  '    Connect this machine to your organisation fleet centre, if it has one:',
  '    your work email, then the six-digit code your admin reads to you. No',
  '    key or password. The centre can show and set policy; decisions stay',
  '    on this machine. stop ends the connection here; the machine stays',
  '    enrolled, and only your admin disconnects it for good.',
  '',
  '/ai2rules:help',
  '    This page.',
  '',
  'A usual start: audit, then guard observe, then status in a new session.',
  'Everything runs on this machine. The only network access is the download',
  'of the pinned harness binary from registry.npmjs.org (on the first run,',
  'and again when a plugin update pins another version), and connect.',
  'More: https://github.com/ai2rules/claude-plugins',
]
// help:end
const HELP_LEAD = 'the commands of this plugin:'

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
    try {
      await $.command.register({
        name: 'ai2rules:help',
        description: 'List the commands of the ai2rules plugin and what each one does. No model turn.',
      })
    } catch {
      // As above: the skill lists it, the hook below answers it.
    }
    return next(e)
  })

  on('command.run', { command: 'ai2rules:help' }, async () => {
    return { text: fenced(HELP_LEAD, PAGE.join(NL)) }
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
