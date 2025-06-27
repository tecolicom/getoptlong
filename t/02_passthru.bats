#!/usr/bin/env bats

# Load the helper (which loads bats-support and bats-assert)
load test_helper.bash
# Source getoptlong.sh to make its functions available for testing
. ../getoptlong.sh

# Test: Passthru - basic long option with value
@test "getoptlong: passthru - long option --passthru-opt val" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([passthru-opt|p:-my_passthru_array]=)
        declare -a my_passthru_array=()
        getoptlong init OPTS
        getoptlong parse --passthru-opt value1
        eval "$(getoptlong set)"
        echo "arr_len:${#my_passthru_array[@]}"
        echo "arr_0:${my_passthru_array[0]}"
        echo "arr_1:${my_passthru_array[1]}"
    '
    assert_success
    assert_line --index 0 "arr_len:2"
    assert_line --index 1 "arr_0:--passthru-opt"
    assert_line --index 2 "arr_1:value1"
}

# Test: Passthru - basic short option with value
@test "getoptlong: passthru - short option -p val" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([passthru-opt|p:-my_passthru_array]=)
        declare -a my_passthru_array=()
        getoptlong init OPTS
        getoptlong parse -p value2
        eval "$(getoptlong set)"
        echo "arr_len:${#my_passthru_array[@]}"
        echo "arr_0:${my_passthru_array[0]}"
        echo "arr_1:${my_passthru_array[1]}"
    '
    assert_success
    assert_line --index 0 "arr_len:2"
    assert_line --index 1 "arr_0:-p"
    assert_line --index 2 "arr_1:value2"
}

# Test: Passthru - flag option (no value)
@test "getoptlong: passthru - flag option --flag-opt" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([flag-opt+-my_flag_array]=)
        declare -a my_flag_array=()
        getoptlong init OPTS
        getoptlong parse --flag-opt
        eval "$(getoptlong set)"
        echo "arr_len:${#my_flag_array[@]}"
        echo "arr_0:${my_flag_array[0]}"
    '
    assert_success
    assert_line --index 0 "arr_len:1"
    assert_line --index 1 "arr_0:--flag-opt"
}

# Test: Passthru - combined with callback (!)
@test "getoptlong: passthru - combined with callback --cb-opt val" {
    run bash -c '
        . ../getoptlong.sh
        cb_func() { echo "Callback: $1 val=$2"; }
        declare -A OPTS=([cb-opt:!-my_cb_array]=)
        declare -a my_cb_array=()
        getoptlong init OPTS
        getoptlong callback cb-opt cb_func
        getoptlong parse --cb-opt cb_val
        eval "$(getoptlong set)"
        echo "arr_len:${#my_cb_array[@]}"
        echo "arr_0:${my_cb_array[0]}"
        echo "arr_1:${my_cb_array[1]}"
    '
    assert_success
    assert_output --partial "Callback: cb-opt val=cb_val"
    assert_line --index 1 "arr_len:2" # Callback output is first
    assert_line --index 2 "arr_0:--cb-opt"
    assert_line --index 3 "arr_1:cb_val"
}

# Test: Passthru - combined with required value (:)
@test "getoptlong: passthru - combined with required value --req-opt val" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([req-opt|r:-my_req_array]=) # Note the type is effectively ':-'
        declare -a my_req_array=()
        getoptlong init OPTS
        getoptlong parse --req-opt req_val
        eval "$(getoptlong set)"
        echo "arr_len:${#my_req_array[@]}"
        echo "arr_0:${my_req_array[0]}"
        echo "arr_1:${my_req_array[1]}"
    '
    assert_success
    assert_line --index 0 "arr_len:2"
    assert_line --index 1 "arr_0:--req-opt"
    assert_line --index 2 "arr_1:req_val"
}

# Test: Passthru - multiple options to the same array
@test "getoptlong: passthru - multiple options to same array" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=(
            [opt1|a:-common_array]=
            [opt2|b:-common_array]=
        )
        declare -a common_array=()
        getoptlong init OPTS
        getoptlong parse --opt1 val1 -b val2 --opt1 val3
        eval "$(getoptlong set)"
        echo "arr_len:${#common_array[@]}"
        echo "arr_0:${common_array[0]}"
        echo "arr_1:${common_array[1]}"
        echo "arr_2:${common_array[2]}"
        echo "arr_3:${common_array[3]}"
        echo "arr_4:${common_array[4]}"
        echo "arr_5:${common_array[5]}"
    '
    assert_success
    assert_line --index 0 "arr_len:6"
    assert_line --index 1 "arr_0:--opt1"
    assert_line --index 2 "arr_1:val1"
    assert_line --index 3 "arr_2:-b"
    assert_line --index 4 "arr_3:val2"
    assert_line --index 5 "arr_4:--opt1"
    assert_line --index 6 "arr_5:val3"
}

# Test: Passthru - default array name (based on option name)
@test "getoptlong: passthru - default array name" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=([default-array-opt+-]=) # Target array will be default_array_opt
        # Ensure default_array_opt is declared, or it might fail in strict mode or cause issues
        declare -a default_array_opt=()
        getoptlong init OPTS
        getoptlong parse --default-array-opt
        eval "$(getoptlong set)"
        echo "arr_len:${#default_array_opt[@]}"
        echo "arr_0:${default_array_opt[0]}"
    '
    assert_success
    assert_line --index 0 "arr_len:1"
    assert_line --index 1 "arr_0:--default-array-opt"
}

# Test: Passthru - help message
@test "getoptlong: passthru - help message" {
    run bash -c '
        . ../getoptlong.sh
        declare -A OPTS=(
            [my-pass|p:-pass_arr]=
            [another-pass:-another_arr]=
        )
        getoptlong init OPTS
        getoptlong help "My Script Usage"
    '
    assert_success
    assert_output --partial "passthrough to PASS_ARR"
    assert_output --partial "passthrough to ANOTHER_ARR"
}
