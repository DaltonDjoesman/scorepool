#!/usr/bin/env bash
# Start OpenSpec section work: update main, create feature branch, comment issues.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
  echo "Usage: $0 <section-number>"
  echo "Example: $0 7"
  exit 1
}

[[ $# -eq 1 ]] || usage
SECTION="$1"

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI is required." >&2
  exit 1
fi

cd "${REPO_ROOT}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is not clean. Commit, stash, or discard changes first." >&2
  git status --short
  exit 1
fi

META="$(python3 "${SCRIPT_DIR}/github_delivery.py" json "${SECTION}")"
BRANCH="$(echo "${META}" | python3 -c "import json,sys; print(json.load(sys.stdin)['branch'])")"
REPO="$(echo "${META}" | python3 -c "import json,sys; print(json.load(sys.stdin)['repo'])")"
ISSUES="$(echo "${META}" | python3 -c "import json,sys; print(' '.join(map(str,json.load(sys.stdin)['issues'])))")"
TITLE="$(echo "${META}" | python3 -c "import json,sys; print(json.load(sys.stdin)['title'])")"

echo "Section ${SECTION}: ${TITLE}"
echo "Branch: ${BRANCH}"
echo "Issues: ${ISSUES}"

git checkout main
git pull --ff-only origin main

if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "Branch ${BRANCH} already exists locally; checking out."
  git checkout "${BRANCH}"
else
  git checkout -b "${BRANCH}"
fi

for issue in ${ISSUES}; do
  gh issue comment "${issue}" --repo "${REPO}" \
    --body "In progress via branch \`${BRANCH}\` (OpenSpec section ${SECTION})." \
    || echo "Warning: could not comment on issue #${issue}"
done

echo ""
echo "Ready on branch ${BRANCH}. Implement tasks, then run:"
echo "  .github/scripts/openspec-section-finish.sh ${SECTION} \"feat(sec-${SECTION}): ${TITLE}\""
