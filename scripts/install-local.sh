#!/usr/bin/env bash
#
# Install the release build into /Applications, for this machine.
#
# The distribution flow (scripts/release.sh) already produces exactly the app
# you want locally, so this deliberately does not build anything by default —
# it copies what is there. Pass --build to run a signed release build first.
#
#   ./scripts/install-local.sh            # install whatever is built
#   ./scripts/install-local.sh --build    # build, then install
#
# Notarization is not required to run an app you built yourself: a locally
# produced bundle carries no quarantine attribute, so Gatekeeper never
# challenges it. This is why the local path can skip the round trip to Apple
# that release.sh pays for.

set -euo pipefail

cd "$(dirname "$0")/.."

# Derived from tauri.conf.json rather than hardcoded: the bundle and binary
# names are the app's to decide, and a rename that left this script pointing at
# a stale path would fail with "no build at …" while a perfectly good bundle sat
# next to it.
product="$(node -p "require('./src-tauri/tauri.conf.json').productName")"
binary="$(node -p "require('./src-tauri/tauri.conf.json').mainBinaryName || require('./src-tauri/tauri.conf.json').productName")"

app="src-tauri/target/release/bundle/macos/$product.app"
dest="/Applications/$product.app"

if [[ "${1:-}" == "--build" ]]; then
  # Only the --build path needs an identity; installing an existing bundle does
  # not re-sign it. Resolved from the environment or .env.local — see
  # scripts/signing-env.sh.
  source "$(dirname "$0")/signing-env.sh"
  echo "==> Building"
  npm run tauri build
elif [[ -n "${1:-}" ]]; then
  echo "usage: $0 [--build]" >&2
  exit 1
fi

if [[ ! -d "$app" ]]; then
  echo "error: no build at $app — run with --build, or npm run app:release" >&2
  exit 1
fi

# Replacing a bundle out from under a running process leaves the copy half
# written and the running app pointing at files that no longer exist. Refuse
# rather than corrupt it; the version being replaced is usually the one the user
# is looking at.
if pgrep -f "^$dest/Contents/MacOS/$binary\$" >/dev/null 2>&1; then
  echo "error: $product is running from /Applications — quit it first (⌘Q)" >&2
  exit 1
fi

from=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app/Contents/Info.plist")
to="(none)"
if [[ -d "$dest" ]]; then
  to=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
    "$dest/Contents/Info.plist" 2>/dev/null || echo "unknown")
fi

echo "==> Installing $from over $to"

# Staged in /Applications rather than /tmp because the swap below has to be a
# rename on the same filesystem: moving a bundle across filesystems re-copies
# it, and that can drop the extended attributes the signature is computed over.
# The staging directory is a plain hidden directory so no stray .app sits at the
# top level of /Applications, and the bundle inside keeps its real name.
stage="/Applications/.$product.install-$$"
staged="$stage/$product.app"
replaced="$stage/replaced.app"

# The install is only destructive for the length of two renames, and this puts
# the old bundle back if it dies between them. On the happy path everything here
# is already gone and each step is a no-op.
cleanup() {
  if [[ -d "$replaced" && ! -d "$dest" ]]; then
    mv "$replaced" "$dest"
  fi
  rm -rf "$stage"
}
# Bash does not reliably run an EXIT trap when a script is killed by a signal it
# has not trapped, and the one moment that matters — between the two renames
# below — is exactly when an impatient ⌃C would leave /Applications empty.
# cleanup is idempotent, so running it twice on the way out is harmless.
trap 'cleanup; exit 130' INT TERM
trap cleanup EXIT

mkdir -p "$stage"

# ditto rather than cp: it preserves the bundle's extended attributes and
# resource forks, which a plain recursive copy can drop and which the code
# signature is computed over.
ditto "$app" "$staged"

# Verify before touching what is installed. Checking after the copy — as this
# used to — meant a bundle that failed left the machine with a suspect app and
# no way back to the working one, which is the opposite of what a failed check
# should cost.
if ! codesign --verify --deep --strict "$staged" 2>/dev/null; then
  echo "error: signature does not verify — refusing to install" >&2
  # Captured rather than piped into grep: `grep -q` exits on the first match and
  # the SIGPIPE that gives codesign becomes a failed pipeline under `pipefail`,
  # so the test reads false exactly when it should read true.
  signing="$(codesign -dvv "$staged" 2>&1 || true)"
  if [[ "$signing" == *"Signature=adhoc"* ]]; then
    # By far the most common cause, and the message is useless without it:
    # `tauri build` signs ad-hoc unless an identity is in the environment, and
    # only the --build path above puts one there.
    echo "  That bundle is ad-hoc signed, which is what a bare \`npm run app:build\`" >&2
    echo "  produces. Only --build resolves a real Developer ID identity (see" >&2
    echo "  scripts/signing-env.sh). Rebuild and install in one step:" >&2
    echo "" >&2
    echo "      npm run app:install -- --build" >&2
    echo "" >&2
  fi
  if [[ -d "$dest" ]]; then
    echo "  $dest is unchanged." >&2
  fi
  exit 1
fi

# Rename the old bundle aside rather than deleting it, so a failure on the next
# line is recoverable. Moving it out entirely — rather than copying over it —
# is also what keeps files deleted between versions from surviving as strays
# inside the new install.
if [[ -d "$dest" ]]; then
  mv "$dest" "$replaced"
fi
mv "$staged" "$dest"

rm -rf "$stage"
trap - EXIT

echo "==> Installed $dest ($from)"
