# Codex local task migration bundle

This private repository transports a one-time, sanitized snapshot of local Codex task data.
It is not intended for bidirectional sync.

## Included

- `~/.codex/sessions`
- `~/.codex/archived_sessions`
- `~/.codex/attachments`
- `~/.codex/generated_images`
- `~/.codex/memories`
- user-installed skills and rules
- session index and a consistent snapshot of the Codex state database
- Codex task-list index files from `~/Library/Application Support/com.openai.chat`

## Intentionally excluded

- `~/.codex/auth.json` and all login credentials
- browser and computer-use profiles
- shell snapshots and transcription/dictation history
- IPC files, writer locks, caches, logs, temporary files, plugin binaries
- generated dependency/runtime caches

## Restore on the new Mac

1. Install Codex and sign in with the same OpenAI account.
2. Quit Codex completely.
3. Clone this private repository.
4. Run `bash restore_codex.sh` from the repository.
5. Reopen Codex and verify several tasks and archived tasks.
6. Copy or clone the original project directories referenced by those tasks.

The task transcripts alone do not contain the complete project working trees.

