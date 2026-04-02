---
name: gmail-jd-watcher
description: |
  Check Gmail inbox for new JD emails,
  identify them and trigger Loom's resume-tailor workflow
triggers:
  - Manual invocation via /gmail-jd-watcher
  - Automatic execution when called by cron job
---

# Gmail JD Watcher

## Goal

Scan Gmail inbox, identify emails containing job descriptions (JDs),
and trigger the Loom resume-tailor workflow for each unprocessed JD email.

## Execution Steps

### Step 1: Search Candidate Emails

Use the Gmail MCP tool `gmail_search_messages` to search for unread emails from the last 48 hours
matching any of these conditions:

- Subject contains: job, position, role, opportunity, hiring, engineer, developer, analyst
- Sender domain contains: recruit, talent, hr, people, careers, jobs, lever, greenhouse, workday

Search query:

```
is:unread newer_than:2d (subject:(job OR position OR role OR opportunity OR hiring OR engineer OR developer OR analyst) OR from:(recruit OR talent OR hr OR careers OR jobs))
```

Call the tool like this:

```
gmail_search_messages(query="is:unread newer_than:2d (subject:(job OR position OR role OR opportunity OR hiring OR engineer OR developer OR analyst) OR from:(recruit OR talent OR hr OR careers OR jobs))", max_results=20)
```

If no results are found, skip to Step 6 and report zero candidates.

### Step 2: Determine Whether Each Email Is a Real JD

For each candidate email, use `gmail_read_message` to read the full body. Then evaluate whether the email contains:

- A job title
- Responsibilities or skill requirements
- A company name

**Exclude** emails that are:
- Simple social invitations or networking requests
- Subscription notifications or newsletters without a specific opening
- Already processed (check for the `loom-processed` label on the message)

Use your judgment as an LLM to classify each email. If uncertain, lean toward including it.

### Step 3: Extract JD Content

For each email confirmed as a real JD:

- Extract the email body text as `jd_raw_text`
- Record: sender (`email_from`), subject (`email_subject`), message ID (`email_id`)

### Step 4: Call Loom API

For each confirmed JD email, make an HTTP POST request:

```
POST http://localhost:8000/api/workflow/run
Content-Type: application/json

{
  "workflow": "resume-tailor",
  "data": {
    "jd_raw_text": "<email body text>",
    "source": "gmail",
    "email_id": "<message ID>",
    "email_subject": "<subject>",
    "email_from": "<sender>",
    "language": "en"
  }
}
```

Use `curl` or the WebFetch tool to make this request. Check that the response status is 200 and the body contains a `workflow_run_id`.

If the Loom API is not reachable (connection refused, timeout, 5xx error):
- Save the failed email info to `~/.claude/skills/gmail-jd-watcher/pending.json` for retry on the next run
- Continue processing remaining emails

### Step 5: Mark as Processed

After a successful workflow trigger, use the Gmail MCP to add the label `loom-processed` to the email.

If the label `loom-processed` does not exist yet, create it first using `gmail_list_labels` to check, then note that the user may need to create it manually (Gmail MCP may not support label creation).

### Step 6: Output Report

Print a summary:

```
=== Gmail JD Watcher Report ===
Scanned:    X candidate emails
Identified: Y as real JDs
Triggered:  Z workflow runs
Skipped:    W (reasons listed below)
  - <email subject>: <reason>
Pending:    P (API unreachable, saved for retry)
================================
```

## Error Handling

- **Loom API unavailable**: Save email details to `~/.claude/skills/gmail-jd-watcher/pending.json`. On next run, retry pending items first before scanning new emails.
- **Gmail search fails**: Print the error clearly. Do not mark any emails. Exit gracefully.
- **Single email processing fails**: Log the error, skip the email, continue with the next one.

## Retry Pending Items

At the start of each run, before Step 1, check if `~/.claude/skills/gmail-jd-watcher/pending.json` exists and is non-empty. If so, retry each pending item against the Loom API. Remove successfully retried items from the file.

## Cron Setup (suggest to user after first run)

To run this skill automatically every 30 minutes, the user can set up a cron schedule:

```
claude schedule create --name "gmail-jd-watcher" --schedule "*/30 * * * *" --prompt "/gmail-jd-watcher"
```

Or using the system crontab:

```
*/30 * * * * claude --print "/gmail-jd-watcher" >> ~/.claude/skills/gmail-jd-watcher/cron.log 2>&1
```
