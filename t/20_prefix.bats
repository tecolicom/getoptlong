#!/usr/bin/env bats

load 'test_helper'

# Path to the script to be tested
SCRIPT_UNDER_TEST="../../../ex/prefix.sh"

setup() {
    # Ensure the script is executable
    chmod +x "$SCRIPT_UNDER_TEST"
}

@test "prefix.sh: help option" {
    run "$SCRIPT_UNDER_TEST" --help
    assert_success
    assert_output --partial "repeat count command" # prefix.sh shares help text with repeat.sh
    assert_output --partial "-c#, --count=#"
}

@test "prefix.sh: basic repeat with prefix (check debug for var names)" {
    # Variables in prefix.sh are opt_count, opt_debug etc.
    # We check this via debug output.
    run "$SCRIPT_UNDER_TEST" --debug=2 2 echo "hello"
    assert_success
    assert_output --partial "opt_count=([0]="2")" # From declare -p opt_count
    assert_output --partial "opt_debug=([0]="2")"
    assert_output "hello
hello"
}

@test "prefix.sh: -c option for count with prefix" {
    run "$SCRIPT_UNDER_TEST" --debug=2 -c 3 echo "test"
    assert_success
    assert_output --partial "opt_count=([0]="3")"
    assert_output "test
test
test"
}

@test "prefix.sh: --count option for count with prefix" {
    run "$SCRIPT_UNDER_TEST" --debug=2 --count=1 echo "once"
    assert_success
    assert_output --partial "opt_count=([0]="1")"
    assert_output "once"
}

@test "prefix.sh: -p (paragraph) option with prefix" {
    run "$SCRIPT_UNDER_TEST" --debug=2 -c 2 -p echo "line"
    assert_success
    assert_output --partial "opt_paragraph=([0]="")" # Set to empty string
    assert_output "line

line
"
}

@test "prefix.sh: --paragraph option with custom separator with prefix" {
    run "$SCRIPT_UNDER_TEST" --debug=2 --count=2 --paragraph=--- echo "segment"
    assert_success
    assert_output --partial "opt_paragraph=([0]="---")"
    assert_output "segment---segment---"
}

@test "prefix.sh: -i (sleep) option with prefix (check debug)" {
    run "$SCRIPT_UNDER_TEST" -c 1 --debug=2 -i 0.01 echo "wait"
    assert_success
    assert_output --partial "opt_sleep=([0]="0.01")" # From declare -p opt_sleep
    assert_output --partial "# sleep 0.01"
    assert_output --partial "wait"
}

@test "prefix.sh: multiple -i (sleep) options with prefix" {
    run "$SCRIPT_UNDER_TEST" -c 3 --debug=2 -i 0.01 -i 0.02 echo "step"
    assert_success
    assert_output --partial "opt_sleep=([0]="0.01" [1]="0.02")"
    # Check that the script output indicates it's using the sequence of sleep times
    # Output will be: step, sleep 0.01, step, sleep 0.02, step, sleep 0.01 (wraps around)
    # The debug output for sleep is inside the loop, check main output for sequence.
    local expected_output="step
step
step" # Command output
    local d_line_1="# sleep 0.01"      # Debug for sleep
    local d_line_2="# sleep 0.02"      # Debug for sleep

    # Check command output
    run echo "${output}" | grep -v "^#" | grep -v "declare -p" | grep -v "OPTS\["
    assert_output "$expected_output"

    # Check debug sleep sequence
    run echo "${output}" | grep "# sleep"
    assert_success
    [[ "${lines[0]}" == *"$d_line_1"* ]]
    [[ "${lines[1]}" == *"$d_line_2"* ]]
    [[ "${lines[2]}" == *"$d_line_1"* ]] # Wraps around
}

@test "prefix.sh: -m (message) BEGIN with prefix" {
    run "$SCRIPT_UNDER_TEST" --debug=2 -c 1 -m BEGIN="Start" echo "action"
    assert_success
    assert_output --partial "opt_message=(["BEGIN"]="Start")"
    assert_output --partial "Start
action"
}

@test "prefix.sh: -m (message) END with prefix" {
    run "$SCRIPT_UNDER_TEST" --debug=2 --count=1 --message=END="Finish" echo "work"
    assert_success
    assert_output --partial "opt_message=(["END"]="Finish")"
    assert_output --partial "work
Finish"
}

@test "prefix.sh: -m (message) EACH with prefix" {
    run "$SCRIPT_UNDER_TEST" --debug=2 -c 2 -m EACH="Cycle" echo "ping"
    assert_success
    assert_output --partial "opt_message=(["EACH"]="Cycle")"
    assert_output "Cycle
ping
Cycle
ping"
}

@test "prefix.sh: -x (trace) option with prefix" {
    run "$SCRIPT_UNDER_TEST" -x -c 1 echo "trace me prefix"
    assert_success
    assert_output --partial "+ echo trace me prefix"
    assert_output --partial "opt_trace=([0]="1")" # Check debug output for var
}

@test "prefix.sh: -d (debug) option level 1 with prefix" {
    # prefix.sh script itself uses opt_debug >= 1 and opt_debug >=2
    # So setting --debug=1 (which means opt_debug=1)
    run "$SCRIPT_UNDER_TEST" -d 1 -c 1 echo "debug test prefix"
    assert_success
    assert_output --partial "[ echo debug test prefix ]" # Debug output format from prefix.sh script
    assert_output --partial "debug test prefix"
    # Check that dump is NOT present
    run echo "${output}" | grep "OPTS\["
    assert_failure # Should not find OPTS dump for debug=1
}

@test "prefix.sh: -d (debug) option level 2 (shows dump) with prefix" {
    run "$SCRIPT_UNDER_TEST" --debug=2 -c 1 echo "dump test prefix"
    assert_success
    assert_output --partial "opt_debug=([0]="2")" # From declare -p
    assert_output --partial "OPTS[" # Part of getoptlong dump
    assert_output --partial "dump test prefix"
}

@test "prefix.sh: count as positional argument with prefix" {
    run "$SCRIPT_UNDER_TEST" --debug=2 2 echo "pos_count_pref"
    assert_success
    assert_output --partial "opt_count=([0]="2")"
    assert_output "pos_count_pref
pos_count_pref"
}
