#!/bin/bash
# Install the /captain skill into ~/.claude/skills/captain with your values filled in.
set -euo pipefail
cd "$(dirname "$0")"
[ -f config/captain.env ] || { echo "Copy config/captain.env.example to config/captain.env and fill it in first."; exit 1; }
source config/captain.env
DEST=~/.claude/skills/captain
mkdir -p "$DEST" "$PROJECT_DIR/scripts/pw"
cp skill/captain/SKILL.md "$DEST/"; cp skill/captain/scripts/* "$DEST/"
cp scripts/*.sh scripts/*.py "$PROJECT_DIR/scripts/" 2>/dev/null || true
cp scripts/pw/*.mjs scripts/pw/package.json "$PROJECT_DIR/scripts/pw/"
mkdir -p "$PROJECT_DIR/corpus/formats"; cp templates/*-format.md "$PROJECT_DIR/corpus/formats/"
render() {
  sed -i '' -e "s#__PROJECT_DIR__#$PROJECT_DIR#g" -e "s#__GH_USER__#$GH_USER#g" -e "s#__GH_REPO__#$GH_REPO#g" \
    -e "s#__REPO_CHECKOUT__#$REPO_CHECKOUT#g" -e "s#__SCHOOL_USER__#$SCHOOL_USER#g" -e "s#__SCHOOL_EMAIL__#$SCHOOL_EMAIL#g" \
    -e "s#__VM_HOST__#$VM_HOST#g" -e "s#__VM_HOSTNAME__#$VM_HOSTNAME#g" -e "s#__SP_HOST__#$SP_HOST#g" \
    -e "s#__SP_SITE_NAME__#$SP_SITE_NAME#g" -e "s#__YOUR_FOLDER__#$YOUR_FOLDER#g" -e "s#__TEAMS_GROUP_CHAT__#$TEAMS_GROUP_CHAT#g" \
    -e "s#STUDENT#$VPN_PROFILE#g" -e "s#gmu-vpn#$VPN_KEYCHAIN_ITEM#g" "$@"
}
render "$DEST"/* "$PROJECT_DIR"/scripts/pw/{teams-send,teams-dm,sp-upload,sp-download,sp-list}.mjs "$PROJECT_DIR"/corpus/formats/*.md
(cd "$PROJECT_DIR/scripts/pw" && command -v npm >/dev/null && npm install --silent && npx playwright install chromium >/dev/null) || echo "Playwright not installed yet; /captain will offer it."
chmod +x "$DEST"/*.sh "$DEST"/*.py
echo "Installed to $DEST. Next: copy templates/CLAUDE.md.template to $PROJECT_DIR/CLAUDE.md, edit it, then run /captain in Claude Code inside cmux."
