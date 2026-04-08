#!/bin/bash
# install.sh — Register the claude-watch Stop hook in Claude Code settings.
#
# Adds a Stop hook entry pointing to notify.sh in ~/.claude/settings.json.
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
# Check if the hook is already installed.
# ---------------------------------------------------------------------------
ALREADY_INSTALLED=$(
    jq --arg cmd "${NOTIFY_PATH}" '
        [.hooks.Stop // [] | .[] | .hooks[]? | select(.command == $cmd)] | length > 0
    ' "${SETTINGS_FILE}"
)

if [[ "${ALREADY_INSTALLED}" == "true" ]]; then
    echo "Already installed."
    exit 0
fi

# ---------------------------------------------------------------------------
# Build the new hook entry and append it to .hooks.Stop[].
# ---------------------------------------------------------------------------
NEW_ENTRY=$(jq -n --arg cmd "${NOTIFY_PATH}" '{
    matcher: "",
    hooks: [
        {
            type: "command",
            command: $cmd
        }
    ]
}')

jq --argjson entry "${NEW_ENTRY}" '
    .hooks //= {} |
    .hooks.Stop //= [] |
    .hooks.Stop += [$entry]
' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
    && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "claude-watch installed successfully."
echo ""
echo "Next steps:"
echo "  1. cp ${SCRIPT_DIR}/.env.example ${SCRIPT_DIR}/.env"
echo "  2. Fill in your Pushover credentials in .env"
echo "  3. Run ./test-notification.sh to verify"
echo ""
echo "Like it? Star the repo: https://github.com/scottmatthews/claude-watch"
