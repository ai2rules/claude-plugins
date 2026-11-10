#!/usr/bin/env bash
# Bootstrap for the ai2rules plugin (D117): run the pinned `harness` binary,
# installing it first if it is not there. For Git Bash, Linux and macOS;
# `harness.ps1` beside it does the same on Windows without Git Bash.
#
#   1. AI2RULES_HARNESS, when it names a file: used as is (development builds,
#      platforms npm has no binary for).
#   2. <config>/ai2rules/plugin/bin/harness[.exe], when its --version is the one
#      binaries.lock pins.
#   3. Otherwise: download the pinned platform tarball from registry.npmjs.org,
#      check its SHA-512 against binaries.lock, and unpack the binary into (2).
#      Another hash is refused and nothing is installed.
#
# Only the plugin's commands run this; the hook never does (it runs the binary
# directly, registered by `harness guard`). Needs curl, tar and sha512sum or shasum.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lock="${AI2RULES_LOCK:-$here/../binaries.lock}"
config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
dir="$config/ai2rules/plugin/bin"

say() { printf 'ai2rules: %s\n' "$*" >&2; }

if [ -n "${AI2RULES_HARNESS:-}" ]; then
  if [ ! -f "$AI2RULES_HARNESS" ]; then
    say "AI2RULES_HARNESS is set to $AI2RULES_HARNESS, which is not a file."
    exit 127
  fi
  exec "$AI2RULES_HARNESS" "$@"
fi

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
exe=harness
[ "$os" = windows ] && exe=harness.exe
bin="$dir/$exe"

if [ ! -f "$lock" ]; then
  say "cannot read $lock; the plugin is incomplete. Reinstall it with /plugin."
  exit 1
fi
version="$(awk '$1 == "version" { print $2 }' "$lock")"
want="$(awk -v p="$platform" '$1 == p { print $2 }' "$lock")"

if [ -x "$bin" ] && [ "$version" != pending ] &&
  "$bin" --version 2>/dev/null | grep -qw -- "$version"; then
  exec "$bin" "$@"
fi

if [ "$version" = pending ] || [ "$want" = pending ]; then
  say "this build of the plugin needs a harness release that is not on npm yet."
  say "Point it at a local build:  export AI2RULES_HARNESS=/absolute/path/to/harness"
  exit 1
fi
if [ -z "$want" ]; then
  say "no prebuilt harness for $platform (published: linux-x64, darwin-x64, darwin-arm64, windows-x64)."
  say "Ask for it at https://github.com/ai2rules/kernel-concepts/issues. With a harness binary of your own,"
  say "point the plugin at it:  export AI2RULES_HARNESS=/absolute/path/to/harness"
  exit 1
fi

pkg="ai2rules-harness-$platform"
url="https://registry.npmjs.org/$pkg/-/$pkg-$version.tgz"
tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT
say "installing harness $version for $platform, once, from $url"
if ! curl -fsSL --retry 2 -o "$tmp/pkg.tgz" "$url"; then
  say "download failed; nothing was installed."
  exit 1
fi
if command -v sha512sum >/dev/null 2>&1; then
  got="$(sha512sum "$tmp/pkg.tgz" | cut -d' ' -f1)"
else
  got="$(shasum -a 512 "$tmp/pkg.tgz" | cut -d' ' -f1)"
fi
if [ "$got" != "$want" ]; then
  say "the downloaded package does not have the SHA-512 binaries.lock pins; refusing it."
  say "  expected $want"
  say "  got      $got"
  exit 1
fi
tar -xzf "$tmp/pkg.tgz" -C "$tmp" "package/$exe"
mkdir -p "$dir"
# A running harness.exe cannot be overwritten on Windows, but it can be renamed.
if [ -e "$bin" ]; then
  mv -f "$bin" "$bin.old-$$" 2>/dev/null || true
fi
mv "$tmp/package/$exe" "$bin"
chmod +x "$bin"
rm -f "$dir/$exe".old-* 2>/dev/null || true
say "installed $bin"
cleanup
trap - EXIT
exec "$bin" "$@"
