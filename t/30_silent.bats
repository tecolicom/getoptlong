#!/usr/bin/env bats

load 'test_helper'

: \${SCRIPT_UNDER_TEST:="../ex/silent.sh"}

setup() {
    chmod +x "\$SCRIPT_UNDER_TEST"
}

script=\$(basename "\$SCRIPT_UNDER_TEST")

RUN() {
    run "\$SCRIPT_UNDER_TEST" "\$@"
}

@test "\${script}: shows help with --help" {
    RUN --help
    assert_success
    assert_output --partial "repeat [ options ] command" # Main help
}

@test "\${script}: main options and subcommand detection" {
    RUN --debug 1 --message MAIN_KEY=MAIN_VAL flag --flag-opt some_arg
    assert_success
    # Check main options parsed (example, debug is a main option)
    # In silent.sh, main options are parsed first, then sub_opts from the same ARGV
    # Check for debug output from main getoptlong dump
    assert_output --partial 'debug=1'
    assert_output --partial 'message\[MAIN_KEY\]="MAIN_VAL"'
    # Check that subcommand is correctly identified and remaining args are present
    # The script itself prints "subcmd [ args ]"
    assert_output --partial "flag \[ --flag-opt some_arg \]"
}

@test "\${script}: subcommand 'flag' with mixed options" {
    RUN --debug 1 --message MAIN=YES flag --flag --another-main-opt
    assert_success
    # Main options
    assert_output --partial 'debug=1'
    assert_output --partial 'message\[MAIN\]="YES"'
    # Subcommand output (declare -p flag)
    assert_output --partial 'declare -- flag="1"'
    # Check that "another-main-opt" doesn't cause sub_opts parsing to fail and is passed as remaining arg
    assert_output --partial "flag \[ --flag --another-main-opt \]"
    # Also check that 'another-main-opt' is captured by the final echo if it's a remaining arg
    assert_output --partial "--another-main-opt"
}

@test "\${script}: subcommand 'data' with mixed options" {
    RUN --sub-data myvalue --debug 2 data --message MAIN=NO --data-val some_data_val
    assert_success
    # Main options
    assert_output --partial "Main Opts Dump:"
    assert_output --partial 'debug=2'
    assert_output --partial 'message\[MAIN\]="NO"' # This is actually a main option
    # Subcommand specific (declare -p data)
    assert_output --partial 'declare -- data="some_data_val"' # This is the subcommand option
    # Check arguments passed to subcommand processing
    # Note: --sub-data is not a main option, it will be passed to subcmd.
    # --message is a main option, it will be parsed by main parser.
    # --data-val is a sub option.
    assert_output --partial "data \[ --sub-data myvalue --message MAIN=NO --data-val some_data_val \]"
    # Check remaining args passed to the subcommand's final echo
    assert_output --partial "--sub-data myvalue" # This was not a sub_opt for 'data'
}

@test "\${script}: subcommand 'list' with mixed options" {
    RUN --main-opt-val --debug 1 list --list item1 --another-main-val --list item2 --random-other-arg
    assert_success
    assert_output --partial 'debug=1'
    assert_output --partial 'declare -a list=(\[0\]="item1" \[1\]="item2")'
    # Check arguments passed to subcommand processing
    assert_output --partial "list \[ --main-opt-val --another-main-val --list item1 --list item2 --random-other-arg \]"
    # Check remaining args. --main-opt-val, --another-main-val, --random-other-arg were not defined for 'list' sub_opts
    assert_output --partial "--main-opt-val --another-main-val --random-other-arg"
}

@test "\${script}: subcommand 'hash' with mixed options" {
    RUN --debug 0 hash --hash key1=val1 --main-message KEY=VAL --hash key2=val2 non_opt_for_hash
    assert_success
    assert_output --partial 'message\[KEY\]="VAL"' # Main option
    assert_output --partial 'declare -A hash=(\[key1\]="val1" \[key2\]="val2" )' # Subcommand option
    # Check arguments passed to subcommand processing
    assert_output --partial "hash \[ --main-message KEY=VAL --hash key1=val1 --hash key2=val2 non_opt_for_hash \]"
    # Check remaining args. --main-message and non_opt_for_hash were not sub_opts for 'hash'
    assert_output --partial "--main-message KEY=VAL non_opt_for_hash"
}

@test "\${script}: unknown subcommand" {
    RUN unknown_sub_command --some-opt
    assert_failure
    assert_output --partial "unknown_sub_command: unknown subcommand"
}

@test "\${script}: required subcommand missing" {
    RUN --debug 1
    assert_failure
    assert_output --partial "subcommand is required"
}

@test "\${script}: help for main command even with subcommand-like args" {
    RUN --help subcmd --sub-opt
    assert_success
    assert_output --partial "repeat [ options ] command" # Main help
    # Ensure "subcmd" and "--sub-opt" are treated as non-option args by main help callback if help is invoked
}
