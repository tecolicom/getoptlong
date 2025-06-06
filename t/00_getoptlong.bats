#!/usr/bin/env bats

load 'test_helper'

# Setup common for all tests in this file
setup() {
    # Make getoptlong.sh available; Bats runs tests in the directory of the .bats file.
    # Adjust path if your t/test_helper.bash loads it differently or if getoptlong.sh is elsewhere.
    # The test_helper.bash provided earlier uses `load '../../../getoptlong.sh'`
    # which assumes getoptlong.sh is three levels up from the .bats file.
    # If getoptlong.sh is in the root, and test_helper.bash is in t/, this should be fine.
    : # No specific setup needed here if test_helper.bash handles loading getoptlong.sh
}

@test "getoptlong: init - basic initialization" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A MY_OPTS=([verbose|v]=)
        getoptlong init MY_OPTS
        [[ "$(type -t GOL_OPTHASH)" == "variable" ]] && [[ "$GOL_OPTHASH" == "MY_OPTS" ]]
    '
    assert_success
}

@test "getoptlong: init - with PREFIX" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([long|l]=)
        getoptlong init OPTS PREFIX=test_
        getoptlong parse --long
        eval "$(getoptlong set)"
        assert_var_eq "test_long" "1"
    '
    assert_success
}

@test "getoptlong: version" {
    run bash -c '
        source ../../../getoptlong.sh
        getoptlong version
    '
    assert_success
    assert_output --partial "0.01" # Assuming version is 0.01 as per the script
}

@test "getoptlong: dump - shows option state" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([foo|f]=bar [baz%]=)
        getoptlong init OPTS
        getoptlong parse --foo --baz key=val
        getoptlong dump
    '
    assert_success
    assert_output --partial '[_opts[baz]]="%baz"'
    assert_output --partial '[_opts[f]]="foo"'
    # Values themselves are not in _opts after processing, but in vars.
    # This tests the internal structure representation.
}

@test "getoptlong: flag - short option" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([verbose|v]=)
        getoptlong init OPTS
        getoptlong parse -v
        eval "$(getoptlong set)"
        assert_var_eq "verbose" "1"
    '
    assert_success
}

@test "getoptlong: flag - long option" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([verbose|v]=)
        getoptlong init OPTS
        getoptlong parse --verbose
        eval "$(getoptlong set)"
        assert_var_eq "verbose" "1"
    '
    assert_success
}

@test "getoptlong: flag - multiple flags" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([verbose|v]= [quiet|q]=)
        getoptlong init OPTS
        getoptlong parse -v -q
        eval "$(getoptlong set)"
        assert_var_eq "verbose" "1"
        assert_var_eq "quiet" "1"
    '
    assert_success
}

@test "getoptlong: flag - incrementing" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([debug|d]=0) # Incremental starts at 0
        getoptlong init OPTS
        getoptlong parse -d -d --debug
        eval "$(getoptlong set)"
        assert_var_eq "debug" "3" # 0->1, 1->2, 2->3
    '
    assert_success
}

@test "getoptlong: flag - negated long option" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([feature|f]=1) # Initially set
        getoptlong init OPTS
        getoptlong parse --no-feature
        eval "$(getoptlong set)"
        assert_var_eq "feature" "" # Negated sets to empty
    '
    assert_success
}

@test "getoptlong: option with required arg - short, attached" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([output|o:]=)
        getoptlong init OPTS
        getoptlong parse -ofile.txt
        eval "$(getoptlong set)"
        assert_var_eq "output" "file.txt"
    '
    assert_success
}

@test "getoptlong: option with required arg - short, separate" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([output|o:]=)
        getoptlong init OPTS
        getoptlong parse -o file.txt
        eval "$(getoptlong set)"
        assert_var_eq "output" "file.txt"
    '
    assert_success
}

@test "getoptlong: option with required arg - long, with equals" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([output|o:]=)
        getoptlong init OPTS
        getoptlong parse --output=file.txt
        eval "$(getoptlong set)"
        assert_var_eq "output" "file.txt"
    '
    assert_success
}

@test "getoptlong: option with required arg - long, separate" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([output|o:]=)
        getoptlong init OPTS
        getoptlong parse --output file.txt
        eval "$(getoptlong set)"
        assert_var_eq "output" "file.txt"
    '
    assert_success
}

@test "getoptlong: option with required arg - missing argument (EXIT_ON_ERROR=1)" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([output|o:]=)
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse --output
        # Script should exit due to missing arg
    '
    assert_failure # Expecting script to fail
    assert_output --partial "option requires an argument -- output"
}

@test "getoptlong: option with optional arg - long, with value" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([param|p?]=default)
        getoptlong init OPTS
        getoptlong parse --param=value
        eval "$(getoptlong set)"
        assert_var_eq "param" "value"
    '
    assert_success
}

@test "getoptlong: option with optional arg - long, no value" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([param|p?]=default)
        getoptlong init OPTS
        getoptlong parse --param
        eval "$(getoptlong set)"
        assert_var_eq "param" "" # Set to empty string
    '
    assert_success
}

@test "getoptlong: option with optional arg - short, no value" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([param|p?]=default)
        getoptlong init OPTS
        getoptlong parse -p
        eval "$(getoptlong set)"
        assert_var_eq "param" "" # Set to empty string
    '
    assert_success
}

@test "getoptlong: option with optional arg - not provided" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([param|p?]=default_val) # Default in definition
        getoptlong init OPTS
        getoptlong parse # No option provided
        eval "$(getoptlong set)"
        # 'param' should be 'default_val' as per its initial declaration in OPTS
        # The 'getoptlong set' does not change it if not parsed.
        assert_var_eq "param" "default_val"
    '
    assert_success
}


@test "getoptlong: array option - long, multiple instances" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([item|i@]=())
        getoptlong init OPTS
        getoptlong parse --item apple --item banana
        eval "$(getoptlong set)"
        assert_array_eq "item" "apple" "banana"
    '
    assert_success
}

@test "getoptlong: array option - short, multiple instances" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([item|i@]=())
        getoptlong init OPTS
        getoptlong parse -i apple -i banana
        eval "$(getoptlong set)"
        assert_array_eq "item" "apple" "banana"
    '
    assert_success
}

@test "getoptlong: array option - long, comma-separated" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([item|i@]=())
        getoptlong init OPTS
        getoptlong parse --item=apple,banana,cherry
        eval "$(getoptlong set)"
        assert_array_eq "item" "apple" "banana" "cherry"
    '
    assert_success
}

@test "getoptlong: array option - long, space-separated in quotes" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([item|i@]=())
        getoptlong init OPTS
        getoptlong parse --item "apple banana cherry"
        eval "$(getoptlong set)"
        assert_array_eq "item" "apple" "banana" "cherry"
    '
    assert_success
}

@test "getoptlong: array option - with default values" {
    run bash -c '
        source ../../../getoptlong.sh
        # Note: Default array values are tricky with `declare -A OPTS=([arr@]="(val1 val2)")`
        # getoptlong.sh initializes the array variable itself.
        declare -A OPTS=([items|I@]=) # Define as array
        getoptlong init OPTS
        # Initialize variable directly before parse if needed for "defaults" not overwritten
        items=("default1" "default2")
        getoptlong parse --items new1 --items new2
        eval "$(getoptlong set)"
        # The behavior of getoptlong is to append or overwrite based on its logic.
        # For array types, it appends.
        assert_array_eq "items" "default1" "default2" "new1" "new2"
    '
    assert_success
}

@test "getoptlong: hash option - long, multiple instances" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([data|D%]=())
        getoptlong init OPTS
        getoptlong parse --data name=Alice --data age=30
        eval "$(getoptlong set)"
        assert_assoc_array_contains "data" "name" "Alice"
        assert_assoc_array_contains "data" "age" "30"
    '
    assert_success
}

@test "getoptlong: hash option - short, multiple instances" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([data|D%]=())
        getoptlong init OPTS
        getoptlong parse -D name=Alice -D age=30
        eval "$(getoptlong set)"
        assert_assoc_array_contains "data" "name" "Alice"
        assert_assoc_array_contains "data" "age" "30"
    '
    assert_success
}

@test "getoptlong: hash option - long, comma-separated" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([data|D%]=())
        getoptlong init OPTS
        getoptlong parse --data name=Alice,age=30,city=Wonderland
        eval "$(getoptlong set)"
        assert_assoc_array_contains "data" "name" "Alice"
        assert_assoc_array_contains "data" "age" "30"
        assert_assoc_array_contains "data" "city" "Wonderland"
    '
    assert_success
}

@test "getoptlong: hash option - implicit value '1'" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([flags|F%]=())
        getoptlong init OPTS
        getoptlong parse --flags enabled,visible
        eval "$(getoptlong set)"
        assert_assoc_array_contains "flags" "enabled" "1"
        assert_assoc_array_contains "flags" "visible" "1"
    '
    assert_success
}


@test "getoptlong: callback - basic execution" {
    run bash -c '
        source ../../../getoptlong.sh
        _callback_func() { echo "Callback for $1 with value $2" >&3 ; }
        declare -A OPTS=([action|a:]=)
        getoptlong init OPTS
        getoptlong callback action _callback_func
        getoptlong parse --action perform
        eval "$(getoptlong set)"
        assert_var_eq "action" "perform"
    '
    assert_success
    # Check stderr (fd 3 in the script) for callback message
    [[ "${lines[0]}" == "Callback for action with value perform" ]]
}

@test "getoptlong: callback - default name" {
    run bash -c '
        source ../../../getoptlong.sh
        help() { echo "Help called with $1" >&3 ; }
        declare -A OPTS=([help|h]=)
        getoptlong init OPTS
        getoptlong callback help # Uses 'help' as function name
        getoptlong parse --help
        eval "$(getoptlong set)"
        assert_var_eq "help" "1"
    '
    assert_success
    [[ "${lines[0]}" == "Help called with 1" ]] # Callback receives the value
}

@test "getoptlong: integer validation - valid" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([count|c:=i]=0)
        getoptlong init OPTS
        getoptlong parse --count 123
        eval "$(getoptlong set)"
        assert_var_eq "count" "123"
    '
    assert_success
}

@test "getoptlong: integer validation - invalid" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([count|c:=i]=0)
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse --count abc
    '
    assert_failure
    assert_output --partial "abc: not an integer"
}

@test "getoptlong: float validation - valid" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([value|v:=f]=0)
        getoptlong init OPTS
        getoptlong parse --value 3.14
        eval "$(getoptlong set)"
        assert_var_eq "value" "3.14"
    '
    assert_success
}

@test "getoptlong: float validation - invalid" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([value|v:=f]=0)
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse --value xyz
    '
    assert_failure
    assert_output --partial "xyz: not a number"
}

@test "getoptlong: regex validation - valid" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([mode|m:=(^(fast|slow)$)]=)
        getoptlong init OPTS
        getoptlong parse --mode fast
        eval "$(getoptlong set)"
        assert_var_eq "mode" "fast"
    '
    assert_success
}

@test "getoptlong: regex validation - invalid" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([mode|m:=(^(fast|slow)$)]=)
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse --mode medium
    '
    assert_failure
    assert_output --partial "medium: invalid argument"
}

@test "getoptlong: PERMUTE - non-option arguments collected" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([verbose|v]=) GOL_ARGV=()
        getoptlong init OPTS PERMUTE=GOL_ARGV
        getoptlong parse arg1 -v arg2 -- arg3
        eval "$(getoptlong set)"
        assert_var_eq "verbose" "1"
        assert_array_eq "GOL_ARGV" "arg1" "arg2" "arg3"
    '
    assert_success
}

@test "getoptlong: configure - change EXIT_ON_ERROR" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([file|f:]=)
        getoptlong init OPTS EXIT_ON_ERROR=0 # Initially don't exit
        getoptlong parse --file # Missing arg, but should not exit yet
        assert_var_unset "file" # Should not be set

        getoptlong configure EXIT_ON_ERROR=1
        getoptlong parse --file # Now it should exit
    '
    assert_failure # The second parse should fail and exit
    assert_output --partial "option requires an argument -- file"
}

@test "getoptlong: option name with hyphens" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([some-long-option|s]=)
        getoptlong init OPTS
        getoptlong parse --some-long-option
        eval "$(getoptlong set)"
        assert_var_eq "some_long_option" "1"
    '
    assert_success
}

@test "getoptlong: short options combined" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([x]= [v]= [f:]=)
        getoptlong init OPTS
        getoptlong parse -xvfvalue
        eval "$(getoptlong set)"
        assert_var_eq "x" "1"
        assert_var_eq "v" "1"
        assert_var_eq "f" "value"
    '
    assert_success
}

@test "getoptlong: short options combined with last needing arg" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([x]= [v]= [f:]=)
        getoptlong init OPTS
        getoptlong parse -xvffile
        eval "$(getoptlong set)"
        assert_var_eq "x" "1"
        assert_var_eq "v" "1"
        assert_var_eq "f" "file"
    '
    assert_success
}

@test "getoptlong: short options combined, arg separated" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([x]= [v]= [f:]=)
        getoptlong init OPTS
        getoptlong parse -xvf file
        eval "$(getoptlong set)"
        assert_var_eq "x" "1"
        assert_var_eq "v" "1"
        assert_var_eq "f" "file"
    '
    assert_success
}

@test "getoptlong: unknown short option" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([a]=)
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse -b
    '
    assert_failure
    assert_output --partial "invalid option -- b" # Error message from getopts
}

@test "getoptlong: unknown long option" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([alpha]=)
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse --beta
    '
    assert_failure
    assert_output --partial "no such option -- --beta"
}

@test "getoptlong: long option does not take arg, but given" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([flag]=) # No arg expected
        getoptlong init OPTS EXIT_ON_ERROR=1
        getoptlong parse --flag=value
    '
    assert_failure
    assert_output --partial "does not take an argument -- flag"
}

@test "getoptlong: SILENT option" {
    run bash -c '
        source ../../../getoptlong.sh
        declare -A OPTS=([output|o:]=)
        getoptlong init OPTS EXIT_ON_ERROR=1 SILENT=1
        getoptlong parse --output
        # Script should exit due to missing arg, but no stderr output
    '
    assert_failure
    assert_output "" # No error message expected on stderr
}
