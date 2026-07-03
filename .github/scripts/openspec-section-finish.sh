#!/usr/bin/env bash
# Push branch and open PR with Closes #N for all section issues.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  echo "Usage: $0 <section-number> \"PR title\""
  echo "Example: $0 7 \"feat(sec-7): group match reconciliation\""
  exit 1
}

[[ $# -ge 2 ]] || usage
SECTION="$1"
shift
PR_TITLE="$*"

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI is required." >&2
  exit 1
fi

cd "${REPO_ROOT}"

META="$(python3 "${SCRIPT_DIR}/github_delivery.py" json "${SECTION}")"
BRANCH="$(echo "${META}" | python3 -c "import json,sys; print(json.load(sys.stdin)['branch'])")"
REPO="$(echo "${META}" | python3 -c "import json,sys; print(json.load(sys.stdin)['repo'])")"
TITLE="$(echo "${META}" | python3 -c "import json,sys; print(json.load(sys.stdin)['title'])")"
ISSUES_JSON="$(echo "${META}" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['issues']))")"

CURRENT="$(git branch --show-current)"
if [[ "${CURRENT}" != "${BRANCH}" ]]; then
  echo "Error: expected branch ${BRANCH}, currently on ${CURRENT}." >&2
  exit 1
fi

git push -u origin HEAD

CLOSES="$(python3 - <<PY
import json
issues = json.loads('${ISSUES_JSON}')
print('\n'.join(f'Closes #{i}' for i in issues))
PY
)"

PR_BODY="$(cat <<EOF
## Summary
OpenSpec section **${SECTION}** — ${TITLE}

## Test plan
- [ ] Subtasks in \`openspec/changes/worldcup-bet-tracker-spec/tasks.md\` marked complete
- [ ] Manual / automated verification as listed in linked issues

${CLOSES}
EOF
)"

gh pr create --repo "${REPO}" --title "${PR_TITLE}" --body "${PR_BODY}"

echo ""
echo "PR created. After merge, run:"
echo "  .github/scripts/openspec-section-done.sh ${SECTION}"
