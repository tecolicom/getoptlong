#!/usr/bin/env bats

load 'test_helper'

# Path to the script to be tested, relative to the .bats file
SCRIPT_UNDER_TEST="../../../ex/repeat.sh"

setup() {
    # Ensure the script is executable
    chmod +x "$SCRIPT_UNDER_TEST"
}

@test "repeat.sh: help option" {
    run "$SCRIPT_UNDER_TEST" --help
    assert_success
    assert_output --partial "repeat count command"
    assert_output --partial "-c#, --count=#"
}

@test "repeat.sh: basic repeat" {
    run "$SCRIPT_UNDER_TEST" 2 echo "hello"
    assert_success
    assert_output "hello
hello"
}

@test "repeat.sh: -c option for count" {
    run "$SCRIPT_UNDER_TEST" -c 3 echo "test"
    assert_success
    assert_output "test
test
test"
}

@test "repeat.sh: --count option for count" {
    run "$SCRIPT_UNDER_TEST" --count 1 echo "once"
    assert_success
    assert_output "once"
}

@test "repeat.sh: -p (paragraph) option, default newline" {
    run "$SCRIPT_UNDER_TEST" -c 2 -p echo "line"
    assert_success
    assert_output "line

line
" # Command output, then paragraph sep, then command, then paragraph sep
}

@test "repeat.sh: --paragraph option with custom separator" {
    run "$SCRIPT_UNDER_TEST" --count=2 --paragraph=--- echo "segment"
    assert_success
    assert_output "segment---segment---"
}

@test "repeat.sh: -i (sleep) option (actual sleep is hard to test, check debug)" {
    # We can't easily test the sleep duration itself in a short unit test.
    # We'll use debug output to infer it was acknowledged.
    # A real test for sleep might involve timing, which is flaky.
    run "$SCRIPT_UNDER_TEST" -c 1 --debug=1 -i 0.01 echo "wait"
    assert_success
    assert_output --partial "# sleep 0.01"
    assert_output --partial "wait"
}

@test "repeat.sh: multiple -i (sleep) options for sequence" {
    run "$SCRIPT_UNDER_TEST" -c 3 --debug=1 -i 0.01 -i 0.02 echo "step"
    assert_success
    # Check that the script output indicates it's using the sequence of sleep times
    # Output will be: step, sleep 0.01, step, sleep 0.02, step, sleep 0.01 (wraps around)
    assert_output --partial "step"
    [[ "${lines[1]}" == *"# sleep 0.01"* ]] # After first echo
    [[ "${lines[3]}" == *"# sleep 0.02"* ]] # After second echo
}

@test "repeat.sh: -m (message) BEGIN" {
    run "$SCRIPT_UNDER_TEST" -c 1 -m BEGIN="Start" echo "action"
    assert_success
    assert_output --partial "Start
action" # Message first, then action
}

@test "repeat.sh: -m (message) END" {
    run "$SCRIPT_UNDER_TEST" --count=1 --message=END="Finish" echo "work"
    assert_success
    assert_output --partial "work
Finish" # Work first, then message
}

@test "repeat.sh: -m (message) EACH" {
    run "$SCRIPT_UNDER_TEST" -c 2 -m EACH="Cycle" echo "ping"
    assert_success
    assert_output "Cycle
ping
Cycle
ping"
}

@test "repeat.sh: -m (message) multiple messages" {
    run "$SCRIPT_UNDER_TEST" -c 1 -m BEGIN="B" -m EACH="E" -m END="X" echo "task"
    assert_success
    assert_output "B
E
task
X"
}

@test "repeat.sh: -x (trace) option" {
    # Checking for 'set -x' output is tricky as it's verbose and context-dependent.
    # We'll check if a known command within the trace output appears.
    run "$SCRIPT_UNDER_TEST" -x -c 1 echo "trace me"
    assert_success
    assert_output --partial "+ echo trace me" # A typical line from `set -x`
}

@test "repeat.sh: -d (debug) option level 1" {
    run "$SCRIPT_UNDER_TEST" -d 1 -c 1 echo "debug test"
    assert_success
    assert_output --partial "# [ echo debug test ]" # Debug output format from script
    assert_output --partial "debug test"
}

@test "repeat.sh: -d (debug) option level 2 (shows dump)" {
    run "$SCRIPT_UNDER_TEST" --debug=2 -c 1 echo "dump test"
    assert_success
    assert_output --partial "OPTS[" # Part of getoptlong dump
    assert_output --partial "count=([0]="1")" # Example from declare -p output
    assert_output --partial "dump test"
}

@test "repeat.sh: command with spaces" {
    run "$SCRIPT_UNDER_TEST" -c 1 echo "hello world"
    assert_success
    assert_output "hello world"
}

@test "repeat.sh: command with its own options" {
    run "$SCRIPT_UNDER_TEST" -c 1 ls -a /dev/null # Using a known command
    assert_success
    assert_output --partial "null" # ls -a /dev/null should output /dev/null (or ./null depending on ls)
}

@test "repeat.sh: no arguments (should show help or error)" {
    run "$SCRIPT_UNDER_TEST"
    assert_failure # Expecting failure as command is missing
    # The script has `set -eu`, so it might exit due to unbound variable if no args
    # or it might show help. Let's check for help-like output.
    assert_output --partial "repeat count command"
}

@test "repeat.sh: count as positional argument" {
    run "$SCRIPT_UNDER_TEST" 2 echo "pos_count"
    assert_success
    assert_output "pos_count
pos_count"
}

@test "repeat.sh: count as positional and -c (positional should win if first)" {
    # According to the script: [[ ${1:-} =~ ^[0-9]+$ ]] && { count=$1 ; shift ; }
    # This means if the first arg is a number, it's taken as count.
    run "$SCRIPT_UNDER_TEST" 3 -c 1 echo "mixed_count"
    assert_success
    assert_output "mixed_count
mixed_count
mixed_count" # Expect 3 times
}

@test "repeat.sh: -c and then positional (positional becomes part of command)" {
    run "$SCRIPT_UNDER_TEST" -c 1 2 echo "cmd_starts_with_num"
    # Here, '2' is not the count, 'echo' is the command, '2' and 'cmd_starts_with_num' are its args.
    assert_success
    assert_output "2 cmd_starts_with_num"
}

@test "repeat.sh: complex message with spaces and equals" {
    run "$SCRIPT_UNDER_TEST" -c 1 -m EACH="An=Each Cycle" echo "Test"
    assert_success
    assert_output "An=Each Cycle
Test"
}

@test "repeat.sh: paragraph with empty string (removes default newline)" {
    run "$SCRIPT_UNDER_TEST" -c 2 --paragraph="" echo "tight"
    assert_success
    assert_output "tighttight" # No newlines or separators from --paragraph
}
