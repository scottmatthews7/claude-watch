#!/bin/bash
# notify.sh — claude-watch: send a Pushover notification when Claude Code finishes.
# Called by Claude Code with JSON on stdin. Must never produce output or exit non-zero.

# This script must NEVER exit non-zero or produce output. No set -e.

# Resolve the directory this script lives in, then source config.
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")" || exit 0

# Source config.sh for Pushover credentials. If it fails (missing .env, missing
# creds), silently exit 0 — a notification failure must never break Claude Code.
# shellcheck source=config.sh
if ! source "${SCRIPT_DIR}/config.sh" 2>/dev/null; then
    exit 0
fi

# Read all of stdin into a variable (Claude Code pipes hook JSON here).
stdin_payload="$(cat)" || stdin_payload=""

# Extract fields with jq. If jq fails or fields are missing, use safe defaults.
stop_reason="$(echo "${stdin_payload}" | jq -r '.stop_hook_reason // "unknown"' 2>/dev/null)" || stop_reason="unknown"
project_name="$(echo "${stdin_payload}" | jq -r '.cwd // ""' 2>/dev/null)" || project_name=""
project_name="$(basename "${project_name:-unknown}")"

# Build the notification message.
message="Done in ${project_name}"

# Send the Pushover notification. Suppress all output. Exit 0 regardless of outcome.
# Use --form-string to safely encode special characters in the message.
# Note: the notification icon is set at the Pushover application level, not per-message.
curl -s -o /dev/null \
    --max-time 10 \
    --form-string "token=${PUSHOVER_APP_TOKEN}" \
    --form-string "user=${PUSHOVER_USER_KEY}" \
    --form-string "title=Claude Code" \
    --form-string "message=${message}" \
    "https://api.pushover.net/1/messages.json" \
    2>/dev/null || true

exit 0
