#!/bin/bash
set -euo pipefail

CODEX_SOURCE="$HOME/.codex"
APP_INDEX_SOURCE="$HOME/Library/Application Support/com.openai.chat"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$REPO_DIR/.migration-work"
PAYLOAD_DIR="$REPO_DIR/payload"
ARCHIVE_PATH="$PAYLOAD_DIR/codex-migration.tar.gz"

if [ ! -d "$CODEX_SOURCE/sessions" ]; then
  echo "Codex sessions were not found at $CODEX_SOURCE/sessions" >&2
  exit 1
fi

mkdir -p "$WORK_DIR/.codex" "$WORK_DIR/Library/Application Support/com.openai.chat" "$PAYLOAD_DIR"
rm -f "$PAYLOAD_DIR"/codex-migration.part-* "$PAYLOAD_DIR/SHA256SUMS"

for item in sessions archived_sessions attachments generated_images memories rules skills; do
  if [ -e "$CODEX_SOURCE/$item" ]; then
    rsync -a --delete \
      --exclude='.system/' \
      --exclude='cache/' \
      --exclude='tmp/' \
      "$CODEX_SOURCE/$item" "$WORK_DIR/.codex/"
  fi
done

for item in AGENTS.md session_index.jsonl .codex-global-state.json; do
  if [ -f "$CODEX_SOURCE/$item" ]; then
    cp -p "$CODEX_SOURCE/$item" "$WORK_DIR/.codex/$item"
  fi
done

if [ -f "$CODEX_SOURCE/state_5.sqlite" ]; then
  sqlite3 "$CODEX_SOURCE/state_5.sqlite" ".backup '$WORK_DIR/.codex/state_5.sqlite'"
fi

if [ -d "$APP_INDEX_SOURCE" ]; then
  find "$APP_INDEX_SOURCE" -maxdepth 1 -type f \
    \( -name 'codex-taskItems-*' -o -name 'codex-taskDetails-*' -o -name 'codex-environments-*' \) \
    -exec cp -p {} "$WORK_DIR/Library/Application Support/com.openai.chat/" \;
fi

# Redact credential-shaped strings from copied task transcripts only. The source
# files under ~/.codex are never modified.
find "$WORK_DIR/.codex/sessions" "$WORK_DIR/.codex/archived_sessions" \
  -type f -name '*.jsonl' -exec perl -pi -e '
    s/sk-[A-Za-z0-9_-]{20,}/[REDACTED_OPENAI_KEY]/g;
    s/github_pat_[A-Za-z0-9_]{20,}/[REDACTED_GITHUB_TOKEN]/g;
    s/gh[pousr]_[A-Za-z0-9]{20,}/[REDACTED_GITHUB_TOKEN]/g;
    s/AKIA[0-9A-Z]{16}/[REDACTED_AWS_ACCESS_KEY]/g;
    s/(authorization.{0,12}bearer\s+)[A-Za-z0-9._-]{16,}/${1}[REDACTED_BEARER_TOKEN]/ig;
    s/(CLAUDE_GATEWAY_API_KEY.{0,12})[A-Za-z0-9._-]{12,}/${1}[REDACTED_GATEWAY_KEY]/ig;
  ' {} +

if find "$WORK_DIR" -type f \( -name 'auth.json' -o -name '*.pem' -o -name '*.key' \) | grep -q .; then
  echo "Unsafe credential-like file detected; refusing to build." >&2
  exit 1
fi

tar -C "$WORK_DIR" -czf "$ARCHIVE_PATH.tmp" .codex 'Library/Application Support/com.openai.chat'
mv "$ARCHIVE_PATH.tmp" "$ARCHIVE_PATH"
split -b 90m -a 4 "$ARCHIVE_PATH" "$PAYLOAD_DIR/codex-migration.part-"
shasum -a 256 "$PAYLOAD_DIR"/codex-migration.part-* > "$PAYLOAD_DIR/SHA256SUMS"
tar -tzf "$ARCHIVE_PATH" >/dev/null
rm -f "$ARCHIVE_PATH"
rm -rf "$WORK_DIR"

echo "Migration payload created in $PAYLOAD_DIR"
du -sh "$PAYLOAD_DIR"
