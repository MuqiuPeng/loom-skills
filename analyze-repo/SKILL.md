---
name: analyze-repo
description: |
  Deep analysis of a local code repository. Extracts tech stack,
  architecture, and project structure from code, then asks targeted
  questions to generate complete STAR-structured bullets.
  Stores the result as a Project in Loom Profile.
  Unlike /setup-profile (conversation-first, code-assist),
  this skill is code-first, conversation-assists.
triggers:
  - User provides a local path
  - User says "analyze my project" / "analyze this repo"
  - Manual invocation via /analyze-repo <path>
---

# Analyze Repo Skill

## Phase 1: Project Overview

Read up to 20 files, prioritized in this order:

1. `CLAUDE.md` or `instruction.md` (if present — read first, they contain project context)
2. `README.md` / `README.rst`
3. First dependency file found:
   - `package.json` / `requirements.txt` / `pyproject.toml`
   - `go.mod` / `Cargo.toml` / `build.gradle` / `pom.xml`
4. Root directory file listing (`ls`, non-recursive)
5. Main source directory structure — one level deep only:
   - `src/` / `app/` / `lib/` / `core/` / `cmd/` / `internal/`
   - List contents, do NOT read file bodies yet
6. Config files if they exist:
   - `docker-compose.yml` / `Dockerfile`
   - `alembic.ini` / `tsconfig.json` / `next.config.js`
   - CI config: `.github/workflows/`, `Makefile`

**Never read**: `node_modules/`, `.git/`, `dist/`, `build/`, `__pycache__/`, `.env`, `.env.*`, binary files, lock files

## Phase 2: Tech Stack Extraction

From the dependency files, extract and categorize:

| Category | Examples |
|----------|---------|
| Frameworks | React, Next.js, FastAPI, Django, Express, Spring |
| Databases | PostgreSQL, MySQL, MongoDB, Redis, Elasticsearch |
| Cloud / Infra | AWS SDK, GCP, Azure, Docker, Kubernetes, Terraform |
| AI / ML | anthropic, openai, torch, transformers, langchain |
| Testing | pytest, jest, vitest, cypress |
| Notable others | Kafka, Celery, GraphQL, gRPC |

For each significant technology, determine:
- What problem does it solve in THIS project?
- What is its relationship to the other technologies? (this informs `ecosystem_group`)

## Phase 3: Present Analysis Report

Show the user what you found. Keep it concise:

```
I've analyzed [project name]. Here's what I found:

**Tech Stack**: Python, FastAPI, PostgreSQL, Claude API, SQLAlchemy, Alembic
**Project Type**: AI-powered automation tool
**Architecture**: Monolith with pipeline engine, 4-step workflow
**From README**: [one-sentence description, or "No README found"]

Before I write the bullets, I have a few questions:
```

Then proceed to Phase 4.

## Output Formatting

**Bold** (`**text**`): Technology names, tools,
frameworks, and libraries only.
Examples: **Python**, **FastAPI**, **PostgreSQL**,
**AWS Lambda**, **Next.js**

*Italic* (`*text*`): Proper nouns — company names,
project names, product names.
Examples: *Jiesan Technology*, *StockViewer*,
*University of Wollongong*

`Code` (backticks): File paths, API endpoints,
commands, specific values.
Examples: `/api/profile`, `content_en`,
`loom db-init`

Blank lines between sections for breathing room.
Never output walls of plain text.
Never bold company names, dates, or locations.
Never italicize technology names.

## Phase 4: Targeted Questions

Ask questions one at a time, in priority order. Skip any question whose answer is already clear from the code.

### Always ask (if not inferable from code):

1. **Business value** (most important):
   "Who uses this? What problem does it solve for them?"

2. **User's role**:
   "What's your role on this project — sole developer, tech lead, team member?"

### Ask if relevant (based on what the code reveals):

- "Do you have any user counts, data volumes, or performance metrics?"
- "I see you chose [key technology]. Why that over alternatives?"
- "What was the hardest technical challenge you faced on this?"
- "Is this in production, still in development, or completed?"
- "I noticed [interesting pattern in code]. Can you tell me more about why?"

### Stop asking when:

- You have enough for 3-5 strong bullets
- The user signals they're done ("that's it", "nothing else")
- You've asked 5+ questions already

## Phase 5: Generate STAR Bullets

Combine code analysis + user answers to generate 3-5 bullets.

### Standards:

**First bullet = business value.** Always.
Format: [quantified result or user value] + [achieved by what means]

**Tech stack = ecosystem narrative, not tag list.**
Every technology mentioned must explain what problem it solved and how it connects to others.

**Action verbs by level:**
- Architecture: Architected / Designed / Led
- Implementation: Built / Implemented / Developed
- Optimization: Reduced / Improved / Accelerated
- NEVER: Assisted / Participated / Helped

### Show bullets for review:

```
Here are the bullets I'd suggest:

1. [business_impact] Enabled retail investors to access quantitative...
2. [technical_design] Architected a 4-step pipeline engine with...
3. [scale] Reduced resume generation latency from...

Does this look right? Any changes before I save?
```

Wait for user confirmation or edits before saving.

## Phase 6: Store After Confirmation

Once the user approves (or provides edits), save via Loom API.
All text fields must include both `_en` and `_zh` — translate in the conversation,
do NOT rely on backend translation.

### Authentication

Before making any API call, you MUST have a valid auth token.

Read credentials from `~/.loom/auth.json`:
```json
{"api_key": "...", "api_url": "https://loom-api.robindev.org"}
```

If this file does not exist or is empty, tell the user:
"You need to log in first. Run /loom-login to authenticate."
Then STOP — do not proceed without authentication.

If the file exists, use the `api_url` from it as the base URL
(instead of the hardcoded URLs below), and add this header
to ALL requests:
```
Authorization: Bearer <api_key from auth.json>
```

Fallback: if `~/.loom/auth.json` doesn't exist but
`/Users/guanshunpeng/projects/Loom/.env` exists (local machine),
read `LOOM_API_KEY` from it and use `http://localhost:8001` as the URL.

### 6a. Check for existing project

Before saving, check if a project with the same `local_repo_path` already exists:

```
GET https://loom-api.robindev.org/api/profile?lang=en
```

Look through `projects` for matching `local_repo_path`.

If found:
"I found an existing entry for *{project_name}* last analyzed on {last_analyzed_at}.
Do you want to update the existing entry, create a new one, or cancel?"

If user chooses Update:
- Use `PATCH /api/profile/project/{id}` instead of POST
- Preserve bullets with confidence="user_edited"

### 6b. Save the project

```
POST https://loom-api.robindev.org/api/profile/project
Content-Type: application/json

{
  "name_en": "<project name>",
  "name_zh": "<project name in Chinese>",
  "description_en": "<one-sentence description>",
  "description_zh": "<one-sentence description in Chinese>",
  "role_en": "<user's role>",
  "role_zh": "<user's role in Chinese>",
  "local_repo_path": "<absolute path, expand ~ before sending>",
  "tech_stack": [
    {"name": "FastAPI", "role": "REST API framework", "ecosystem_group": "backend"}
  ],
  "bullets": [
    {
      "content_en": "...",
      "content_zh": "...",
      "type": "business_impact",
      "priority": 1,
      "star_data": {
        "situation": "...",
        "task": "...",
        "action": "...",
        "result_quantified": "...",
        "result_qualitative": "..."
      }
    }
  ]
}
```

### 6b. Auto-extract and save skills

After saving the project, extract each significant technology from the
tech_stack and save it as a Skill. Categorize by **usage scenario**, NOT
by which project it came from.

Standard categories:
- `Backend` — server-side languages, frameworks, ORMs (Python, FastAPI, SQLAlchemy)
- `Frontend` — UI frameworks, styling, charting (React, Next.js, Tailwind CSS)
- `Database` — data stores, caches (PostgreSQL, Redis, MongoDB)
- `AI/ML` — LLM APIs, ML frameworks (Anthropic Claude, OpenAI, PyTorch)
- `DevOps/Infra` — containers, CI/CD, cloud (Docker, AWS, Terraform)
- `Testing` — test frameworks (pytest, Jest)
- `Data Processing` — data libraries (pandas, NumPy, Spark)

For each technology:
```
POST https://loom-api.robindev.org/api/profile/skill
Content-Type: application/json

{
  "name": "FastAPI",
  "level": "proficient",
  "category": "Backend",
  "context_en": "REST API serving profile CRUD and workflow execution",
  "context_zh": "REST API 提供档案增删改查和工作流执行"
}
```

Rules:
- **Deduplicate**: Before saving, check the existing skills in the profile
  (`GET /api/profile`). If a skill already exists, skip it.
- **Level**: Use `expert` for primary/core tech, `proficient` for actively used,
  `familiar` for supporting/peripheral.
- **Context**: Describe what the tech does in THIS project, not generic knowledge.

After saving, confirm:
"Saved [project name] to your profile with N skills. You can view it at http://localhost:3001"

## Key Difference from /setup-profile

| | /setup-profile | /analyze-repo |
|---|---|---|
| Primary input | Conversation | Code |
| Code reading | Light (config + README) | Deep (structure + deps + patterns) |
| Conversation | Drives the process | Fills gaps after analysis |
| Save timing | Silent, when ready | After user confirms bullets |
| Best for | Free-form career exploration | Deliberately documenting one project |

## Example Session

```
User: /analyze-repo ~/projects/loom

Claude: [reads files]

Claude: I've analyzed Loom. Here's what I found:
  **Tech Stack**: Python, FastAPI, PostgreSQL, Claude API, Next.js, SWR
  **Project Type**: AI-powered workflow automation engine
  **Architecture**: Pipeline engine with 4-step resume-tailor workflow,
    bilingual data layer, Gmail integration via MCP
  **From README**: [description]

  Who's the target user for this? What problem are you solving?

User: It's for job seekers who want tailored resumes...

Claude: Got it. Do you have any metrics — how many resumes generated,
  or time savings compared to manual tailoring?

User: Still in development, no production metrics yet.

Claude: Here are the bullets I'd suggest:

  1. [business_impact] Built an AI-native workflow engine that
     automates resume tailoring for job seekers — extracting JD
     requirements via Claude Haiku and matching them against a
     structured STAR-format profile to generate targeted resumes

  2. [technical_design] Architected a bilingual data layer with
     automatic EN→ZH translation via Claude Haiku, preserving
     technical terms across 80+ protected keywords while maintaining
     natural Chinese resume language

  3. [implementation] Developed a 4-step pipeline engine
     (parse-jd → match-profile → select-bullets → generate-resume)
     with pluggable steps, PostgreSQL persistence, and Alembic
     migrations for schema evolution

  Does this look right? Any changes before I save?

User: Looks good, save it.

Claude: Saved Loom to your profile. You can view it at http://localhost:3001
```
