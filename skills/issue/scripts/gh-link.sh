#!/usr/bin/env bash
# Helpers for /issue: things the gh CLI has no direct command for.
# Usage (run from the project folder):
#   gh-link.sh setup                  create missing labels and board
#   gh-link.sh sub <parent> <child>   add <child> as sub-issue of <parent>
#   gh-link.sh block <issue> <by>     mark <issue> as blocked by <by> (+ status:blocked)
#   gh-link.sh board <issue>          add <issue> to the board with Status = Backlog
#   gh-link.sh milestone <title>      create milestone if missing
#   gh-link.sh in-progress            list issue numbers with Status = In progress
set -euo pipefail

TEMPLATE="${WORKFLOW_TEMPLATE:-$HOME/.claude/workflow-template}"
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
OWNER=${REPO%%/*}
NAME=${REPO##*/}

issue_id() { gh api "repos/$REPO/issues/$1" --jq .id; }

# Number of the first project linked to this repo, empty if none.
project_number() {
  gh api graphql -f query='query($o:String!,$n:String!){repository(owner:$o,name:$n){projectsV2(first:1){nodes{number}}}}' \
    -f o="$OWNER" -f n="$NAME" --jq '.data.repository.projectsV2.nodes[0].number // empty'
}

ensure_labels() {
  local existing created=""
  existing=$(gh label list -R "$REPO" --limit 200 --json name -q '.[].name')
  while IFS=$'\t' read -r name color desc; do
    if ! grep -qxF "$name" <<<"$existing"; then
      gh label create "$name" -R "$REPO" --color "$color" --description "$desc" >/dev/null
      created+="$name "
    fi
  done < <(python -c "import json,sys
for l in json.load(open(sys.argv[1],encoding='utf-8')): print(l['name'],l['color'],l['description'],sep='\t')" "$TEMPLATE/labels.json")
  [ -n "$created" ] && echo "Created labels: $created"
  return 0
}

ensure_board() {
  [ -n "$(project_number)" ] && return 0
  local num pid fid
  num=$(gh project create --owner "$OWNER" --title "$NAME" --format json -q .number)
  gh project link "$num" --owner "$OWNER" --repo "$REPO" >/dev/null
  fid=$(gh project field-list "$num" --owner "$OWNER" --format json -q '.fields[]|select(.name=="Status")|.id')
  gh api graphql -f f="$fid" -f query='mutation($f:ID!){updateProjectV2Field(input:{fieldId:$f,singleSelectOptions:[
    {name:"Backlog",color:GRAY,description:""},{name:"Ready",color:BLUE,description:""},
    {name:"In progress",color:YELLOW,description:""},{name:"In review",color:PURPLE,description:""},
    {name:"Done",color:GREEN,description:""}]}){projectV2Field{... on ProjectV2SingleSelectField{id}}}}' >/dev/null
  echo "Created board \"$NAME\" (project #$num). Turn on 'Show hierarchy' in its view menu to see the tree."
}

set_status() { # <issue> <status name>
  local num pid fid opt item
  num=$(project_number)
  [ -z "$num" ] && { echo "No board linked to $REPO" >&2; exit 1; }
  pid=$(gh project view "$num" --owner "$OWNER" --format json -q .id)
  fid=$(gh project field-list "$num" --owner "$OWNER" --format json -q '.fields[]|select(.name=="Status")|.id')
  opt=$(gh project field-list "$num" --owner "$OWNER" --format json -q ".fields[]|select(.name==\"Status\")|.options[]|select(.name==\"$2\")|.id")
  [ -z "$opt" ] && { echo "Board has no Status option \"$2\"" >&2; exit 1; }
  item=$(gh project item-add "$num" --owner "$OWNER" --url "https://github.com/$REPO/issues/$1" --format json -q .id)
  gh project item-edit --id "$item" --project-id "$pid" --field-id "$fid" --single-select-option-id "$opt" >/dev/null
  echo "#$1 → $2"
}

case "${1:-}" in
  setup)      ensure_labels; ensure_board ;;
  sub)        gh api -X POST "repos/$REPO/issues/$2/sub_issues" -F sub_issue_id="$(issue_id "$3")" >/dev/null && echo "#$3 under #$2" ;;
  block)      gh api -X POST "repos/$REPO/issues/$2/dependencies/blocked_by" -F issue_id="$(issue_id "$3")" >/dev/null
              gh issue edit "$2" -R "$REPO" --add-label status:blocked >/dev/null && echo "#$2 blocked by #$3" ;;
  board)      set_status "$2" Backlog ;;
  milestone)  gh api "repos/$REPO/milestones" --jq '.[].title' | grep -qxF "$2" \
                || { gh api -X POST "repos/$REPO/milestones" -f title="$2" >/dev/null && echo "Created milestone $2"; } ;;
  in-progress)
              num=$(project_number); [ -z "$num" ] && exit 0
              gh project item-list "$num" --owner "$OWNER" --format json --limit 500 \
                -q '.items[]|select(.status=="In progress")|"#\(.content.number) \(.content.title)"' ;;
  *)          sed -n '2,9p' "$0"; exit 1 ;;
esac
