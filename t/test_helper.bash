#!/usr/bin/env bash

# Load getoptlong.sh relative to the test file's location
# Bats changes directory to the test file's directory
load '../../../getoptlong.sh'

# Helper function to run a script with arguments and capture output
run_script() {
    local script_path="$1"
    shift
    bash "$script_path" "$@"
}

# Helper function to assert that a variable is set to a specific value
assert_var_eq() {
    local var_name="$1"
    local expected_value="$2"
    local actual_value
    eval "actual_value=\$$var_name"

    if [[ "$actual_value" == "$expected_value" ]]; then
        return 0 # Success
    else
        echo "Error: Expected $var_name to be '$expected_value', but got '$actual_value'" >&2
        return 1 # Failure
    fi
}

# Helper function to assert that a variable is unset
assert_var_unset() {
    local var_name="$1"
    if ! declare -p "$var_name" &>/dev/null; then
        return 0 # Success
    elif [[ -z "${!var_name}" ]]; then # Also treat empty string as effectively unset for some tests
        return 0 # Success
    else
        local actual_value
        eval "actual_value=\$$var_name"
        echo "Error: Expected $var_name to be unset, but it is set to '$actual_value'" >&2
        return 1 # Failure
    fi
}

# Helper function to assert that an array contains specific elements in order
assert_array_eq() {
    local array_name="$1"
    shift
    local expected_elements=("$@")
    local actual_elements_str
    eval "actual_elements_str="\${$array_name[*]}""
    # shellcheck disable=SC2207
    local actual_elements=($(echo $actual_elements_str)) # Split by space, consider IFS if necessary

    if [[ "${#actual_elements[@]}" -ne "${#expected_elements[@]}" ]]; then
        echo "Error: Array $array_name: expected ${#expected_elements[@]} elements, got ${#actual_elements[@]}" >&2
        echo "Expected: (${expected_elements[*]})" >&2
        echo "Actual  : (${actual_elements[*]})" >&2
        return 1
    fi

    for i in "${!expected_elements[@]}"; do
        if [[ "${actual_elements[$i]}" != "${expected_elements[$i]}" ]]; then
            echo "Error: Array $array_name at index $i: expected '${expected_elements[$i]}', got '${actual_elements[$i]}'" >&2
            echo "Expected: (${expected_elements[*]})" >&2
            echo "Actual  : (${actual_elements[*]})" >&2
            return 1
        fi
    done
    return 0
}

# Helper function to assert that an associative array contains a specific key-value pair
assert_assoc_array_contains() {
    local array_name="$1"
    local key="$2"
    local expected_value="$3"
    local actual_value
    eval "actual_value="\${$array_name[$key]}""

    if [[ "$actual_value" == "$expected_value" ]]; then
        return 0 # Success
    else
        echo "Error: Associative array $array_name: for key '$key', expected '$expected_value', but got '$actual_value'" >&2
        # Optionally, print the whole array for debugging
        # eval "declare -p $array_name" >&2
        return 1 # Failure
    fi
}

# Helper function to assert that a command an exits with status 0
assert_success() {
    run "$@"
    [[ "$status" -eq 0 ]]
}

# Helper function to assert that a command an exits with status non-0
assert_failure() {
    run "$@"
    [[ "$status" -ne 0 ]]
}
