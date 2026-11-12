# Bootstrap for the ai2rules plugin (D117), for Windows without Git Bash: run the
# pinned `harness` binary, installing it first if it is not there. Same order as
# harness.sh beside it:
#
#   1. AI2RULES_HARNESS_FOR_PLUGIN, else AI2RULES_HARNESS, when it names a file:
#      used as is. The first is read by the plugin alone; the second is also the
#      pin a project's hook shim reads, which refuses a binary inside the project.
#   2. <config>\ai2rules\plugin\bin\harness.exe, when its --version is the one
#      binaries.lock pins.
#   3. Otherwise: download the pinned tarball from registry.npmjs.org, check its
#      SHA-512 against binaries.lock, and unpack the binary into (2) with the
#      tar.exe Windows 10 and later ship. Another hash is refused.
#
# `connect` (D137) runs `harness-connect`, the fleet connector: a program of its
# own, from the fleet application (ai2rules/app-console), which `harness connect`
# runs. For `connect` the same three steps make sure that program is there, pinned by
# connect.lock (npm package ai2rules-connect-windows-x64; a local build through
# AI2RULES_CONNECT_FOR_PLUGIN), and run it directly, without harness.
#
# Run it as: powershell -NoProfile -ExecutionPolicy Bypass -File harness.ps1 <args>
$ErrorActionPreference = 'Stop'

function Say($msg) { [Console]::Error.WriteLine("ai2rules: $msg") }

# The `key value` lines of a lock file, as a table.
function Read-Lock($path) {
    $entries = @{}
    foreach ($line in Get-Content -LiteralPath $path) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        $parts = $t -split '\s+'
        if ($parts.Count -ge 2) { $entries[$parts[0]] = $parts[1] }
    }
    $entries
}

# Download an npm package, refuse it unless its SHA-512 is the pinned one, and put
# one file of it at $dest. $true when installed; otherwise says why.
function Install-Pinned($what, $pkg, $version, $want, $file, $dest) {
    $url = "https://registry.npmjs.org/$pkg/-/$pkg-$version.tgz"
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("ai2rules-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        Say "installing $what $version for windows-x64, once, from $url"
        $tgz = Join-Path $tmp 'pkg.tgz'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tgz
        $got = (Get-FileHash -Algorithm SHA512 -LiteralPath $tgz).Hash.ToLowerInvariant()
        if ($got -ne $want.ToLowerInvariant()) {
            Say 'the downloaded package does not have the SHA-512 the plugin pins; refusing it.'
            Say "  expected $want"
            Say "  got      $got"
            return $false
        }
        # Windows' own tar.exe by full path: Git for Windows' tar can come first on PATH (a
        # PowerShell started from Git Bash), and it reads `C:\...` as a remote host.
        $tar = Join-Path $env:SystemRoot 'System32\tar.exe'
        if (-not (Test-Path -LiteralPath $tar)) { $tar = 'tar.exe' }
        & $tar -xzf $tgz -C $tmp "package/$file"
        if ($LASTEXITCODE -ne 0) { Say 'cannot unpack the package; nothing was installed.'; return $false }
        $destDir = Split-Path -Parent $dest
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        # A running .exe cannot be overwritten, but it can be renamed.
        $leaf = Split-Path -Leaf $dest
        if (Test-Path -LiteralPath $dest) {
            Rename-Item -LiteralPath $dest -NewName ("$leaf.old-" + $PID) -ErrorAction SilentlyContinue
        }
        Move-Item -LiteralPath (Join-Path $tmp "package\$file") -Destination $dest
        Get-ChildItem -LiteralPath $destDir -Filter "$leaf.old-*" -ErrorAction SilentlyContinue |
            Remove-Item -ErrorAction SilentlyContinue
        Say "installed $dest"
        return $true
    }
    finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

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

# `--version` of a binary, or '' when it cannot say (a corrupt file, an error on stderr):
# under ErrorActionPreference Stop either would end this script instead of reinstalling.
function Version-Of($path) {
    try { ((& $path --version 2>$null) -join ' ') } catch { '' }
}

# `connect` runs the fleet connector itself, of the pinned version, as `harness connect`
# would (D137): it does not depend on the pinned harness being a release that has
# `harness connect`. It gets the version `harness connect` would pass, the pinned
# harness's, which the console runs.
if ($args.Count -gt 0 -and $args[0] -ceq 'connect') {
    $cBin = $null
    if ($env:AI2RULES_CONNECT_FOR_PLUGIN) {
        if (-not (Test-Path -LiteralPath $env:AI2RULES_CONNECT_FOR_PLUGIN -PathType Leaf)) {
            Say "AI2RULES_CONNECT_FOR_PLUGIN is set to $($env:AI2RULES_CONNECT_FOR_PLUGIN), which is not a file."
            exit 1
        }
        $cBin = (Resolve-Path -LiteralPath $env:AI2RULES_CONNECT_FOR_PLUGIN).Path
    }
    else {
        $connectLock = if ($env:AI2RULES_CONNECT_LOCK) { $env:AI2RULES_CONNECT_LOCK } else { Join-Path $PSScriptRoot '..\connect.lock' }
        if (-not (Test-Path -LiteralPath $connectLock)) {
            Say "cannot read $connectLock; the plugin is incomplete. Reinstall it with /plugin."
            exit 1
        }
        $c = Read-Lock $connectLock
        $cVersion = $c['version']
        $cWant = $c[$platform]
        if ($cVersion -eq 'pending' -or $cWant -eq 'pending') {
            Say 'this build of the plugin needs a fleet connector (harness-connect) release that is not on npm yet.'
            Say 'Point it at a local build:  $env:AI2RULES_CONNECT_FOR_PLUGIN = "C:\absolute\path\to\harness-connect.exe"'
            exit 1
        }
        $cBin = Join-Path $dir 'harness-connect.exe'
        $ready = $false
        if (Test-Path -LiteralPath $cBin) {
            $ready = (Version-Of $cBin) -match "(^|\s)$([regex]::Escape($cVersion))(\s|$)"
        }
        if (-not $ready) {
            if (-not $cWant) {
                Say "no prebuilt fleet connector $cVersion for $platform."
                exit 1
            }
            if (-not (Install-Pinned 'the fleet connector' "ai2rules-connect-$platform" $cVersion $cWant 'harness-connect.exe' $cBin)) {
                exit 1
            }
        }
    }
    $hLock = if ($env:AI2RULES_LOCK) { $env:AI2RULES_LOCK } else { Join-Path $PSScriptRoot '..\binaries.lock' }
    if (Test-Path -LiteralPath $hLock) {
        $hVersion = (Read-Lock $hLock)['version']
        if ($hVersion -and $hVersion -ne 'pending') { $env:AI2RULES_HARNESS_VERSION = $hVersion }
    }
    $rest = @()
    if ($args.Count -gt 1) { $rest = $args[1..($args.Count - 1)] }
    & $cBin @rest
    exit $LASTEXITCODE
}

$givenBy = 'AI2RULES_HARNESS_FOR_PLUGIN'
$given = $env:AI2RULES_HARNESS_FOR_PLUGIN
if (-not $given) {
    $givenBy = 'AI2RULES_HARNESS'
    $given = $env:AI2RULES_HARNESS
}
if ($given) {
    if (-not (Test-Path -LiteralPath $given -PathType Leaf)) {
        Say "$givenBy is set to $given, which is not a file."
        exit 127
    }
    & $given @args
    exit $LASTEXITCODE
}

$lock = if ($env:AI2RULES_LOCK) { $env:AI2RULES_LOCK } else { Join-Path $PSScriptRoot '..\binaries.lock' }
if (-not (Test-Path -LiteralPath $lock)) {
    Say "cannot read $lock; the plugin is incomplete. Reinstall it with /plugin."
    exit 1
}
$entries = Read-Lock $lock
$version = $entries['version']
$want = $entries[$platform]

if ((Test-Path -LiteralPath $bin) -and $version -ne 'pending') {
    $have = Version-Of $bin
    if ($have -match "(^|\s)$([regex]::Escape($version))(\s|$)") {
        & $bin @args
        exit $LASTEXITCODE
    }
}

if ($version -eq 'pending' -or $want -eq 'pending') {
    Say 'this build of the plugin needs a harness release that is not on npm yet.'
    Say 'Point it at a local build:  $env:AI2RULES_HARNESS_FOR_PLUGIN = "C:\absolute\path\to\harness.exe"'
    exit 1
}
if (-not $want) {
    Say "no prebuilt harness $version for $platform. (A release candidate is built for Windows x64 only;"
    Say "stable releases have linux-x64, darwin-x64, darwin-arm64 and windows-x64.)"
    exit 1
}

if (-not (Install-Pinned 'harness' "ai2rules-harness-$platform" $version $want 'harness.exe' $bin)) {
    exit 1
}
& $bin @args
exit $LASTEXITCODE
