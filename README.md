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
    Call `getoptlong parse` with the script's arguments (`"$@"`). Then, use `eval "$(getoptlong set)"` to set the variables according to the parsed options. `getoptlong set` generates the shell commands (e.g., `variable=value`) to assign parsed option values to variables. `eval` executes these commands in the current shell, making the variables available. If `PERMUTE` was used, the non-option arguments will be available in the specified array (`GOL_ARGV` by default). Otherwise, use `shift $((OPTIND-1))` to remove processed options.

    ```bash
    getoptlong parse "$@" && eval "$(getoptlong set)" 
    ```

5.  **Access option values:**
    - If no `PREFIX` was set (and `EXPORT=yes` which is the default), options will be available as variables like `$help`, `$name`.
    - If `EXPORT=no` was set during `getoptlong init` and no `PREFIX` is used, option values are not set as individual shell variables. Instead, they are stored in the options array itself (e.g., if your options array is `OPTS`, you can access the value of an option like `name` via `${OPTS[name]}`).
    - If a `PREFIX` was set (e.g., `opt_`), options will be available as variables like `$opt_help`, `$opt_name` (regardless of `EXPORT` setting for direct variable access, but the array will also be populated).
    - Array options will be available as Bash arrays (e.g., `"${mode[@]}"`).
    - Hash options will be available as Bash associative arrays (e.g., `"${!config[@]}"` for keys, `"${config[key]}"` for values).
    - If `PERMUTE=<array_name>` was used during `getoptlong init` (or `PERMUTE` which defaults to `GOL_ARGV`), non-option arguments are collected into this array. For example, if `PERMUTE=my_args` was used, non-option arguments can be accessed via `"${my_args[@]}"`. If only `PERMUTE` was used (or `PERMUTE=GOL_ARGV`), they are in `"${GOL_ARGV[@]}"`.

## Functions

-   **`getoptlong init <opts_array_name> [CONFIGURATIONS...]`**:
    Initializes the library with the provided options definition array.

    **Re-initializing for different parsing contexts:**
    You can call `getoptlong init <new_opts_array> [CONFIGS...]` multiple times within a script. Each call effectively resets `getoptlong.sh` for a new parsing session with the specified options and configurations. This is useful if your script has different modes with distinct options, or for parsing arguments to sub-commands or complex callback functions. For an example, see the `help()` function in `ex/cmap`, which uses a local options array and re-initializes `getoptlong` to parse arguments specifically for the help output (like `--man`).

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
    Registers a callback function to be executed when a specific option is encountered. If `callback_function` is omitted, it defaults to `opt_name`. If `callback_function` is `-`, it uses the option name as the callback function name. The first argument passed to the callback function is always the name of the option that triggered it.

    You can also pass additional static arguments to your callback function. These arguments will be passed to the callback after the option name when the option is parsed:
    ```bash
    my_callback_func() {
        echo "Callback for option: $1" # Option name (e.g., "myopt")
        echo "Argument 1: $2"         # e.g., "arg1_for_callback"
        echo "Argument 2: $3"         # e.g., "arg2_for_callback"
    }
    declare -A OPTS=([myopt|m]=)
    getoptlong init OPTS
    # Register 'my_callback_func' for 'myopt', with two additional arguments
    getoptlong callback myopt my_callback_func "arg1_for_callback" "arg2_for_callback"

    # When -m or --myopt is parsed, my_callback_func will be called with:
    # $1 = "myopt"
    # $2 = "arg1_for_callback"
    # $3 = "arg2_for_callback"
    ```

    For registering multiple callbacks where the callback function name is the same as the option name (using the `-` shortcut for the callback function), you can use command substitution. This is useful when option names are also the names of the functions to be called.
    ```bash
    # Assuming 'help_func' and 'version_func' are defined shell functions
    # and 'help' and 'version' are defined as options.
    # We want to call help_func when --help is parsed, and version_func when --version is parsed.
    getoptlong callback help help_func
    getoptlong callback version version_func

    # If the option names themselves are the callback functions (e.g., a function named 'help' for option 'help'):
    # Assuming 'label' and 'trace' are defined as options AND as shell functions.
    getoptlong callback $(printf "%s -\n" label trace)
    # This is equivalent to:
    # getoptlong callback label -
    # getoptlong callback trace -
    # Which means, when --label is parsed, the function 'label' will be called.
    # When --trace is parsed, the function 'trace' will be called.
    ```

-   **`getoptlong configure <CONFIG_PARAM=VALUE> ...`**:
    Changes configuration parameters after initialization.

-   **`getoptlong export`**:
    Manually exports option variables. Useful if `EXPORT=no` was set during init.

-   **`getoptlong dump`**:
    Prints the internal state of the options and their values. Useful for debugging. For a more readable, tabular output, try piping its output to `column -t` (e.g., `getoptlong dump | column -t`).

## Option Types in Definition

When defining options in the associative array:

-   No suffix (e.g., `[help|h]`): A simple flag. Sets to `TRUE` (default `yes`) value if present.
-   `:` (e.g., `[name|n:]`): Option requires an argument.
-   `?` (e.g., `[output|o?]`): Option takes an optional argument. If the option is present but no argument is given, the corresponding variable will be set to the value of `TRUE` (default `yes`).
    If an option `[file|f?]` is defined:
    - Not providing the option: `$file` is not set (or empty if `EXPORT=no` and not using a prefix).
    - Providing `--file`: `$file` is set to the `TRUE` value (e.g., "yes").
    - Providing `--file=myfile.txt`: `$file` is set to "myfile.txt".

    To set a default filename (e.g., "default.txt") *only* when `--file` is provided without a value:
    ```bash
    # Assuming 'file' is the variable name after parsing (and using default EXPORT=yes, no PREFIX)
    TRUE_VALUE="$(getoptlong configure TRUE)" # Get the configured TRUE value
    DEFAULT_FILENAME_FOR_OPTIONAL="default.txt"

    if [[ -v file && "$file" == "$TRUE_VALUE" ]]; then
      file="$DEFAULT_FILENAME_FOR_OPTIONAL"
    fi
    # Now $file is either not set (if option was absent), "myfile.txt", or "default.txt"
    ```
    This is a common scenario for options with optional arguments.
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
