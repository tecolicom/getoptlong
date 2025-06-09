#!/usr/bin/env bats

load 'test_helper'

setup() {
    chmod +x "/app/ex/subcmd.sh" # Use absolute path if relative caused issues
}

RUN() {
    # run "/app/ex/subcmd.sh" "\$@" # Use absolute path
}

@test "subcmd.sh: help" {
    run /app/ex/subcmd.sh --help # Direct run
    assert_success
    assert_output --partial "repeat [ options ] command"
}

@test "subcmd.sh: main option parsing (debug and message)" {
    RUN --debug --message key=val subcmd_test --sub-opt
    assert_success
    # Check the explicit echo for debug value
    assert_output --partial "Debug var after main parse: [1]" # Expect 1 for --debug
    assert_output --partial "Message var after main parse: [key=val]" # Expect key=val for --message
    assert_output --partial "Remaining args after main parse: [subcmd_test --sub-opt]"
    assert_output --partial "Subcommand identified: [subcmd_test]"
    assert_output --partial "Args for sub-parser: [--sub-opt]"
}

@test "subcmd.sh: PERMUTE= behavior (main options stop at first non-option)" {
    RUN --debug main_non_opt --message key=val subcmd_test --sub-opt
    assert_success
    # --debug is parsed, main_non_opt is first positional.
    # --message should NOT be parsed as a main option.
    assert_output --partial "Debug var after main parse: [1]"
    assert_output --partial "Message var after main parse: []" # Empty, as it was after non_opt
    assert_output --partial "Remaining args after main parse: [main_non_opt --message key=val subcmd_test --sub-opt]"
    assert_output --partial "Subcommand identified: [main_non_opt]"
    assert_output --partial "Args for sub-parser: [--message key=val subcmd_test --sub-opt]"
}

@test "subcmd.sh: subcommand 'flag'" {
    RUN --debug flag --flag # Here, 'flag' is the $subcmd_val, --flag is for sub-parser
    assert_success
    assert_output --partial "Debug var after main parse: [1]" # Main option
    assert_output --partial "Subcommand identified: [flag]"
    assert_output --partial "Args for sub-parser: [--flag]"
    assert_output --partial 'declare -- flag="1"' # Output from subcommand 'flag' block
}

@test "subcmd.sh: subcommand 'data'" {
    RUN --message main=foo data --data sub_value remaining
    assert_success
    assert_output --partial "Message var after main parse: [main=foo]"
    assert_output --partial "Subcommand identified: [data]"
    assert_output --partial "Args for sub-parser: [--data sub_value remaining]"
    assert_output --partial 'declare -- data="sub_value"'
    assert_output --partial "Remaining args after sub-parser: [remaining]" # Adjusted to check new echo
}

@test "subcmd.sh: unknown subcommand" {
    run "/app/ex/subcmd.sh" "unknown" # Direct run for failure check
    assert_failure # Expect exit code 1
    assert_output --partial "Subcommand identified: [unknown]" # Will be printed before error
    assert_output --partial "unknown: unknown subcommand"
}
