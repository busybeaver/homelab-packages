#!/usr/bin/env bash
# Fails unless every job in NEEDS_JSON (the workflow's `toJSON(needs)`) succeeded or was skipped. A skipped job counts
# as passed, so the job that runs this script must use `if: always()` and also need the jobs that others depend on.
set -Eeuo pipefail

if ! results="$(jq -er 'to_entries | map("\(.key)=\(.value.result)") | .[]' <<<"${NEEDS_JSON:-}" 2>/dev/null)"; then
  echo "::error::NEEDS_JSON is missing or not the JSON of the needs context, or the gate needs no jobs"
  exit 1
fi

failed=()
while IFS='=' read -r job result; do
  case "${result}" in
  success | skipped) ;;
  *) failed+=("${job} (${result})") ;;
  esac
done <<<"${results}"

if [ "${#failed[@]}" -gt 0 ]; then
  echo "::error::Jobs not successful: ${failed[*]}"
  exit 1
fi
echo "All $(wc -l <<<"${results}" | tr -d ' ') jobs succeeded or were skipped"
