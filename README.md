# getoptlong.sh

`getoptlong.sh` is a Bash library for parsing command-line options in shell scripts. It provides a flexible way to handle both short and long options, option arguments, and callbacks.

## Usage

1.  **Source the library:**
    ```bash
    . getoptlong.sh
    ```

2.  **Define your options:**
    Create an associative array (e.g., `OPTS`) to define your script's options. Each key is a string representing the option names (short and long, separated by `|`) and its properties (e.g., whether it takes an argument).

    ```bash
    declare -A OPTS=(
        [ help    | h   ]=  # Simple flag
        [ name    | n : ]=  # Option with a required argument
        [ output  | o ? ]=  # Option with an optional argument
        [ verbose | v + ]=  # Option that can be specified multiple times (increments)
        [ mode    | m @ ]=  # Array option
        [ config  | C % ]=  # Hash option
    )
    ```

3.  **Initialize the library:**
    Call `getoptlong init` with the name of your options array.

    ```bash
    getoptlong init OPTS
    ```

4.  **Parse the arguments:**
    Call `getoptlong parse` with the script's arguments (`"$@"`). Then, use `eval "$(getoptlong set)"` to set the variables according to the parsed options. If `PERMUTE` was used, the non-option arguments will be available in the specified array (`GOL_ARGV` by default). Otherwise, use `shift $((OPTIND-1))` to remove processed options.

    ```bash
    getoptlong parse "$@" && eval "$(getoptlong set)" 
    ```

5.  **Access option values:**
    - If no `PREFIX` was set, options will be available as variables like `$help`, `$name`.
    - If a `PREFIX` was set (e.g., `opt_`), options will be available as variables like `$opt_help`, `$opt_name`.
    - Array options will be available as Bash arrays (e.g., `"${mode[@]}"`).
    - Hash options will be available as Bash associative arrays (e.g., `"${!config[@]}"` for keys, `"${config[key]}"` for values).

## Functions

-   **`getoptlong init <opts_array_name> [CONFIGURATIONS...]`**:
    Initializes the library with the provided options definition array.
    -   `PERMUTE=<array_name>`: Non-option arguments will be collected into `<array_name>` (default: `GOL_ARGV`).
    -   `PREFIX=<string>`: Prepend `<string>` to variable names when setting them (default: empty).
    -   `EXPORT=<BOOL>`: Whether to export the option variables (default: `yes`).
    -   `EXIT_ON_ERROR=<BOOL>`: Whether to exit if an error occurs during parsing (default: `yes`).
    -   `TRUE=<value>`: Value for boolean flags when they are present (default: `yes`).
    -   `FALSE=<value>`: Value for boolean flags when explicitly negated with `no-` (default: empty).
    -   `SILENT=<BOOL>`: Suppress error messages (default: empty).
    -   `DEBUG=<BOOL>`: Enable debug messages (default: empty).

-   **`getoptlong parse "$@"`**:
    Parses the command-line arguments according to the initialized options.

-   **`getoptlong set`**:
    Returns a string of shell commands to set the variables based on parsed options. This should be evaluated using `eval`.

-   **`getoptlong callback <opt_name> [callback_function] ...`**:
    Registers a callback function to be executed when a specific option is encountered. If `callback_function` is omitted, it defaults to `opt_name`. If `callback_function` is `-`, it uses the option name as the callback function name.

-   **`getoptlong configure <CONFIG_PARAM=VALUE> ...`**:
    Changes configuration parameters after initialization.

-   **`getoptlong export`**:
    Manually exports option variables. Useful if `EXPORT=no` was set during init.

-   **`getoptlong dump`**:
    Prints the internal state of the options and their values. Useful for debugging.

## Option Types in Definition

When defining options in the associative array:

-   No suffix (e.g., `[help|h]`): A simple flag. Sets to `TRUE` (default `yes`) value if present.
-   `:` (e.g., `[name|n:]`): Option requires an argument.
-   `?` (e.g., `[output|o?]`): Option takes an optional argument.
-   `+` (e.g., `[verbose|v+]`): Incremental option. The variable is incremented each time the option is found.
-   `@` (e.g., `[mode|m@]`): Array option. Arguments are collected into an array.
-   `%` (e.g., `[config|C%]`): Hash option. Arguments in `key=value` format are collected into an associative array.

## Examples

The `ex/` directory contains example scripts demonstrating various features of `getoptlong.sh`:

-   `ex/cmap`: Demonstrates color mapping, complex option parsing, and callbacks.
-   `ex/no-export.sh`: Shows usage with `EXPORT=no`.
-   `ex/prefix.sh`: Shows usage with the `PREFIX` configuration.
-   `ex/repeat.sh`: A utility to repeat commands, showcasing various option types including array and incremental options.

Refer to these examples for practical usage patterns.
