#!/usr/bin/env bats

# Load the modified test_helper.bash which sources getoptlong.sh
load 'test_helper'

# Test: getoptlong init and version
@test "getoptlong: init and version" {
    run bash -c '
        # getoptlong.sh is sourced by test_helper.bash loaded above
        getoptlong version
    '
    assert_success
    assert_output --partial "0.01" # Assuming version is 0.01
}

# Test: Basic flag option (--verbose)
@test "getoptlong: flag - long option --verbose" {
    run bash -c '
        declare -A OPTS=([verbose|v]=)
        getoptlong init OPTS
        getoptlong parse --verbose
        eval "$(getoptlong set)"
        echo "verbose_val:\$verbose"
    '
    assert_success
    assert_output "verbose_val:1"
}

# Test: Basic flag option (-v)
@test "getoptlong: flag - short option -v" {
    run bash -c '
        declare -A OPTS=([verbose|v]=)
        getoptlong init OPTS
        getoptlong parse -v
        eval "$(getoptlong set)"
        echo "verbose_val:\$verbose"
    '
    assert_success
    assert_output "verbose_val:1"
}

# Test: Flag option, incrementing (-d -d)
@test "getoptlong: flag - incrementing -d -d" {
    run bash -c '
        declare -A OPTS=([debug|d]=0) # Initial value for increment
        getoptlong init OPTS
        getoptlong parse -d -d --debug
        eval "$(getoptlong set)"
        echo "debug_val:\$debug"
    '
    assert_success
    assert_output "debug_val:3"
}

# Test: Flag option, negated (--no-feature)
@test "getoptlong: flag - negated --no-feature" {
    run bash -c '
        declare -A OPTS=([feature|f]=1) # Initially set to 1
        getoptlong init OPTS
        getoptlong parse --no-feature
        eval "$(getoptlong set)"
        echo "feature_val:\$feature" # Should be empty after negation
    '
    assert_success
    assert_output "feature_val:"
}

# Test: Option with required argument (--file data.txt)
@test "getoptlong: required arg - long --file data.txt" {
    run bash -c '
        declare -A OPTS=([file|f:]=)
        getoptlong init OPTS
        getoptlong parse --file data.txt
        eval "$(getoptlong set)"
        echo "file_val:\$file"
    '
    assert_success
    assert_output "file_val:data.txt"
}

# Test: Option with required argument (-f data.txt)
@test "getoptlong: required arg - short -f data.txt" {
    run bash -c '
        declare -A OPTS=([file|f:]=)
        getoptlong init OPTS
        getoptlong parse -f data.txt
        eval "$(getoptlong set)"
        echo "file_val:\$file"
    '
    assert_success
    assert_output "file_val:data.txt"
}

# Test: Option with required argument (-fdata.txt, attached)
@test "getoptlong: required arg - short -fdata.txt (attached)" {
    run bash -c '
        declare -A OPTS=([file|f:]=)
        getoptlong init OPTS
        getoptlong parse -fdata.txt
        eval "$(getoptlong set)"
        echo "file_val:\$file"
    '
    assert_success
    assert_output "file_val:data.txt"
}

# Test: Option with optional argument (--optarg=value)
@test "getoptlong: optional arg - long --optarg=value" {
    run bash -c '
        declare -A OPTS=([optarg|o?]=default)
        getoptlong init OPTS
        getoptlong parse --optarg=value
        eval "$(getoptlong set)"
        echo "optarg_val:\$optarg"
    '
    assert_success
    assert_output "optarg_val:value"
}

# Test: Option with optional argument (--optarg, no value provided)
@test "getoptlong: optional arg - long --optarg (no value)" {
    run bash -c '
        declare -A OPTS=([optarg|o?]=default)
        getoptlong init OPTS
        getoptlong parse --optarg
        eval "$(getoptlong set)"
        echo "optarg_val:\$optarg" # Should be empty string
    '
    assert_success
    assert_output "optarg_val:"
}

# Test: Option with optional argument (not given, should retain default from OPTS array)
@test "getoptlong: optional arg - not given (retain default)" {
    run bash -c '
        declare -A OPTS=([optarg|o?]=default_value_in_opts)
        getoptlong init OPTS
        getoptlong parse # No args
        eval "$(getoptlong set)"
        echo "optarg_val:\$optarg"
    '
    assert_success
    assert_output "optarg_val:default_value_in_opts"
}

# Test: Array option (--item val1 --item val2)
@test "getoptlong: array option - long --item val1 --item val2" {
    run bash -c '
        declare -A OPTS=([item|i@]=())
        getoptlong init OPTS
        getoptlong parse --item val1 --item val2
        eval "$(getoptlong set)"
        echo "item_vals:\${item[*]}" # Bash array to space-separated string
    '
    assert_success
    assert_output "item_vals:val1 val2"
}

# Test: Array option (-i val1 -i val2)
@test "getoptlong: array option - short -i val1 -i val2" {
    run bash -c '
        declare -A OPTS=([item|i@]=())
        getoptlong init OPTS
        getoptlong parse -i val1 -i val2
        eval "$(getoptlong set)"
        echo "item_vals:\${item[*]}"
    '
    assert_success
    assert_output "item_vals:val1 val2"
}

# Test: Array option (--item=val1,val2,val3 comma separated)
@test "getoptlong: array option - long --item=v1,v2,v3 (comma separated)" {
    run bash -c '
        declare -A OPTS=([item|i@]=())
        getoptlong init OPTS
        getoptlong parse --item=v1,v2,v3
        eval "$(getoptlong set)"
        echo "item_vals:\${item[*]}"
    '
    assert_success
    assert_output "item_vals:v1 v2 v3" # Default IFS for getoptlong splits by comma too
}


# Test: Hash option (--data key1=val1 --data key2=val2)
@test "getoptlong: hash option - long --data k1=v1 --data k2=v2" {
    run bash -c '
        declare -A OPTS=([data|D%]=())
        getoptlong init OPTS
        getoptlong parse --data k1=v1 --data k2=v2
        eval "$(getoptlong set)"
        # Order of keys might vary, so check presence of both
        # For simplicity in this output-based test, we might need to sort or check individually.
        # Let's output specific known keys for now.
        echo "data_k1:\${data[k1]}"
        echo "data_k2:\${data[k2]}"
    '
    assert_success
    assert_line --index 0 "data_k1:v1"
    assert_line --index 1 "data_k2:v2"
}

# Test: Hash option (-D k1=v1 -D k2=v2)
@test "getoptlong: hash option - short -D k1=v1 -D k2=v2" {
    run bash -c '
        declare -A OPTS=([data|D%]=())
        getoptlong init OPTS
        getoptlong parse -D k1=v1 -D k2=v2
        eval "$(getoptlong set)"
        echo "data_k1:\${data[k1]}"
        echo "data_k2:\${data[k2]}"
    '
    assert_success
    assert_line --index 0 "data_k1:v1"
    assert_line --index 1 "data_k2:v2"
}

# Test: Integer validation (=i) - valid
@test "getoptlong: validation - integer (=i) - valid" {
    run bash -c '
        declare -A OPTS=([count|c:=i]=0)
        getoptlong init OPTS
        getoptlong parse --count 123
        eval "$(getoptlong set)"
        echo "count_val:\$count"
    '
    assert_success
    assert_output "count_val:123"
}

# Test: Integer validation (=i) - invalid (check stderr)
@test "getoptlong: validation - integer (=i) - invalid (stderr)" {
    run bash -c '
        declare -A OPTS=([count|c:=i]=0)
        getoptlong init OPTS EXIT_ON_ERROR=1 # Ensure it exits
        getoptlong parse --count abc
        # Should not reach here
        echo "SHOULD_NOT_SEE_THIS"
    '
    assert_failure # Script should exit with error
    assert_output --partial "abc: not an integer" # Check stderr for message
}

# Test: Float validation (=f) - valid
@test "getoptlong: validation - float (=f) - valid" {
    run bash -c '
        declare -A OPTS=([value|v:=f]=0)
        getoptlong init OPTS
        getoptlong parse --value 3.14
        eval "$(getoptlong set)"
        echo "value_val:\$value"
    '
    assert_success
    assert_output "value_val:3.14"
}

# Test: Regex validation (=(regex)) - valid
@test "getoptlong: validation - regex (=(regex)) - valid" {
    run bash -c '
        declare -A OPTS=([mode|m:=(^(fast|slow)$)]=)
        getoptlong init OPTS
        getoptlong parse --mode fast
        eval "$(getoptlong set)"
        echo "mode_val:\$mode"
    '
    assert_success
    assert_output "mode_val:fast"
}

# Test: Callback execution
@test "getoptlong: callback - basic execution" {
    run bash -c '
        my_callback() { echo "Callback invoked for \$1 with value: \$2"; }
        declare -A OPTS=([action|a:]=)
        getoptlong init OPTS
        getoptlong callback action my_callback
        getoptlong parse --action perform_action
        eval "$(getoptlong set)"
        # Callback output goes to stdout in this setup for easy capture
    '
    assert_success
    assert_output "Callback invoked for action with value: perform_action"
}

# Test: PREFIX option
@test "getoptlong: configuration - PREFIX=test_" {
    run bash -c '
        declare -A OPTS=([long|l]=)
        getoptlong init OPTS PREFIX=test_
        getoptlong parse --long
        eval "$(getoptlong set)"
        echo "test_long_val:\$test_long"
    '
    assert_success
    assert_output "test_long_val:1"
}

# Test: PERMUTE option for non-option arguments
@test "getoptlong: configuration - PERMUTE" {
    run bash -c '
        declare -A OPTS=([verbose|v]=) GOL_MYARGS=() # Initialize GOL_MYARGS
        getoptlong init OPTS PERMUTE=GOL_MYARGS
        getoptlong parse arg1 --verbose arg2 -- arg3
        eval "$(getoptlong set)"
        echo "verbose_is:\$verbose"
        echo "permuted_args:\${GOL_MYARGS[*]}"
    '
    assert_success
    assert_line --index 0 "verbose_is:1"
    assert_line --index 1 "permuted_args:arg1 arg2 arg3"
}

# Test: getoptlong dump
@test "getoptlong: dump command" {
    run bash -c '
        declare -A OPTS=([foo|f]=bar [baz%]=)
        getoptlong init OPTS
        getoptlong parse --foo --baz key=val # Parse some options
        # The output of dump can be verbose and order-dependent.
        # We will just check if it runs and produces some output.
        # A more specific check might be too brittle.
        getoptlong dump
    '
    assert_success
    assert_output --partial '[_opts[' # Check for a common pattern in dump output
}

# Test: Combined short options (-xvf value)
@test "getoptlong: combined short options -xvf value" {
  run bash -c '
    declare -A OPTS=([xflag|x]= [vflag|v]= [file|f:]=)
    getoptlong init OPTS
    getoptlong parse -xvf somefile
    eval "$(getoptlong set)"
    echo "x:\$xflag v:\$vflag f:\$file"
  '
  assert_success
  assert_output "x:1 v:1 f:somefile"
}

# Test: Unknown long option (should produce error on stderr)
@test "getoptlong: error - unknown long option" {
  run bash -c '
    declare -A OPTS=([known]=)
    getoptlong init OPTS EXIT_ON_ERROR=1
    getoptlong parse --unknown-option
    echo "Should not be reached"
  '
  assert_failure
  assert_output --partial "no such option -- --unknown-option"
}

# Test: Option requires argument, but not given (stderr)
@test "getoptlong: error - required arg missing" {
  run bash -c '
    declare -A OPTS=([myfile|f:]=)
    getoptlong init OPTS EXIT_ON_ERROR=1
    getoptlong parse --myfile
    echo "Should not be reached"
  '
  assert_failure
  assert_output --partial "option requires an argument -- myfile"
}
