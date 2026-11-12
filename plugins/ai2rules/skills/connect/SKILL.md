---
description: Connect this machine to your organisation's ai2rules fleet centre. You give your work email and confirm with one click on the page the centre mails you a link to; you are never asked for a key, token or password.
argument-hint: "[your work email | stop]"
disable-model-invocation: true
---

# ai2rules connect

The person asked to connect this machine to their organisation's fleet centre. The
centre lists the machine, shows its local console to the admin and can push policy
to it; every decision about a tool call stays on this machine.

The centre's address, from the plugin's configuration: `${user_config.fleet_centre}`

If `$ARGUMENTS` is the word `stop`, go straight to "Stopping" below: stopping needs
no address.

If that address is empty, or still reads as a placeholder starting with `${`, run
nothing. Tell the person the plugin does not know their fleet centre yet: their admin
sets it for the organisation (managed settings, `pluginConfigs` → the plugin's name →
`fleet_centre`), or they set it themselves with `/plugin configure` and the plugin's
name (the "Fleet centre" option, an `https://` address their admin gives them), and
restart Claude Code. The plugin's name depends on where it was installed from, so name
both: `ai2rules@ai2rules` from the usual marketplace, `ai2rules@ai2rules-next` from the
test channel (`/plugin` lists the one they have). Then stop.

Run nothing either unless the address has exactly one of these shapes, character for
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

- It says the connector "runs in the background" or is "already running": the
  machine is connected. Relay its lines and stop.
- It says the machine "is not enrolled": go to step 2.
- It says the machine "is enrolled with" one centre, "not with" the configured one:
  the fleet has moved. Tell the person the machine is still enrolled with the old
  centre, and that connecting it to the new one takes their email and a new
  confirmation. On yes, go to step 2. Once the new enrollment is made, the old
  connector stops by itself.
- It says the admin "disconnected this machine": tell the person so, and ask whether
  to connect it again. On yes, go to step 2.
- Anything else: relay it word for word and stop.

## 2. The email address

If `$ARGUMENTS` is an email address, use it. Otherwise ask the person for the work
email address their admin put on the fleet's list, and wait for the answer. Then run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" connect --centre '<CENTRE>' --email 'EMAIL'
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" connect --centre '<CENTRE>' --email 'EMAIL'
```

- "a mail is on its way": tell the person, in so many words: "I sent the request.
  Check your inbox for a mail from the fleet centre and open the link. I'm waiting." If it also says "the check code is" and a code, add: "The page shows
  four codes: press CHECK. If it is not among them, press none." with that code in
  place of CHECK. The centre answers every address alike, so this does not
  mean the address is on the list. Then go to step 3 at once, without waiting for an
  answer.
- "if your address is on the list, the admin has your code": this centre is an older
  one, which confirms with a six-digit code instead of a mail. Go to step 4. The
  centre answers every address alike, so this does not mean the address is on the list.
- "too many attempts": relay it word for word. Tell the person to wait a while and run
  `/ai2rules:connect` again, or to ask their admin to clear the limit. Do not retry. Stop.
- Anything else: relay it word for word and stop.

## 3. Waiting for the confirmation

Run this with the tool's timeout set to 600000 ms (ten minutes): it waits, up to nine
minutes, until the person confirms on the page the mail links to.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/harness.sh" connect --wait --background
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/bin/harness.ps1" connect --wait --background
```

- It says the connector "runs in the background": the machine is connected. Tell the
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

- It says it "stopped this machine's connector": relay its lines. Tell the person this
  ends the connection on this machine only until they run `/ai2rules:connect` again
  (no new mail or code is needed then). It does not disconnect the
  machine for good: the machine stays enrolled and the centre still lists it; that is
  their admin's revoke on the fleet page. Then stop.
- It says "no connector is running", or that the connector "has ended by itself":
  tell the person no connector runs on this machine now, so there was nothing to stop.
  Stop.
- Anything else (it could not stop the connector): relay it word for word and stop.

## If you are Codex, not Claude Code

This command reads the centre's address from Claude Code's plugin configuration,
which Codex does not have. Run nothing. Tell the person to run `/ai2rules:connect` in
Claude Code, or, in a terminal of their own, `harness connect --centre <address>
--email <their address>`, which waits for the mailed link itself (or, with an older
centre, asks for the code). `harness connect` runs the fleet connector, a program of
its own: if it says the connector is not installed, `npm install -g ai2rules-connect`
installs it.
