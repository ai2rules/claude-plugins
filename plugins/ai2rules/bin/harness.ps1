# Bootstrap for the ai2rules plugin (D117), for Windows without Git Bash: run the
# pinned `harness` binary, installing it first if it is not there. Same order as
# harness.sh beside it:
#
#   1. AI2RULES_HARNESS, when it names a file: used as is.
#   2. <config>\ai2rules\plugin\bin\harness.exe, when its --version is the one
#      binaries.lock pins.
#   3. Otherwise: download the pinned tarball from registry.npmjs.org, check its
#      SHA-512 against binaries.lock, and unpack the binary into (2) with the
#      tar.exe Windows 10 and later ship. Another hash is refused.
#
# Run it as: powershell -NoProfile -ExecutionPolicy Bypass -File harness.ps1 <args>
$ErrorActionPreference = 'Stop'

function Say($msg) { [Console]::Error.WriteLine("ai2rules: $msg") }

if ($env:AI2RULES_HARNESS) {
    if (-not (Test-Path -LiteralPath $env:AI2RULES_HARNESS -PathType Leaf)) {
        Say "AI2RULES_HARNESS is set to $($env:AI2RULES_HARNESS), which is not a file."
        exit 127
    }
    & $env:AI2RULES_HARNESS @args
    exit $LASTEXITCODE
}

$lock = if ($env:AI2RULES_LOCK) { $env:AI2RULES_LOCK } else { Join-Path $PSScriptRoot '..\binaries.lock' }
$config = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
# Run for Codex (`--host codex` among the arguments, D124): the binary lives under
# Codex's home, the folder Codex's sandbox keeps read-only to a sandboxed agent.
for ($i = 0; $i -lt $args.Count - 1; $i++) {
    if ($args[$i] -eq '--host' -and $args[$i + 1] -eq 'codex') {
        $config = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
    }
}
$dir = Join-Path $config 'ai2rules\plugin\bin'
$bin = Join-Path $dir 'harness.exe'
$platform = 'windows-x64'

if (-not (Test-Path -LiteralPath $lock)) {
    Say "cannot read $lock; the plugin is incomplete. Reinstall it with /plugin."
    exit 1
}
$entries = @{}
foreach ($line in Get-Content -LiteralPath $lock) {
    $t = $line.Trim()
    if ($t -eq '' -or $t.StartsWith('#')) { continue }
    $parts = $t -split '\s+'
    if ($parts.Count -ge 2) { $entries[$parts[0]] = $parts[1] }
}
$version = $entries['version']
$want = $entries[$platform]

if ((Test-Path -LiteralPath $bin) -and $version -ne 'pending') {
    $have = (& $bin --version 2>$null) -join ' '
    if ($have -match "(^|\s)$([regex]::Escape($version))(\s|$)") {
        & $bin @args
        exit $LASTEXITCODE
    }
}

if ($version -eq 'pending' -or $want -eq 'pending') {
    Say 'this build of the plugin needs a harness release that is not on npm yet.'
    Say 'Point it at a local build:  $env:AI2RULES_HARNESS = "C:\absolute\path\to\harness.exe"'
    exit 1
}
if (-not $want) {
    Say "binaries.lock pins no binary for $platform."
    exit 1
}

$pkg = "ai2rules-harness-$platform"
$url = "https://registry.npmjs.org/$pkg/-/$pkg-$version.tgz"
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("ai2rules-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    Say "installing harness $version for $platform, once, from $url"
    $tgz = Join-Path $tmp 'pkg.tgz'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tgz
    $got = (Get-FileHash -Algorithm SHA512 -LiteralPath $tgz).Hash.ToLowerInvariant()
    if ($got -ne $want.ToLowerInvariant()) {
        Say 'the downloaded package does not have the SHA-512 binaries.lock pins; refusing it.'
        Say "  expected $want"
        Say "  got      $got"
        exit 1
    }
    # Windows' own tar.exe by full path: Git for Windows' tar can come first on PATH (a
    # PowerShell started from Git Bash), and it reads `C:\...` as a remote host.
    $tar = Join-Path $env:SystemRoot 'System32\tar.exe'
    if (-not (Test-Path -LiteralPath $tar)) { $tar = 'tar.exe' }
    & $tar -xzf $tgz -C $tmp 'package/harness.exe'
    if ($LASTEXITCODE -ne 0) { Say 'cannot unpack the package; nothing was installed.'; exit 1 }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    # A running harness.exe cannot be overwritten, but it can be renamed.
    if (Test-Path -LiteralPath $bin) {
        Rename-Item -LiteralPath $bin -NewName ("harness.exe.old-" + $PID) -ErrorAction SilentlyContinue
    }
    Move-Item -LiteralPath (Join-Path $tmp 'package\harness.exe') -Destination $bin
    Get-ChildItem -LiteralPath $dir -Filter 'harness.exe.old-*' -ErrorAction SilentlyContinue |
        Remove-Item -ErrorAction SilentlyContinue
    Say "installed $bin"
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
& $bin @args
exit $LASTEXITCODE
