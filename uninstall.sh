#!/bin/bash
# Uninstall claude-watch: remove Stop and Notification hooks from Claude Code settings.

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

HOOK_EVENTS=("Stop" "Notification")
FOUND=false

for event in "${HOOK_EVENTS[@]}"; do
  MATCH_COUNT=$(jq --arg cmd "${NOTIFY_SCRIPT}" --arg evt "${event}" '
    [.hooks[$evt] // [] | .[] | select(.hooks[]?.command == $cmd)] | length
  ' "${SETTINGS_FILE}")
  if [[ "${MATCH_COUNT}" -gt 0 ]]; then
    FOUND=true
    break
  fi
done

if [[ "${FOUND}" != "true" ]]; then
  echo "claude-watch hook not found in settings"
  exit 0
fi

# Remove matching entries from both hook arrays, then prune empty structures.
jq --arg cmd "${NOTIFY_SCRIPT}" '
  # Remove entries whose hooks array contains a matching command
  .hooks.Stop = [(.hooks.Stop // [])[] | select((.hooks // []) | all(.command != $cmd))]
  | .hooks.Notification = [(.hooks.Notification // [])[] | select((.hooks // []) | all(.command != $cmd))]

  # Remove empty arrays
  | if (.hooks.Stop | length) == 0 then del(.hooks.Stop) else . end
  | if (.hooks.Notification | length) == 0 then del(.hooks.Notification) else . end

  # If hooks object is now empty, remove the key
  | if (.hooks | length) == 0 then del(.hooks) else . end
' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp"

mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Uninstalled. Smartwatch notifications disabled."
