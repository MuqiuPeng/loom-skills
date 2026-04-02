#!/bin/bash
# Install Loom Claude Code Skills
# Usage: git clone https://github.com/MuqiuPeng/loom-skills.git && cd loom-skills && bash install.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

for skill in loom-login setup-profile analyze-repo gmail-jd-watcher; do
  if [ -d "$SCRIPT_DIR/$skill" ]; then
    rm -rf "$SKILLS_DIR/$skill"
    ln -s "$SCRIPT_DIR/$skill" "$SKILLS_DIR/$skill"
    echo "  Installed: /$skill"
  fi
done

echo ""
echo "Done! In Claude Code, run /loom-login to authenticate."
