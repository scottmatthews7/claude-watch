# claude-watch

Get smartwatch notifications when Claude Code finishes a task.

```
Claude Code (Stop hook) → notify.sh → Pushover API → Phone → Smartwatch
```

Your watch mirrors phone notifications. This project hooks into Claude Code's Stop event, sends a push notification via Pushover to your phone, and your watch mirrors it. Works with Garmin, Apple Watch, and any smartwatch that mirrors phone notifications. Typical latency is 1–5 seconds.

## Prerequisites

- Smartwatch paired with your phone (Garmin, Apple Watch, etc.)
- [Pushover](https://pushover.net) account ($4.99 one-time, 30-day free trial)
- Pushover app installed on your phone
- Smartwatch notification mirroring enabled (see [Watch Setup](#watch-setup))
- macOS with `jq` installed (`brew install jq`)
- Claude Code CLI

## Setup

```bash
git clone https://github.com/scottmatthews7/claude-watch.git
cd claude-watch
cp .env.example .env
```

Edit `.env` with your Pushover credentials from [pushover.net/dashboard](https://pushover.net/dashboard):

```
PUSHOVER_USER_KEY=your_user_key_here
PUSHOVER_APP_TOKEN=your_app_token_here
```

Then install the hook and test it:

```bash
./install.sh
./test-notification.sh
```

Check your watch — you should see a "Claude Code" notification within a few seconds.

## Uninstall

```bash
./uninstall.sh
```

This removes the Stop hook entry from `~/.claude/settings.json` without affecting other hooks.

## How It Works

1. Claude Code fires a **Stop hook** whenever it finishes responding.
2. The hook pipes JSON (containing `session_id`, `cwd`, and `stop_hook_reason`) to `notify.sh` via stdin.
3. `notify.sh` extracts the project name and stop reason using `jq`, formats a message, and POSTs it to the Pushover API.
4. Pushover delivers a push notification to your phone.
5. Your smartwatch mirrors the notification.

The script is **fail-safe**: if anything goes wrong (missing credentials, network failure, malformed input), it exits silently with code 0 so Claude Code is never affected.

## Environment Variables

| Variable | Description |
|---|---|
| `PUSHOVER_USER_KEY` | Your Pushover user key (from [pushover.net/dashboard](https://pushover.net/dashboard)) |
| `PUSHOVER_APP_TOKEN` | Your Pushover application token (create one at [pushover.net/apps](https://pushover.net/apps)) |

These are stored in `.env` at the project root. The file is gitignored — never commit your credentials.

## Watch Setup

For notifications to reach your watch, Pushover must be allowed in your phone's notification settings and your watch must be set to mirror notifications.

**iPhone + Garmin:**
Settings > Notifications > Pushover > ensure Allow Notifications is on, and set Show Previews to Always. In the Garmin Connect app, ensure your watch is connected and Alerts are enabled on the watch (Settings > Notifications > Alerts).

**iPhone + Apple Watch:**
Pushover notifications mirror automatically if enabled on your iPhone. No extra setup needed.

**Android + Garmin:**
In the Garmin Connect app, go to Settings > Notifications > App Notifications and toggle Pushover on.

**Android + Other watches:**
Ensure Pushover notifications are enabled on your phone. Most Wear OS watches mirror all phone notifications by default.

---

If claude-watch helped you, [leave a star on GitHub](https://github.com/scottmatthews7/claude-watch) — it helps others find it.
