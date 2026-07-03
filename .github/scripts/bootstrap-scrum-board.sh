#!/usr/bin/env bash
# Bootstrap GitHub Project + issues for World Cup Bet Tracker.
# Issue content lives in update-issue-content.py (self-contained, no openspec refs).
# Requires: gh CLI, repo scope (issues), project scope (project create/item-add).
# Run: gh auth refresh -s project -h github.com   (if project commands fail)
set -euo pipefail

REPO="DaltonDjoesman/worldcup-pool-tracker-app"
ASSIGNEE="DaltonDjoesman"
PROJECT_TITLE="World Cup Bet Tracker"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

create_labels() {
  local labels=(
    "P0:d73a4a:Critical path — foundation"
    "P1:fbca04:Core product features"
    "P2:0e8a16:Polish, stats, release"
    "frontend:1d76db:Flutter UI"
    "backend:5319e7:Cloud Functions / server logic"
    "firebase:ff6b35:Firebase services"
    "security:b60205:Firestore rules & auth gates"
    "devops:006b75:CI/CD, ingestion jobs"
  )
  for entry in "${labels[@]}"; do
    IFS=':' read -r name color desc <<< "$entry"
    gh api --method POST "repos/${REPO}/labels" \
      -f name="$name" -f color="$color" -f description="$desc" 2>/dev/null \
      || gh api --method PATCH "repos/${REPO}/labels/$(printf '%s' "$name" | jq -sRr @uri)" \
        -f color="$color" -f description="$desc" 2>/dev/null || true
  done
}

create_all_issues() {
  python3 "${SCRIPT_DIR}/update-issue-content.py" --create
}

update_all_issues() {
  python3 "${SCRIPT_DIR}/update-issue-content.py"
}

setup_project() {
  echo "Creating GitHub Project..."
  local project_json
  project_json=$(gh projects create --user '@me' --title "$PROJECT_TITLE" --format json)
  local project_number
  project_number=$(echo "$project_json" | jq -r '.number')
  echo "Project #$project_number created."

  echo "Linking project to repository..."
  local repo_id project_id
  repo_id=$(gh api graphql -f query='query { repository(owner:"DaltonDjoesman", name:"worldcup-pool-tracker-app") { id } }' --jq '.data.repository.id')
  project_id=$(gh api graphql -f query="query { user(login:\"$ASSIGNEE\") { projectV2(number:$project_number) { id } } }" --jq '.data.user.projectV2.id')

  gh api graphql -f query="
    mutation {
      linkProjectV2ToRepository(input: { projectId: \"$project_id\", repositoryId: \"$repo_id\" }) {
        repository { nameWithOwner }
      }
    }"

  echo "Adding open issues to project (Status: Todo)..."
  gh issue list --repo "$REPO" --state open --limit 200 --json url --jq '.[].url' | while read -r url; do
    gh projects item-add "$project_number" --user '@me' --url "$url" >/dev/null
    echo "  Added $url"
  done

  echo ""
  echo "Done! Project: https://github.com/users/$ASSIGNEE/projects/$project_number"
}

main() {
  case "${1:-}" in
    --project-only)
      setup_project
      ;;
    --issues-only)
      create_labels
      create_all_issues
      ;;
    --update-issues)
      update_all_issues
      ;;
    *)
      create_labels
      create_all_issues
      setup_project
      ;;
  esac
}

main "$@"
