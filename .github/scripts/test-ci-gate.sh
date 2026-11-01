#!/usr/bin/env bash
# Tests ci-gate.sh with the needs context of different workflow runs.
set -Eeuo pipefail

scripts="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
log="$(mktemp)"
trap 'rm -f -- "${log}"' EXIT
tests=0
failures=0

# usage: assert <name> <condition...>
assert() {
  local name="$1"
  shift
  tests=$((tests + 1))
  if "$@"; then
    echo "ok   ${name}"
  else
    failures=$((failures + 1))
    echo "FAIL ${name}"
    [ ! -s "${log}" ] || while IFS= read -r line; do echo "    ${line}"; done <"${log}"
  fi
}

# usage: gate <needs json> ; runs ci-gate.sh with NEEDS_JSON set to the given value
gate() {
  status=0
  NEEDS_JSON="$1" bash "${scripts}/ci-gate.sh" >"${log}" 2>&1 || status=$?
}
passed() { [ "${status}" -eq 0 ]; }
failed_with() { [ "${status}" -ne 0 ] && grep -qF -- "$1" "${log}"; }

gate '{"build":{"result":"success","outputs":{}},"test":{"result":"success","outputs":{}}}'
assert "all jobs successful passes" passed

gate '{"build":{"result":"success","outputs":{}},"publish":{"result":"skipped","outputs":{}}}'
assert "skipped jobs pass" passed

gate '{"build":{"result":"success","outputs":{}},"test":{"result":"failure","outputs":{}}}'
assert "a failed job fails the gate" failed_with "test"
assert "only the failed job is reported" bash -c "! grep -qF 'build' '${log}'"

gate '{"build":{"result":"cancelled","outputs":{}}}'
assert "a cancelled job fails the gate" failed_with "build"

gate '{"setup":{"result":"failure","outputs":{}},"build":{"result":"skipped","outputs":{}}}'
assert "a failed setup job fails the gate although its dependents were skipped" failed_with "setup"

gate '{}'
assert "a run without jobs fails the gate" failed_with "no jobs"

gate 'not json'
assert "invalid input fails the gate" failed_with "NEEDS_JSON"

status=0
env -u NEEDS_JSON bash "${scripts}/ci-gate.sh" >"${log}" 2>&1 || status=$?
assert "a missing NEEDS_JSON fails the gate" failed_with "NEEDS_JSON"

echo "${tests} tests, ${failures} failures"
[ "${failures}" -eq 0 ]
