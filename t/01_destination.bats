
#!/usr/bin/env bats

load test_helper.bash

. ../getoptlong.sh

# Test: Basic flag option (--verbose)
@test "getoptlong: flag - long option --verbose" {
    run bash -c '
        . ../getoptlong.sh
        # getoptlong.sh is sourced above by the test file itself
        declare -A OPTS=([verbose|v+VERB]=)
        getoptlong init OPTS
        getoptlong parse foo --verbose
        eval "$(getoptlong set)"
        echo "verbose_val:$VERB"
    '
    assert_success # bats-assert
    assert_output "verbose_val:1"
}

# Test: Basic flag option (-v)
@test "getoptlong: flag - short option -v" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([verbose|v+VERB]=)
        getoptlong init OPTS
        getoptlong parse -v
        eval "$(getoptlong set)"
        echo "verbose_val:$VERB"
    '
    assert_success
    assert_output "verbose_val:1"
}

# Test: Flag option, incrementing (-d -d)
@test "getoptlong: flag - incrementing -d -d -dd --debug" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([debug|d+DEB]=0)
        getoptlong init OPTS
        getoptlong parse -d -d -dd --debug
        eval "$(getoptlong set)"
        echo "debug_val:$DEB"
    '
    assert_success
    assert_output "debug_val:5"
}

# Test: Flag option, negated (--no-feature)
@test "getoptlong: flag - negated --no-feature" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([feature|f+FEA]=1)
        getoptlong init OPTS
        getoptlong parse --no-feature
        eval "$(getoptlong set)"
        echo "feature_val:$FEA"
    '
    assert_success
    assert_output "feature_val:"
}

# Test: Option with required argument (--file data.txt)
@test "getoptlong: required arg - long --file data.txt" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([file|f:FILE]=)
        getoptlong init OPTS
        getoptlong parse --file data.txt
        eval "$(getoptlong set)"
        echo "file_val:$FILE"
    '
    assert_success
    assert_output "file_val:data.txt"
}

# Test: Option with optional argument (--optarg=value)
@test "getoptlong: optional arg - long --optarg=value" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([optarg|o?ARG]=)
        getoptlong init OPTS
        getoptlong parse --optarg=value
        eval "$(getoptlong set)"
        echo "optarg_val:$ARG"
    '
    assert_success
    assert_output "optarg_val:value"
}

# Test: Array option (--item val1 --item val2)
@test "getoptlong: array option - long --item val1 --item val2" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([item|i@ARRAY]=)
        getoptlong init OPTS
        getoptlong parse --item val1 --item val2
        eval "$(getoptlong set)"
        echo "item_vals:${ARRAY[*]}"
    '
    assert_success
    assert_output "item_vals:val1 val2"
}

# Test: Hash option (--data key1=val1 --data key2=val2)
@test "getoptlong: hash option - long --data k1=v1 --data k2=v2" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([data|D%HASH]=)
        getoptlong init OPTS
        getoptlong parse --data k1=v1 --data k2=v2
        eval "$(getoptlong set)"
        echo "data_k1:${HASH[k1]}"
        echo "data_k2:${HASH[k2]}"
    '
    assert_success
    assert_line --index 0 "data_k1:v1"
    assert_line --index 1 "data_k2:v2"
}
