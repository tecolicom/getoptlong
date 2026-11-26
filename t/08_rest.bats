#!/usr/bin/env bats

# The * type: the arguments up to -- are taken as they are

load test_helper.bash

# rest_with [ init-params ] -- args...
# OPTS has a * option, column-opts|X, and a flag, lateral|L.
rest_with() {
    run env LC_ALL=C $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([column-opts|X*]= [lateral|L]=)
        declare -a ARGV=()
        params=() ; while [[ $1 != -- ]] ; do params+=("$1") ; shift ; done ; shift
        getoptlong init OPTS PERMUTE=ARGV "${params[@]}"
        getoptlong parse "$@"
        echo "parse:$? cols:$(printf "[%s]" "${column_opts[@]}") lateral:$lateral argv:$(printf "[%s]" "${ARGV[@]}")"
    ' _ "$@"
}

@test "rest: long option" {
    rest_with -- --column-opts -w 170 -s ' ' -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w][170][-s][ ] lateral: argv:[a.txt]"
}

@test "rest: short option" {
    rest_with -- -X -w 170 -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w][170] lateral: argv:[a.txt]"
}

@test "rest: short option joined with the first argument" {
    rest_with -- -X-w 170 -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w][170] lateral: argv:[a.txt]"
}

@test "rest: short option at the end of a cluster" {
    rest_with -- -LX -w -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w] lateral:1 argv:[a.txt]"
}

@test "rest: no arguments" {
    rest_with -- --column-opts -- -X -- a.txt
    assert_success
    assert_output "parse:0 cols:[] lateral: argv:[a.txt]"
}

@test "rest: the arguments are not split by DELIM" {
    rest_with -- -X 'a,b c' -- a.txt
    assert_success
    assert_output "parse:0 cols:[a,b c] lateral: argv:[a.txt]"
}

@test "rest: repeated options add to the array" {
    rest_with -- -X -w 170 -- --column-opts -s ' ' -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w][170][-s][ ] lateral: argv:[a.txt]"
}

@test "rest: options after the arguments are parsed" {
    rest_with -- -X -L -- -L a.txt
    assert_success
    assert_output "parse:0 cols:[-L] lateral:1 argv:[a.txt]"
}

@test "rest: with PERMUTE, the arguments around are kept in order" {
    rest_with -- a.txt -X -w -- b.txt
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[a.txt][b.txt]"
}

@test "rest: another -- ends the options" {
    rest_with -- -X -w -- -- -L
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[-L]"
}

@test "rest: --opt=value takes the value only" {
    rest_with -- --column-opts=-w 170 -- a.txt
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[170][a.txt]"
}

@test "rest: --no- empties the array" {
    rest_with -- -X -w -- --no-column-opts a.txt
    assert_success
    assert_output "parse:0 cols:[] lateral: argv:[a.txt]"
}

@test "rest: without --, the script exits" {
    rest_with -- --column-opts -w 170
    assert_failure
    assert_output "option requires terminating -- -- column-opts"
}

@test "rest: without -- in short option, the script exits" {
    rest_with -- -X -w 170
    assert_failure
    assert_output "option requires terminating -- -- X"
}

@test "rest: without --, parse returns 1 with EXIT_ON_ERROR disabled" {
    rest_with EXIT_ON_ERROR= -- -L -X -w 170
    assert_success
    assert_line --index 0 "option requires terminating -- -- X"
    assert_line --index 1 "parse:1 cols:[] lateral:1 argv:[]"
}

@test "rest: short option at the end requires an argument" {
    rest_with -- -X
    assert_failure
    assert_output --partial "option requires an argument -- X"
}

@test "rest: initial value" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([column-opts|X*]="(-w 80)")
        getoptlong init OPTS
        getoptlong parse -X -s " " -- a.txt
        eval "$(getoptlong set)"
        echo "cols:$(printf "[%s]" "${column_opts[@]}") args:$*"
    '
    assert_success
    assert_output "cols:[-w][80][-s][ ] args:a.txt"
}

@test "rest: validation of each argument" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([size|s*=i]=)
        getoptlong init OPTS
        getoptlong parse -s 1 x -- a.txt
        echo "not reached"
    '
    assert_failure
    assert_output "x: not an integer"
}

@test "rest: callback gets the arguments" {
    run $BASH -c '
        . ../script/getoptlong.sh
        column_opts() { echo "callback:$(printf "[%s]" "$@")" ; }
        declare -A OPTS=([column-opts|X*!]=)
        getoptlong init OPTS
        getoptlong parse -X -s " " 170 -- a.txt
        eval "$(getoptlong set)"
        echo "cols:$(printf "[%s]" "${column_opts[@]}") args:$*"
    '
    assert_success
    assert_line --index 0 "callback:[column-opts][-s][ ][170]"
    assert_line --index 1 "cols:[-s][ ][170] args:a.txt"
}

@test "rest: pass-through" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([column-opts|X*>cols]=)
        getoptlong init OPTS
        getoptlong parse --column-opts -w 170 -- -X -s " " -- a.txt
        eval "$(getoptlong set)"
        echo "cols:$(printf "[%s]" "${cols[@]}") args:$*"
    '
    assert_success
    assert_output "cols:[--column-opts][-w][170][--][-X][-s][ ][--] args:a.txt"
}

@test "rest: help" {
    run $BASH -c '
        . ../script/getoptlong.sh
        declare -A OPTS=([column-opts|X*]= [pane|C:]=)
        getoptlong init OPTS
        getoptlong help
    '
    assert_success
    assert_output --regexp "--column-opts #\.\.\. -- +-X #\.\.\. -- +add arguments up to -- to COLUMN-OPTS"
}

@test "rest: with PERMUTE, options after the arguments and a file are parsed" {
    rest_with -- -X -w -- a.txt -L b.txt
    assert_success
    assert_output "parse:0 cols:[-w] lateral:1 argv:[a.txt][b.txt]"
}

@test "rest: with PERMUTE, another -- after a file ends the options" {
    rest_with -- -X -w -- a.txt -- -L
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[a.txt][-L]"
}

@test "rest: without PERMUTE, parse stops at a file after the arguments" {
    rest_with PERMUTE= -- -X -w -- a.txt -L
    assert_success
    assert_output "parse:0 cols:[-w] lateral: argv:[]"
}

@test "rest: with PERMUTE, options after no arguments and a file are parsed" {
    rest_with -- -X -- a.txt -L b.txt
    assert_success
    assert_output "parse:0 cols:[] lateral:1 argv:[a.txt][b.txt]"
}

@test "rest: with PERMUTE, options after -X-- and a file are parsed" {
    rest_with -- -X-- a.txt -L b.txt
    assert_success
    assert_output "parse:0 cols:[] lateral:1 argv:[a.txt][b.txt]"
}

@test "rest: callback gets no arguments for no arguments and --no-" {
    run $BASH -c '
        . ../script/getoptlong.sh
        column_opts() { echo "callback:$#:$1" ; }
        declare -A OPTS=([column-opts|X*!]=)
        getoptlong init OPTS
        getoptlong parse -X -- --no-column-opts a.txt
    '
    assert_success
    assert_line --index 0 "callback:1:column-opts"
    assert_line --index 1 "callback:1:column-opts"
}
