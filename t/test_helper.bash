#!/usr/bin/env bats

# Source getoptlong.sh for use in tests
load '../getoptlong.sh'

# --- Basic Assertion Helpers ---

# Asserts that the last 'run' command completed successfully (status 0)
assert_success() {
  if [ "$status" -ne 0 ]; then
    echo "Error: Command failed with status $status" >&2
    echo "Output:" >&2
    echo "$output" >&2
    return 1 # Indicate assertion failure
  fi
  return 0 # Indicate assertion success
}

# Asserts that the last 'run' command failed (status non-zero)
assert_failure() {
  if [ "$status" -eq 0 ]; then
    echo "Error: Command succeeded unexpectedly (status 0)" >&2
    echo "Output:" >&2
    echo "$output" >&2
    return 1 # Indicate assertion failure
  fi
  return 0 # Indicate assertion success
}
