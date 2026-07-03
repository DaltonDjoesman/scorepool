#!/usr/bin/env bash
# Move all section issues to Done on GitHub Project.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/openspec-delivery-lib.sh"

usage() {
  echo "Usage: $0 <section-number>"
  exit 1
}

[[ $# -eq 1 ]] || usage
SECTION="$1"

load_delivery_config
META="$(section_json "${SECTION}")"
ISSUES="$(echo "${META}" | python3 -c "import json,sys; print(' '.join(map(str,json.load(sys.stdin)['issues'])))")"

for issue in ${ISSUES}; do
  move_issue_to_done "${issue}"
done

echo "Section ${SECTION} issues processed."
