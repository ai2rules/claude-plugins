---
description: Connect this machine to your organisation's ai2rules fleet centre. You give your work email and confirm with one click on the page the centre mails you a link to; you are never asked for a key, token or password.
argument-hint: "[your work email | stop | forget]"
disable-model-invocation: true
---

# ai2rules connect

The person asked to connect this machine to their organisation's fleet centre. The
centre lists the machine, shows its local console to the admin and can push policy
to it; every decision about a tool call stays on this machine.

The centre's address, from the plugin's configuration: `${user_config.fleet_centre}`

That is the organisation's address (their managed settings) or the person's own
setting, whichever Claude Code holds. When neither names one, the plugin's channel has
a default (D144): the plugin from the `next` channel connects to the staging centre,
the stable plugin to the production one.

If `$ARGUMENTS` is the word `stop`, go straight to "Stopping" below; if it is the word
`forget`, go straight to "Forgetting". Neither needs an address.

If that address is empty, or still reads as a placeholder starting with `${`, go to
"No address configured" below. The machine may be enrolled already (from a terminal, or
under another plugin name), and an enrollment keeps its centre: it outranks the
channel's default, which is used only for a machine that is not enrolled.

## No address configured

Only when the address above is empty or a placeholder. Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" connect --background
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" connect --background
```

Read its lines in this order, and take the first that fits:

- It says this machine "joins the fleet by itself": a request made earlier still waits
  for its confirmation. Do as the first bullet of step 1 says, using the centre the line
  names.
- It says "the connector runs in the background" or a connector is "already running":
  the machine is connected, with the centre it was enrolled with (the line names it).
  Do "So that the centre sees this machine" below first, using that centre. Relay its lines, and tell the person what step 1 says for a connected machine. Stop.
- It says the machine "is not enrolled": ask the plugin for its channel's default:

  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" guard centre --plugin-root "${CLAUDE_PLUGIN_ROOT}"
  ```

  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" guard centre --plugin-root "${CLAUDE_PLUGIN_ROOT}"
  ```

  Other lines may come first (on the first run after an update the plugin says it
  installs the harness, `ai2rules: installing …`). Look for the line that starts with
  `Fleet centre: http`: the address after it, up to the next space, is the configured
  address from here on, and the bracket after it says where it came from (the plugin's
  channel default). Tell the person, in a few words, where the address came from, as
  the bracket says (usually the default of the plugin's channel), and that
  `/ai2rules:about` shows how to set another. Go on with
  "The configured address" below.

  If no such line comes (`Fleet centre: none`, or the harness does not know the
  command): tell the person the plugin could not tell their fleet centre (no default for
  its channel: it was tried from a checkout, or its harness is older), so it cannot
  enroll this machine: their admin sets it for the
  organisation (managed settings, `pluginConfigs` → the plugin's name → `fleet_centre`),
  or they set it themselves with `/plugin configure` and the plugin's name (the "Fleet
  centre" option, an `https://` address their admin gives them), and restart Claude
  Code. The plugin's name depends on where it was installed from, so name both:
  `ai2rules@ai2rules` from the usual marketplace, `ai2rules@ai2rules-next` from the
  test channel (`/plugin` lists the one they have). Then stop.
- It says the admin "disconnected this machine": tell the person so, and that
  connecting it again needs the fleet centre's address set as above. Stop.
- Anything else: relay it word for word and stop.

## The configured address

Run nothing unless the address has exactly one of these shapes, character for
character, and nothing else at all (no space, line break, quote of any kind, `$`,
backtick or any other character):

- `https://`, then a host of letters `a`-`z` `A`-`Z`, digits `0`-`9`, `.` and `-`,
  then optionally `:` and a port of digits, then optionally a path of `/` followed by
  letters, digits, `.`, `-`, `_` and `/`;
- `http://127.0.0.1` or `http://localhost`, optionally followed by `:` and a port of
  digits (a centre on this machine).

If it does not fit, tell the person the configured address looks wrong, and stop.

Throughout:

- Never ask the person for a key, a token, a password, a certificate or a hosts-file
  line, and never read, print or quote the files under `~/.claude/ai2rules/fleet/`.
  The binary keeps the machine's token there; neither you nor the person needs to see it.
- Run only the commands below, one at a time, with the person's email address or
  code in place of `EMAIL` or `CODE`, and the address above in place of `<CENTRE>`.
  Keep the single quotes around each value exactly as shown, so the shell passes it
  as typed and expands nothing in it.
- Check a value's shape before it goes into a command, and if it does not fit, run
  nothing and ask the person again:
  - an email address is one `@` with something on each side; before the `@` only
    letters, digits and `.` `_` `%` `+` `-`; after it only letters, digits, `.` and `-`.
    No space, quote, `$`, backtick or anything else.
  - a code is exactly six digits, `0` to `9`, and nothing else (drop spaces the person
    put between the digits).
- Each command has two forms. Use the Bash one when you have a Bash tool; without one
  (Windows without Git Bash), use the PowerShell one.

## 1. Already connected?

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" connect --background --centre '<CENTRE>'
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" connect --background --centre '<CENTRE>'
```

Read its lines in this order, and take the first that fits:

- It says this machine "joins the fleet by itself": a request made earlier is still
  waiting for the person's confirmation, and a helper on this machine waits for it (the
  machine is not connected yet). Mail nothing new. Do "So that the centre sees this machine" below first. If the person says they have already
  pressed the code, tell them the helper picks the confirmation up within a few seconds,
  and to run `/ai2rules:connect` again in a moment to see the machine connected; do not
  ask them to press again (the link works once). Otherwise tell them to open the mail
  from the fleet centre and press the check code that line names on the page it opens;
  the machine then joins by itself. Stop.
- It says "the connector runs in the background" or a connector is "already running":
  the machine is connected. Do "So that the centre sees this machine" below first. Relay its lines. Tell the person it stays connected while
  this computer is on, that after a restart they run `/ai2rules:connect` again (no new
  mail is needed then), that `/ai2rules:connect stop` ends the connection on this
  machine, and that `/ai2rules:connect forget` also removes the enrollment from it.
  Stop.
- It says the machine "is not enrolled": go to step 2. If it also says the last request
  "ended without this machine joining", tell the person why first, in its words (the
  link expired or was already used, or too many attempts), then go to step 2.
- It says the machine "is enrolled with" one centre, "not with" the configured one:
  the fleet has moved. Tell the person the machine is still enrolled with the old
  centre, and ask, in so many words: "Should I enroll this machine with <CENTRE>? It
  takes your work email and one confirmation in a mail." with the configured address in
  place of <CENTRE>. Wait for the answer. On yes, go to step 2. Once the new enrollment is made, the
  old connector stops by itself. On no, keep the machine with the centre it is enrolled
  with: run the command under "No address configured" and go on as it says there.
- It says the admin "disconnected this machine": tell the person so, and ask whether
  to connect it again. On yes, go to step 2.
- Anything else: relay it word for word and stop.

## So that the centre sees this machine

The fleet centre sees a machine through two things on it: the guard, which decides and
logs every tool call, and the local console, which the connector relays to the centre.
The person never has to open the console. Do this whenever step 1, 2 or 3 says the
machine is connected, or that it "joins the fleet by itself", before you tell the person
the result, and only once in this conversation:

1. See whether the guard is on:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" guard about
   ```

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" guard about
   ```

   If its `Guard:` line says `off`, turn it on in observe mode, which logs and blocks
   nothing:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" guard observe
   ```

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" guard observe
   ```

   Then tell the person, in so many words: "I turned the guard on in observe mode: it
   logs every tool call and blocks nothing, so the fleet centre sees what the agents do.
   It applies to Claude Code sessions started from now on." If the `Guard:` line says
   `observe` or `seatbelt`, leave it as it is: never change a mode the person chose.
2. Start the console in the background (it says "already runs" if it does, and replaces
   one of an older release):

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" console --background
   ```

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" console --background
   ```

   If it fails, relay its line, and go on: the machine is still connected.
3. With the result of step 1, 2 or 3, tell the person where the admin looks: "The fleet
   page is <CENTRE>: your admin sees this machine there, what its agents do, and the
   tools they ask for. You do not need to open anything on this machine." Use the
   configured address in place of <CENTRE>.

## 2. The email address

If `$ARGUMENTS` is an email address, use it. Otherwise ask the person for the work
email address their admin put on the fleet's list, and wait for the answer. Then run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" connect --centre '<CENTRE>' --email 'EMAIL' --background
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" connect --centre '<CENTRE>' --email 'EMAIL' --background
```

- "a mail is on its way" and "joins the fleet by itself": the request is made, and a
  helper on this machine waits for the confirmation, then connects the machine by
  itself. Do "So that the centre sees this machine" below first. Tell the person, in so many words: "Open the mail from the fleet centre and
  press CHECK on the page it opens; this machine joins the fleet by itself. Nothing
  else is needed now, from you or from me." with the code from the line "the check code is"
  in place of CHECK, and add: "The page shows four codes. If CHECK is not among them,
  press none. The code makes sure nobody can join your fleet with your email from their
  own computer." Then: "Once it has joined, it stays connected while this computer is on;
  after a restart, run `/ai2rules:connect` again (no new mail is needed then)." The
  centre answers every address alike, so this does not mean the address is on the list.
  Then stop: run nothing more and do not wait. If the person comes back and says they
  pressed it, run step 1 and tell them what it says.
- "a mail is on its way" with no "joins the fleet by itself", but "run `harness
  connect --wait`" (an older connector): tell the person, in so many words: "I sent the
  request. Check your inbox for a mail from the fleet centre and open the link. I'm
  waiting." If it also says "the check code is" and a code, add: "The page shows four
  codes: press CHECK. If it is not among them, press none. The code makes sure nobody
  can join your fleet with your email from their own computer." with that code in place
  of CHECK. Then go to step 3 at once, without waiting for an answer.
- "if your address is on the list, the admin has your code": this centre is an older
  one, which confirms with a six-digit code instead of a mail. Go to step 4. The
  centre answers every address alike, so this does not mean the address is on the list.
- "too many attempts": relay it word for word. Tell the person to wait a while and run
  `/ai2rules:connect` again, or to ask their admin to clear the limit. Do not retry. Stop.
- Anything else: relay it word for word and stop.

## 3. Waiting for the confirmation (an older connector)

Only when step 2 said to run `harness connect --wait`. Run this with the tool's timeout
set to 600000 ms (ten minutes): it waits, up to nine minutes, until the person confirms
on the page the mail links to.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" connect --wait --background
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" connect --wait --background
```

- It says the connector "runs in the background": the machine is connected. Do "So that the centre sees this machine" below first. Tell the
  person it now shows on the fleet page, that it stays connected while this computer
  is on, and that after a restart they run `/ai2rules:connect` again (no new mail is
  needed then). To end the connection on this machine, they run
  `/ai2rules:connect stop`.
- "still waiting for the confirmation": ask the person whether the mail came and
  whether they pressed their check code on the page it opens (and to look in their spam
  folder). Wait for their answer, then run step 3 again.
- "Start again": the link expired or was already used, and the enrollment is gone.
  Tell the person so, and ask them to check that the address is the one their admin
  put on the list. Only if they ask to start again, run step 2 (with the address they
  confirm).
- "too many attempts": relay it word for word. Tell the person to wait a while and run
  `/ai2rules:connect` again, or to ask their admin to clear the limit. Do not retry. Stop.
- Anything else: relay it word for word and stop.

## 4. The code (an older centre)

Only when step 2 said the admin has the code. Ask the person for the six-digit code:
their admin reads it to them. Wait for the answer, then run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" connect --code 'CODE' --background
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" connect --code 'CODE' --background
```

- It says the connector "runs in the background": the machine is connected. Tell the
  person it now shows on the fleet page, that it stays connected while this computer
  is on, and that after a restart they run `/ai2rules:connect` again (no new code is
  needed then). To end the connection on this machine, they run
  `/ai2rules:connect stop`.
- "wrong code" or "six digits": ask for the code again and repeat step 4.
- "Start again": the code expired or was wrong five times, and the enrollment is gone.
  Tell the person so, and ask them to check that the address is the one their admin
  put on the list. Only if they ask to start again, run step 2 (with the address they
  confirm).
- "too many attempts": relay it word for word. Tell the person to wait a while and run
  `/ai2rules:connect` again, or to ask their admin to clear the limit. Do not retry. Stop.
- Anything else: relay it word for word and stop.

## Stopping

Only when `$ARGUMENTS` is `stop`. Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" connect --stop
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" connect --stop
```

- If one of its lines says a request "is withdrawn": a request was still waiting for its
  confirmation, and it is cancelled now, so this machine does not join when that mail is
  confirmed. Tell the person so, then go on with the other lines below.
- It says it "stopped this machine's connector": relay its lines. Tell the person this
  ends the connection on this machine only until they run `/ai2rules:connect` again
  (no new mail or code is needed then). It does not disconnect the
  machine for good: the machine stays enrolled and the centre still lists it; that is
  their admin's revoke on the fleet page; `/ai2rules:connect forget` also removes the
  enrollment from this machine. Then stop.
- It says "no connector is running", or that the connector "has ended by itself":
  tell the person no connector runs on this machine now, so there was no connection to
  stop (a withdrawn request, above, is still worth saying). Stop.
- Anything else (it could not stop the connector): relay it word for word and stop.

## Forgetting

Only when `$ARGUMENTS` is `forget`. It stops the connector as "Stopping" does, and also
removes this machine's enrollment (its token and centre) from this machine. Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" connect --forget
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" connect --forget
```

Go through its lines in order:

- A line says a request "is withdrawn", or that a request waiting in `enroll.json`
  "could not be read, is removed": a request was still waiting for its confirmation, and
  it is cancelled now. Tell the person so, then go on.
- A line says "connect: stopped" this machine's connector for a centre, that "no
  connector was running", or that the connector "has ended by itself": relay it, then go
  on.
- It says it "forgot this machine's enrollment with" a centre, or that it "removed this
  machine's enrollment, which could not be read": relay its lines. Tell the
  person three things: this machine no longer connects, and its token is gone from it;
  it is forgotten only on this machine, so the centre still lists the machine until
  their admin revokes it on the fleet page (or until it enrolls again, which replaces
  the old card); and joining again with `/ai2rules:connect` mails a new link. Stop.
- It says "nothing to forget" or "nothing more to forget": this machine was not
  enrolled. Tell the person so (a withdrawn request or a stopped connector, above, is
  still worth saying). Stop.
- It says "the enrollment stays": relay its lines word for word. Nothing beyond a
  withdrawn request was forgotten. If a line says a connector still runs and to "end it
  by hand", tell the person to end the process that line names first, then run
  `/ai2rules:connect forget` again. Otherwise (a wait for a confirmation still runs),
  tell them they can run `/ai2rules:connect forget` again in a minute. Stop.
- It says "unexpected argument" about `--forget`: the connector this plugin installed
  predates `forget`. Relay it, and tell the person to update the plugin (`/plugin`, then
  restart Claude Code) and run `/ai2rules:connect forget` again; meanwhile
  `/ai2rules:connect stop` ends the connection. Stop.
- Anything else: relay it word for word and stop.

## If you are Codex, not Claude Code

This command reads the centre's address from Claude Code's plugin configuration,
which Codex does not have. Run nothing. Tell the person to run `/ai2rules:connect` in
Claude Code, or, in a terminal of their own, `harness connect --centre <address>
--email <their address>`, which waits for the mailed link itself (or, with an older
centre, asks for the code). `harness connect` runs the fleet connector, a program of
its own: if it says the connector is not installed, `npm install -g ai2rules-connect`
installs it.
