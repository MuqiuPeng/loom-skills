# Loom Skills for Claude Code

Claude Code skills for managing your professional profile, analyzing repos, and generating tailored resumes — powered by [Loom](https://loom.robindev.org).

## Install

```bash
git clone https://github.com/MuqiuPeng/loom-skills.git
cd loom-skills
bash install.sh
```

## Login

In Claude Code:

```
/loom-login
```

Enter your API key when prompted. You only need to do this once per device.

## Skills

| Skill | Description |
|---|---|
| `/loom-login` | Authenticate with Loom API |
| `/setup-profile` | Conversational career coach — add work experience, projects, skills |
| `/analyze-repo` | Analyze a local code repo and generate STAR-structured project bullets |
| `/gmail-jd-watcher` | Check Gmail for job description emails |

## How it works

All data is stored in your Loom account (cloud). Skills communicate with the Loom API via authenticated HTTPS calls. No data is stored locally except the auth token in `~/.loom/auth.json`.
