#!/bin/bash
# install.sh — Register claude-watch hooks in Claude Code settings.
#
# Adds Stop and Notification hook entries pointing to notify.sh in ~/.claude/settings.json.
# Idempotent: safe to run multiple times. Preserves all existing settings and hooks.

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve the absolute path to notify.sh (lives next to this script).
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_PATH="${SCRIPT_DIR}/notify.sh"

if [[ ! -f "${NOTIFY_PATH}" ]]; then
    echo "Error: notify.sh not found at ${NOTIFY_PATH}" >&2
    exit 1
fi

# Ensure notify.sh is executable.
chmod +x "${NOTIFY_PATH}"

# ---------------------------------------------------------------------------
# Check for jq.
# ---------------------------------------------------------------------------
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed. Install it with: brew install jq" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Ensure ~/.claude/ and settings.json exist.
# ---------------------------------------------------------------------------
SETTINGS_DIR="${HOME}/.claude"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"

mkdir -p "${SETTINGS_DIR}"

if [[ ! -f "${SETTINGS_FILE}" ]]; then
    echo '{}' > "${SETTINGS_FILE}"
fi

# ---------------------------------------------------------------------------
# Install the hook for each event type (Stop + Notification).
# Stop fires when Claude finishes responding.
# Notification fires when Claude needs attention (e.g. permission prompts).
# ---------------------------------------------------------------------------
HOOK_EVENTS=("Stop" "Notification")

ALREADY_ALL_INSTALLED=true
for event in "${HOOK_EVENTS[@]}"; do
    INSTALLED=$(
        jq --arg cmd "${NOTIFY_PATH}" --arg evt "${event}" '
            [.hooks[$evt] // [] | .[] | .hooks[]? | select(.command == $cmd)] | length > 0
        ' "${SETTINGS_FILE}"
    )
    if [[ "${INSTALLED}" != "true" ]]; then
        ALREADY_ALL_INSTALLED=false
        break
    fi
done

if [[ "${ALREADY_ALL_INSTALLED}" == "true" ]]; then
    echo "Already installed."
    exit 0
fi

NEW_ENTRY=$(jq -n --arg cmd "${NOTIFY_PATH}" '{
    matcher: "",
    hooks: [
        {
            type: "command",
            command: $cmd
        }
    ]
}')

for event in "${HOOK_EVENTS[@]}"; do
    INSTALLED=$(
        jq --arg cmd "${NOTIFY_PATH}" --arg evt "${event}" '
            [.hooks[$evt] // [] | .[] | .hooks[]? | select(.command == $cmd)] | length > 0
        ' "${SETTINGS_FILE}"
    )
    if [[ "${INSTALLED}" != "true" ]]; then
        jq --argjson entry "${NEW_ENTRY}" --arg evt "${event}" '
            .hooks //= {} |
            .hooks[$evt] //= [] |
            .hooks[$evt] += [$entry]
        ' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
            && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"
    fi
done

echo "claude-watch installed successfully."
echo ""
echo "Next steps:"
echo "  1. cp ${SCRIPT_DIR}/.env.example ${SCRIPT_DIR}/.env"
echo "  2. Fill in your Pushover credentials in .env"
echo "  3. Run ./test-notification.sh to verify"
echo ""
echo "Like it? Star the repo: https://github.com/scottmatthews/claude-watch"
