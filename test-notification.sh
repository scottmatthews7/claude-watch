#!/bin/bash
# test-notification.sh — Send a test notification to verify Pushover + Garmin setup.

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

if ! source "${SCRIPT_DIR}/config.sh"; then
    echo "Failed to load config. Make sure .env exists with PUSHOVER_USER_KEY and PUSHOVER_APP_TOKEN."
    exit 1
fi

echo "Sending test notification to Pushover..."

response=$(curl -s -w "\n%{http_code}" \
    --form-string "token=${PUSHOVER_APP_TOKEN}" \
    --form-string "user=${PUSHOVER_USER_KEY}" \
    --form-string "title=Claude Code (Test)" \
    --form-string "message=If you see this on your Garmin, setup is working!" \
    "https://api.pushover.net/1/messages.json")

body=$(echo "$response" | sed '$d')
code=$(echo "$response" | tail -n1)

if [[ "$code" == "200" ]]; then
    echo "Success! Check your phone and watch for the notification."
    echo ""
    echo "If claude-watch helped you, leave a star: https://github.com/scottmatthews7/claude-watch"
else
    echo "Failed with HTTP status: $code"
    echo "$body"
    exit 1
fi
