#!/usr/bin/env bash
# Shared helpers for OpenSpec GitHub delivery scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

load_delivery_config() {
  if [[ -n "${DELIVERY_CONFIG_LOADED:-}" ]]; then
    return 0
  fi
  DELIVERY_JSON="$(python3 "${SCRIPT_DIR}/github_delivery.py" json)"
  REPO="$(json_field repo)"
  PROJECT_OWNER="$(json_field project_owner)"
  PROJECT_NUMBER="$(json_field project_number)"
  STATUS_FIELD="$(json_field status_field)"
  STATUS_DONE="$(json_field status_done)"
  DELIVERY_CONFIG_LOADED=1
  export REPO PROJECT_OWNER PROJECT_NUMBER STATUS_FIELD STATUS_DONE DELIVERY_JSON
}

json_field() {
  python3 -c "import json,sys; print(json.load(sys.stdin)['$1'])" <<< "${DELIVERY_JSON}"
}

section_json() {
  python3 "${SCRIPT_DIR}/github_delivery.py" json "$1"
}

move_issue_to_done() {
  local issue="$1"
  local repo_name="${2:-${REPO}}"
  local owner="${3:-${PROJECT_OWNER}}"
  local project_number="${4:-${PROJECT_NUMBER}}"
  local status_field="${5:-${STATUS_FIELD}}"
  local status_done="${6:-${STATUS_DONE}}"

  echo "Processing issue #${issue}..."

  local state
  state="$(gh issue view "${issue}" --repo "${repo_name}" --json state --jq '.state')"
  if [[ "${state}" == "OPEN" ]]; then
    gh issue close "${issue}" --repo "${repo_name}" \
      --comment "Completed via OpenSpec delivery workflow." \
      || echo "Warning: could not close issue #${issue}"
  fi

  local project_id field_id done_option_id
  project_id="$(gh api graphql -f query="
    query(\$owner: String!, \$number: Int!) {
      user(login: \$owner) {
        projectV2(number: \$number) { id }
      }
    }" -f owner="${owner}" -F number="${project_number}" --jq '.data.user.projectV2.id')"

  field_id="$(gh api graphql -f query="
    query(\$owner: String!, \$number: Int!) {
      user(login: \$owner) {
        projectV2(number: \$number) {
          fields(first: 50) {
            nodes {
              ... on ProjectV2SingleSelectField {
                id
                name
                options { id name }
              }
            }
          }
        }
      }
    }" -f owner="${owner}" -F number="${project_number}" --jq "
      .data.user.projectV2.fields.nodes[]
      | select(.name==\"${status_field}\")
      | .id
    " | head -1)"

  done_option_id="$(gh api graphql -f query="
    query(\$owner: String!, \$number: Int!) {
      user(login: \$owner) {
        projectV2(number: \$number) {
          fields(first: 50) {
            nodes {
              ... on ProjectV2SingleSelectField {
                name
                options { id name }
              }
            }
          }
        }
      }
    }" -f owner="${owner}" -F number="${project_number}" --jq "
      .data.user.projectV2.fields.nodes[]
      | select(.name==\"${status_field}\")
      | .options[]
      | select(.name==\"${status_done}\")
      | .id
    " | head -1)"

  if [[ -z "${field_id}" || -z "${done_option_id}" ]]; then
    echo "Warning: Status field '${status_field}' / '${status_done}' not found on project #${project_number}." >&2
    echo "Issue #${issue} is closed; move the card to Done manually if needed." >&2
    return 0
  fi

  local item_id issue_url
  issue_url="$(gh issue view "${issue}" --repo "${repo_name}" --json url --jq '.url')"

  item_id="$(gh api graphql -f query="
    query(\$url: URI!) {
      resource(url: \$url) {
        ... on Issue {
          projectItems(first: 20) {
            nodes {
              id
              project { number }
            }
          }
        }
      }
    }" -f url="${issue_url}" --jq "
      [.data.resource.projectItems.nodes[] | select(.project.number==${project_number}) | .id][0]
    ")"

  if [[ -z "${item_id}" || "${item_id}" == "null" ]]; then
    echo "Adding issue to project #${project_number}..."
    if gh project item-add "${project_number}" --owner "@me" --url "${issue_url}" >/dev/null 2>&1; then
      :
    elif gh api graphql -f query="
      mutation(\$projectId: ID!, \$contentId: ID!) {
        addProjectV2ItemById(input: { projectId: \$projectId, contentId: \$contentId }) {
          item { id }
        }
      }" -f projectId="${project_id}" -f contentId="$(gh issue view "${issue}" --repo "${repo_name}" --json id --jq '.id')" --jq '.data.addProjectV2ItemById.item.id' >/tmp/item_id.txt 2>/dev/null; then
      item_id="$(cat /tmp/item_id.txt)"
    else
      echo "Warning: could not add issue #${issue} to project." >&2
      return 0
    fi

    item_id="$(gh api graphql -f query="
      query(\$url: URI!) {
        resource(url: \$url) {
          ... on Issue {
            projectItems(first: 20) {
              nodes { id project { number } }
            }
          }
        }
      }" -f url="${issue_url}" --jq "
        [.data.resource.projectItems.nodes[] | select(.project.number==${project_number}) | .id][0]
      ")"
  fi

  if [[ -z "${item_id}" || "${item_id}" == "null" ]]; then
    echo "Warning: could not resolve project item for issue #${issue}." >&2
    return 0
  fi

  gh api graphql -f query="
    mutation(\$projectId: ID!, \$itemId: ID!, \$fieldId: ID!, \$optionId: String!) {
      updateProjectV2ItemFieldValue(
        input: {
          projectId: \$projectId
          itemId: \$itemId
          fieldId: \$fieldId
          value: { singleSelectOptionId: \$optionId }
        }
      ) { projectV2Item { id } }
    }" -f projectId="${project_id}" -f itemId="${item_id}" -f fieldId="${field_id}" -f optionId="${done_option_id}" >/dev/null

  echo "Issue #${issue} → ${status_done} on project #${project_number}"
}
