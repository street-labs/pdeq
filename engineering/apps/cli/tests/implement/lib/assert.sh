#!/usr/bin/env bash
# Assertion helpers for implement-context.sh tests.

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-}"
  if [ "$expected" = "$actual" ]; then return 0; fi
  echo "  FAIL: assert_eq ${msg:+($msg) }expected=<$expected> actual=<$actual>" >&2
  return 1
}

assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-}"
  if [[ "$haystack" == *"$needle"* ]]; then return 0; fi
  echo "  FAIL: assert_contains ${msg:+($msg) }needle=<$needle> not found" >&2
  echo "$haystack" | head -20 | sed 's/^/    /' >&2
  return 1
}

assert_not_contains() {
  local haystack="$1" needle="$2" msg="${3:-}"
  if [[ "$haystack" != *"$needle"* ]]; then return 0; fi
  echo "  FAIL: assert_not_contains ${msg:+($msg) }needle=<$needle> unexpectedly found" >&2
  return 1
}

assert_exit() {
  local expected="$1" msg="${2:-}"
  shift 2
  set +e
  "$@" >/dev/null 2>&1
  local actual=$?
  set -e
  if [ "$expected" = "$actual" ]; then return 0; fi
  echo "  FAIL: assert_exit ${msg:+($msg) }expected=$expected actual=$actual" >&2
  return 1
}
