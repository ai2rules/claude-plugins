#!/usr/bin/env bash
# Bootstrap for the ai2rules plugin (D117): run the pinned `harness` binary,
# installing it first if it is not there. For Git Bash, Linux and macOS;
# `harness.ps1` beside it does the same on Windows without Git Bash.
#
#   1. AI2RULES_HARNESS_FOR_PLUGIN, else AI2RULES_HARNESS, when it names a file:
#      used as is (development builds, platforms npm has no binary for). The
#      first is read by the plugin alone. The second is also the pin a project's
#      hook shim reads (D101), and that shim refuses a binary inside the project
#      it governs, so a build under the project's own target/ goes in the first.
#   2. <config>/ai2rules/plugin/bin/harness[.exe], when its --version is the one
#      binaries.lock pins.
#   3. Otherwise: download the pinned platform tarball from registry.npmjs.org,
#      check its SHA-512 against binaries.lock, and unpack the binary into (2).
#      Another hash is refused and nothing is installed.
#
# `connect` (D137) runs `harness-connect`, the fleet connector: a program of its
# own, from the fleet application (ai2rules/app-console), which `harness connect`
# runs. For `connect` the same three steps make sure that program is there, pinned by
# connect.lock (npm package ai2rules-connect-<platform>; a local build through
# AI2RULES_CONNECT_FOR_PLUGIN), and run it directly, without harness.
#
# Only the plugin's commands run this; the hook never does (it runs the binary
# directly, registered by `harness guard`). Needs curl, tar and sha512sum or shasum.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lock="${AI2RULES_LOCK:-$here/../binaries.lock}"
connect_lock="${AI2RULES_CONNECT_LOCK:-$here/../connect.lock}"
config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# Run for Codex (`--host codex` among the arguments, D124): the binary lives under
# Codex's home, the folder Codex's sandbox keeps read-only to a sandboxed agent.
prev=
for a in "$@"; do
  if [ "$prev" = --host ] && [ "$a" = codex ]; then
    config="${CODEX_HOME:-$HOME/.codex}"
  fi
  prev="$a"
done
dir="$config/ai2rules/plugin/bin"

say() { printf 'ai2rules: %s\n' "$*" >&2; }

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  MINGW* | MSYS* | CYGWIN*) os=windows ;;
  *) os=unknown ;;
esac
case "$(uname -m)" in
  x86_64 | amd64) arch=x64 ;;
  arm64 | aarch64) arch=arm64 ;;
  *) arch=unknown ;;
esac
platform="$os-$arch"
suffix=""
[ "$os" = windows ] && suffix=.exe

# pinned <lock> <key>: the value of `<key> <value>` in a lock file.
pinned() { awk -v k="$2" '$1 == k { print $2 }' "$1"; }

# fetch_pinned <what> <npm package> <version> <sha512 hex> <file in the package> <dest>:
# download the package from registry.npmjs.org, refuse it unless its SHA-512 is the
# pinned one, and put the file at <dest>. Returns 1, having said why, on failure.
fetch_pinned() {
  local what="$1" pkg="$2" version="$3" want="$4" file="$5" dest="$6"
  local url="https://registry.npmjs.org/$pkg/-/$pkg-$version.tgz"
  local tmp got
  tmp="$(mktemp -d)"
  say "installing $what $version for $platform, once, from $url"
  if ! curl -fsSL --retry 2 -o "$tmp/pkg.tgz" "$url"; then
    rm -rf "$tmp"
    say "download failed; nothing was installed."
    return 1
  fi
  if command -v sha512sum >/dev/null 2>&1; then
    got="$(sha512sum "$tmp/pkg.tgz" | cut -d' ' -f1)"
  else
    got="$(shasum -a 512 "$tmp/pkg.tgz" | cut -d' ' -f1)"
  fi
  if [ "$got" != "$want" ]; then
    rm -rf "$tmp"
    say "the downloaded package does not have the SHA-512 the plugin pins; refusing it."
    say "  expected $want"
    say "  got      $got"
    return 1
  fi
  # Each step checked by hand: called with `||`, this function runs without `set -e`.
  if ! tar -xzf "$tmp/pkg.tgz" -C "$tmp" "package/$file" || ! mkdir -p "$(dirname "$dest")"; then
    rm -rf "$tmp"
    say "cannot unpack the package; nothing was installed."
    return 1
  fi
  # A running .exe cannot be overwritten on Windows, but it can be renamed.
  if [ -e "$dest" ]; then
    mv -f "$dest" "$dest.old-$$" 2>/dev/null || true
  fi
  if ! mv "$tmp/package/$file" "$dest" || ! chmod +x "$dest"; then
    rm -rf "$tmp"
    say "cannot put $dest in place; nothing was installed."
    return 1
  fi
  rm -f "$dest".old-* 2>/dev/null || true
  rm -rf "$tmp"
  say "installed $dest"
}

# The fleet connector for `connect`, of the pinned version, in $connect_bin.
connect_ready() {
  if [ -n "${AI2RULES_CONNECT_FOR_PLUGIN:-}" ]; then
    if [ ! -f "$AI2RULES_CONNECT_FOR_PLUGIN" ]; then
      say "AI2RULES_CONNECT_FOR_PLUGIN is set to $AI2RULES_CONNECT_FOR_PLUGIN, which is not a file."
      return 1
    fi
    connect_bin="$AI2RULES_CONNECT_FOR_PLUGIN"
    return 0
  fi
  if [ ! -f "$connect_lock" ]; then
    say "cannot read $connect_lock; the plugin is incomplete. Reinstall it with /plugin."
    return 1
  fi
  local version want cbin
  version="$(pinned "$connect_lock" version)"
  want="$(pinned "$connect_lock" "$platform")"
  cbin="$dir/harness-connect$suffix"
  if [ "$version" = pending ] || [ "$want" = pending ]; then
    say "this build of the plugin needs a fleet connector (harness-connect) release that is not on npm yet."
    say "Point it at a local build:  export AI2RULES_CONNECT_FOR_PLUGIN=/absolute/path/to/harness-connect"
    return 1
  fi
  if ! { [ -x "$cbin" ] && "$cbin" --version 2>/dev/null | grep -qw -- "$version"; }; then
    if [ -z "$want" ]; then
      say "no prebuilt fleet connector $version for $platform. (A release candidate is built for Windows x64 only.)"
      say "With a harness-connect binary of your own:  export AI2RULES_CONNECT_FOR_PLUGIN=/absolute/path/to/harness-connect"
      return 1
    fi
    fetch_pinned "the fleet connector" "ai2rules-connect-$platform" "$version" "$want" \
      "harness-connect$suffix" "$cbin" || return 1
  fi
  connect_bin="$cbin"
}

# `connect` runs the connector itself, as `harness connect` would (D137), so it does not
# depend on the pinned harness being a release that has `harness connect`. It gets the
# version `harness connect` would pass: the pinned harness's, which the console runs.
if [ "${1:-}" = connect ]; then
  connect_bin=""
  connect_ready || exit 1
  shift
  harness_version="$( [ -f "$lock" ] && pinned "$lock" version || true)"
  if [ -n "$harness_version" ] && [ "$harness_version" != pending ]; then
    export AI2RULES_HARNESS_VERSION="$harness_version"
  fi
  exec "$connect_bin" "$@"
fi

given_by=AI2RULES_HARNESS_FOR_PLUGIN
given="${AI2RULES_HARNESS_FOR_PLUGIN:-}"
if [ -z "$given" ]; then
  given_by=AI2RULES_HARNESS
  given="${AI2RULES_HARNESS:-}"
fi
if [ -n "$given" ]; then
  if [ ! -f "$given" ]; then
    say "$given_by is set to $given, which is not a file."
    exit 127
  fi
  exec "$given" "$@"
fi

exe="harness$suffix"
bin="$dir/$exe"

if [ ! -f "$lock" ]; then
  say "cannot read $lock; the plugin is incomplete. Reinstall it with /plugin."
  exit 1
fi
version="$(pinned "$lock" version)"
want="$(pinned "$lock" "$platform")"

if [ -x "$bin" ] && [ "$version" != pending ] &&
  "$bin" --version 2>/dev/null | grep -qw -- "$version"; then
  exec "$bin" "$@"
fi

if [ "$version" = pending ] || [ "$want" = pending ]; then
  say "this build of the plugin needs a harness release that is not on npm yet."
  say "Point it at a local build:  export AI2RULES_HARNESS_FOR_PLUGIN=/absolute/path/to/harness"
  exit 1
fi
if [ -z "$want" ]; then
  say "no prebuilt harness $version for $platform. (A release candidate is built for Windows x64 only;"
  say "stable releases have linux-x64, darwin-x64, darwin-arm64 and windows-x64.)"
  say "Ask for it at https://github.com/ai2rules/kernel-concepts/issues. With a harness binary of your own,"
  say "point the plugin at it:  export AI2RULES_HARNESS_FOR_PLUGIN=/absolute/path/to/harness"
  exit 1
fi

fetch_pinned harness "ai2rules-harness-$platform" "$version" "$want" "$exe" "$bin" || exit 1
exec "$bin" "$@"
