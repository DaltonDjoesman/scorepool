#!/usr/bin/env bash
# Close a single issue and move it to Done on GitHub Project #3.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/openspec-delivery-lib.sh"

[[ $# -eq 1 ]] || { echo "Usage: $0 <issue-number>"; exit 1; }

load_delivery_config
move_issue_to_done "$1"
