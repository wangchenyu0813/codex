#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD_DIR="$REPO_DIR/payload"
RESTORE_WORK="$(mktemp -d "${TMPDIR:-/tmp}/codex-restore.XXXXXX")"
ARCHIVE_PATH="$RESTORE_WORK/codex-migration.tar.gz"
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

cleanup() {
  rm -rf "$RESTORE_WORK"
}
trap cleanup EXIT

if pgrep -x Codex >/dev/null 2>&1; then
  echo "Quit Codex completely before restoring." >&2
  exit 1
fi

cd "$PAYLOAD_DIR"
shasum -a 256 -c SHA256SUMS
cat codex-migration.part-* > "$ARCHIVE_PATH"
tar -tzf "$ARCHIVE_PATH" >/dev/null

mkdir -p "$HOME/.codex" "$HOME/Library/Application Support/com.openai.chat"
for item in sessions archived_sessions attachments generated_images memories rules skills session_index.jsonl state_5.sqlite .codex-global-state.json; do
  if [ -e "$HOME/.codex/$item" ]; then
    mv "$HOME/.codex/$item" "$HOME/.codex/${item}.pre-migration-$BACKUP_SUFFIX"
  fi
done

tar -C "$HOME" -xzf "$ARCHIVE_PATH"
echo "Restore completed. Open Codex and verify the task list and archived tasks."

