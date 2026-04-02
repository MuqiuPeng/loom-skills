---
name: loom-login
description: |
  Authenticate with the Loom API. Required before using
  /setup-profile, /analyze-repo, or any other Loom skill
  on a remote device.
triggers:
  - User says "loom login" / "login to loom"
  - Manual invocation via /loom-login
---

# Loom Login

## Purpose

Authenticate with the Loom API so that other Loom skills
(`/setup-profile`, `/analyze-repo`) can make authenticated
API calls. This is required when using Claude Code on a
device that doesn't have the Loom `.env` file locally.

## Flow

### Step 1: Check if already logged in

Read the auth file at `~/.loom/auth.json`:

```json
{
  "api_key": "...",
  "api_url": "https://loom-api.robindev.org",
  "validated_at": "2026-04-03T..."
}
```

If the file exists and has an `api_key`, validate it:

```bash
curl -s -H "Authorization: Bearer <api_key>" \
  <api_url>/api/health
```

If it returns `{"status": "healthy"}`:
  "You're already logged in to Loom. API: <api_url>"
  Done — no further action needed.

If it fails or file doesn't exist, proceed to Step 2.

### Step 2: Check local .env file

If running on the same machine as Loom, try reading
the API key from `/Users/guanshunpeng/projects/Loom/.env`
(the line starting with `LOOM_API_KEY=`).

If found, save it to `~/.loom/auth.json` and validate.
If valid: "Auto-logged in from local .env file."
Done.

### Step 3: Prompt for credentials

If no local .env is available (remote device), ask:

"Enter your Loom API key:"

The user will paste the key. Then:

1. Ask for the API URL (default: `https://loom-api.robindev.org`):
   "API URL (press Enter for default: https://loom-api.robindev.org):"

2. Validate the key:
   ```bash
   curl -s -H "Authorization: Bearer <key>" <url>/api/health
   ```

3. If valid, save to `~/.loom/auth.json`:
   ```json
   {
     "api_key": "<key>",
     "api_url": "<url>",
     "validated_at": "<ISO timestamp>"
   }
   ```
   "Logged in successfully. You can now use /setup-profile and /analyze-repo."

4. If invalid:
   "Invalid API key. Please check and try again."

### Step 4: Verify profile access

After successful login, fetch and display the profile:

```bash
curl -s -H "Authorization: Bearer <key>" <url>/api/profile?lang=en
```

Show a brief summary:
"Connected as: <name> (<email>)
 Profile: <N> experiences, <M> projects, <K> skills"

## Auth File Location

`~/.loom/auth.json`

This file is gitignored and local to each device.
Other Loom skills read from this file for authentication.

## Logout

If the user says "loom logout" or "logout from loom":

1. Delete `~/.loom/auth.json`
2. "Logged out from Loom."
