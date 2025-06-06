#!/usr/bin/env bash

# run_tests.sh
# Simple test runner using prove for .bats files in the t/ directory

# Ensure prove is available
if ! command -v prove &> /dev/null
then
    echo "Error: 'prove' command not found." >&2
    echo "Please install 'prove' (usually part of Perl core or App::Prove module)." >&2
    exit 1
fi

# Ensure bats is available (basic check, assumes it's in PATH)
# The individual .bats files also call `load 'test_helper'` which might implicitly
# depend on a bats installation or a local bats in t/bats/.
# Given the previous issues, we are assuming bats is globally available.
if ! command -v bats &> /dev/null
then
    echo "Warning: 'bats' command not found. Tests might fail if not installed globally or configured via test_helper." >&2
    # Depending on how test_helper.bash and bats files are set up,
    # this might not be a fatal error if bats is loaded locally by the tests.
fi

# Directory containing the test files
TEST_DIR="t"

if [ ! -d "$TEST_DIR" ]; then
    echo "Error: Test directory '$TEST_DIR' not found." >&2
    exit 1
fi

# Find all .bats files in the test directory
TEST_FILES=$(find "$TEST_DIR" -maxdepth 1 -name '*.bats' 2>/dev/null)

if [ -z "$TEST_FILES" ]; then
    echo "No .bats files found in '$TEST_DIR'."
    exit 0
fi

echo "Running tests using prove..."
# -l : Add lib directory to Perl's @INC path (may not be strictly needed for bats but common for prove)
# -v : Verbose output
# We are passing the .bats files directly to prove.
# prove can execute scripts that are executable and have a shebang.
prove -lv $TEST_FILES

exit $?
