#!/bin/bash
# config.sh — Load and validate Pushover credentials for claude-watch.
# Sourced by other scripts; exits on missing credentials.

GARMIN_CLAUDE_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

if [[ -f "${GARMIN_CLAUDE_DIR}/.env" ]]; then
    # shellcheck source=/dev/null
    source "${GARMIN_CLAUDE_DIR}/.env"
fi

if [[ -z "${PUSHOVER_USER_KEY:-}" ]]; then
    echo "Error: PUSHOVER_USER_KEY is not set. Copy .env.example to .env and fill in your credentials." >&2
    return 1 2>/dev/null || exit 1
fi

if [[ -z "${PUSHOVER_APP_TOKEN:-}" ]]; then
    echo "Error: PUSHOVER_APP_TOKEN is not set. Copy .env.example to .env and fill in your credentials." >&2
    return 1 2>/dev/null || exit 1
fi

export PUSHOVER_USER_KEY
export PUSHOVER_APP_TOKEN
