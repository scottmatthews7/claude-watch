#!/bin/bash
# Uninstall claude-watch: remove the Stop hook from Claude Code settings.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SCRIPT="${SCRIPT_DIR}/notify.sh"
SETTINGS_FILE="${HOME}/.claude/settings.json"

if [[ ! -f "${SETTINGS_FILE}" ]]; then
  echo "Nothing to uninstall"
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

# Check whether any Stop hook entry contains a command matching our notify.sh path.
MATCH_COUNT=$(jq --arg cmd "${NOTIFY_SCRIPT}" '
  [.hooks.Stop // [] | .[] | select(.hooks[]?.command == $cmd)] | length
' "${SETTINGS_FILE}")

if [[ "${MATCH_COUNT}" -eq 0 ]]; then
  echo "garmin-claude hook not found in settings"
  exit 0
fi

# Remove matching entries from the Stop array, then prune empty structures.
jq --arg cmd "${NOTIFY_SCRIPT}" '
  # Remove Stop entries whose hooks array contains a matching command
  .hooks.Stop = [.hooks.Stop[] | select((.hooks // []) | all(.command != $cmd))]

  # If Stop array is now empty, remove the key
  | if (.hooks.Stop | length) == 0 then del(.hooks.Stop) else . end

  # If hooks object is now empty, remove the key
  | if (.hooks | length) == 0 then del(.hooks) else . end
' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp"

mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Uninstalled. Garmin notifications disabled."
