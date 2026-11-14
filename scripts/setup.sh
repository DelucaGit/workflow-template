#!/usr/bin/env bash
# setup.sh – sätter upp ett repo enligt WORKFLOW.md.
#
# Körs EN gång, inifrån det repo-bibliotek som ska sättas upp:
#   cd "C:/Users/malak/Desktop/Coding Projects/<projekt>"
#   bash "<sökväg till workflow-template>/scripts/setup.sh"
#
# Skriptet stannar vid första felet och löser inget på egen hand (regel 12).
# Det skyddar INTE main (kräver GitHub Pro för privata repon, se WORKFLOW.md).

set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c "import sys" >/dev/null 2>&1; then PY="$c"; break; fi
done

fail() { echo "FEL: $1" >&2; echo "Skriptet stannar. Ingenting mer har ändrats efter detta steg." >&2; exit 1; }

[ -n "$PY" ] || fail "Python hittades inte (behövs för att läsa labels.json)."
command -v gh >/dev/null || fail "GitHub CLI (gh) hittades inte."
gh auth status >/dev/null 2>&1 || fail "gh är inte inloggad."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Kör skriptet inifrån ett git-repo."

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)" || fail "Hittade inget GitHub-repo för den här mappen."
OWNER="${REPO%%/*}"
NAME="${REPO##*/}"
echo "Sätter upp: $REPO"

# --- 1. Labels --------------------------------------------------------------
echo "[1/5] Labels"
gh label list --limit 200 --json name -q '.[].name' | while IFS= read -r l; do
  [ -n "$l" ] && gh label delete "$l" --yes >/dev/null
done
"$PY" - "$TEMPLATE_DIR/labels.json" <<'PYEOF'
import json, subprocess, sys
for l in json.load(open(sys.argv[1], encoding="utf-8")):
    subprocess.run(["gh", "label", "create", l["name"], "--color", l["color"],
                    "--description", l["description"], "--force"],
                   check=True, stdout=subprocess.DEVNULL)
PYEOF

# --- 2. Merge-inställningar --------------------------------------------------
echo "[2/5] Endast squash merge, radera branch efter merge"
gh api -X PATCH "repos/$REPO" \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=PR_BODY >/dev/null

# --- 3. Mallar ---------------------------------------------------------------
echo "[3/5] Mallar och WORKFLOW.md"
copy_file() { # $1 = källa relativt mallrepot, samma sökväg i målet
  local src="$TEMPLATE_DIR/$1"
  if [ -e "$1" ] && ! cmp -s "$src" "$1"; then
    fail "$1 finns redan och skiljer sig från mallen. Jag skriver inte över den utan ditt besked."
  fi
  mkdir -p "$(dirname "$1")"
  cp "$src" "$1"
}
(cd "$TEMPLATE_DIR" && ls .github/ISSUE_TEMPLATE/*.yml) | while IFS= read -r f; do copy_file "$f"; done
copy_file .github/pull_request_template.md
copy_file WORKFLOW.md

# --- 4. Project ----------------------------------------------------------------
echo "[4/5] GitHub Project"
PROJ_JSON="$(gh project create --owner "$OWNER" --title "$NAME" --format json)" \
  || fail "Kunde inte skapa Project. Saknas scope 'project'? (gh auth refresh -s project)"
PROJ_ID="$(echo "$PROJ_JSON" | "$PY" -c 'import json,sys;print(json.load(sys.stdin)["id"])')"
PROJ_NUM="$(echo "$PROJ_JSON" | "$PY" -c 'import json,sys;print(json.load(sys.stdin)["number"])')"
gh project link "$PROJ_NUM" --owner "$OWNER" --repo "$REPO" >/dev/null

STATUS_ID="$(gh project field-list "$PROJ_NUM" --owner "$OWNER" --format json \
  -q '.fields[] | select(.name=="Status") | .id')"
[ -n "$STATUS_ID" ] || fail "Hittade inget Status-fält i Projectet."

"$PY" - "$STATUS_ID" "$PROJ_ID" <<'PYEOF'
import datetime, json, subprocess, sys
status_id, proj_id = sys.argv[1], sys.argv[2]

def graphql(query, variables):
    p = subprocess.run(["gh", "api", "graphql", "--input", "-"],
                       input=json.dumps({"query": query, "variables": variables}),
                       capture_output=True, text=True)
    if p.returncode != 0 or '"errors"' in p.stdout:
        sys.exit("GraphQL-fel: " + (p.stdout or p.stderr))

# Status: de fem värdena från WORKFLOW.md
opts = [("Backlog", "GRAY"), ("Ready", "BLUE"), ("In progress", "YELLOW"),
        ("In review", "ORANGE"), ("Done", "GREEN")]
graphql("""mutation($id:ID!,$o:[ProjectV2SingleSelectFieldOptionInput!]){
  updateProjectV2Field(input:{fieldId:$id,singleSelectOptions:$o}){clientMutationId}}""",
        {"id": status_id,
         "o": [{"name": n, "color": c, "description": ""} for n, c in opts]})

# Sprint: Iteration-fält, 1 veckas sprintar från nästa måndag, åtta stycken
d = datetime.date.today()
d += datetime.timedelta(days=(7 - d.weekday()) % 7 or 7)
iters = [{"title": f"Sprint {i+1}",
          "startDate": (d + datetime.timedelta(days=7 * i)).isoformat(),
          "duration": 7} for i in range(8)]
graphql("""mutation($p:ID!,$c:ProjectV2IterationFieldConfigurationInput){
  createProjectV2Field(input:{projectId:$p,dataType:ITERATION,name:"Sprint",iterationConfiguration:$c}){clientMutationId}}""",
        {"p": proj_id, "c": {"startDate": iters[0]["startDate"], "duration": 7, "iterations": iters}})
PYEOF

# --- 5. Det som måste göras för hand ------------------------------------------
echo "[5/5] Klart. Gör följande för hand i Projectet (kan inte göras via API):"
cat <<EOF
  1. Öppna: https://github.com/users/$OWNER/projects/$PROJ_NUM
  2. Table-vyn: lägg till fälten Parent issue, Sub-issues progress, Labels,
     Blocked by och Sprint, och gruppera/expandera efter Parent issue.
  3. Settings > Workflows: slå på "Item added to project" (Backlog),
     "Pull request merged" (Done) och "Item closed" (Done).
  4. Automation så att story och epic följer sina tasks finns inte inbyggt,
     den får hanteras för hand tills vidare (se WORKFLOW.md avsnitt 4).
  5. Committa de kopierade filerna i en egen task och PR.
EOF
