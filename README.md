# claude-watch

Get smartwatch notifications when Claude Code finishes a task or needs your attention.

```
Claude Code (hook) → notify.sh → Pushover API → Phone → Smartwatch
```

Your watch mirrors phone notifications. This project hooks into Claude Code's **Stop** and **Notification** events, sends a push notification via Pushover to your phone, and your watch mirrors it. Works with Garmin, Apple Watch, and any smartwatch that mirrors phone notifications. Typical latency is 1-5 seconds.

**Stop** fires when Claude finishes responding. **Notification** fires when Claude needs your attention — for example, when it's waiting for you to approve a tool permission.

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

Then install the hooks and test:

```bash
./install.sh
./test-notification.sh
```

Check your watch — you should see a "Claude Code" notification within a few seconds.

### Custom Notification Icon

To set a custom icon that appears on your watch, upload an image as the application icon in your [Pushover app settings](https://pushover.net/apps). This icon shows on all notifications, including on your smartwatch. Per-message image attachments don't get forwarded to watches — only the app-level icon does.

## Uninstall

```bash
./uninstall.sh
```

This removes the Stop and Notification hook entries from `~/.claude/settings.json` without affecting other hooks.

## How It Works

1. Claude Code fires a **Stop hook** when it finishes responding, and a **Notification hook** when it needs your attention (e.g. permission prompts).
2. The hook pipes JSON (containing `session_id`, `cwd`, and `stop_hook_reason`) to `notify.sh` via stdin.
3. `notify.sh` extracts the project name using `jq`, formats a message, and POSTs it to the Pushover API.
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

## Troubleshooting

**No notifications at all**

- Run `./test-notification.sh` — if it fails, your Pushover credentials are wrong. Double-check `.env` against [pushover.net/dashboard](https://pushover.net/dashboard).
- Check that `jq` is installed: `which jq`. If missing, run `brew install jq`.
- Verify the hook is registered: `cat ~/.claude/settings.json | jq '.hooks.Stop, .hooks.Notification'`. You should see entries pointing to `notify.sh`.

**Phone gets the notification but watch doesn't**

- Open your phone's notification settings and confirm Pushover is allowed to send notifications with previews.
- In your smartwatch companion app (Garmin Connect, Watch app, etc.), make sure notification mirroring is enabled for Pushover specifically.
- Some watches suppress notifications when in Do Not Disturb or sleep mode.
- Restart the companion app and/or re-pair your watch if mirroring has stopped working.

**Notification arrives on Stop but not on permission prompts**

- You may be on an older version that only registered the Stop hook. Re-run `./install.sh` — it will add the Notification hook if missing.
- Verify both hooks are registered: `cat ~/.claude/settings.json | jq '.hooks.Stop, .hooks.Notification'`.

**Custom icon not showing on watch**

- Pushover's per-message `attachment` parameter only shows in the phone app, not on watches. The watch displays the **application-level icon** instead.
- Upload your icon at [pushover.net/apps](https://pushover.net/apps) by editing your Claude Code application. This is the only way to get a custom icon on the watch.

**Duplicate notifications**

- Run `./install.sh` again — it's idempotent and won't add duplicate hook entries. If you see duplicates, run `./uninstall.sh` then `./install.sh` to start clean.

**Notifications are delayed (>10 seconds)**

- This is usually a phone or watch connectivity issue, not a Pushover issue. Check that your watch has a stable Bluetooth connection to your phone.
- Pushover itself typically delivers within 1-2 seconds. You can verify by checking the Pushover app on your phone — if it arrives there quickly, the delay is in watch mirroring.

---

If claude-watch helped you, [leave a star on GitHub](https://github.com/scottmatthews7/claude-watch) — it helps others find it.
