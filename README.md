# getoptlong.sh

`getoptlong.sh` is a Bash library for parsing command-line options in shell scripts. It supports short and long options, option arguments, and callbacks.

## Basic Usage

1.  **Source the library:**
    ```bash
    . getoptlong.sh
    ```

2.  **Define your options:**
    Create an associative array (e.g., `OPTS`) for your script's options. The key is the option definition string, and the value can be an initial default (though often left empty for basic options).

    ```bash
    declare -A OPTS=(
        [help|h]=          # A standard flag
        [file|f:]=         # Option with a required argument
        [output|o?]=       # Option with an optional argument
    )
    ```

3.  **Initialize the library:**
    Call `getoptlong init` with the name of your options array.
    ```bash
    getoptlong init OPTS
    ```

4.  **Parse arguments and set variables:**
    Use `getoptlong parse "$@"` followed by `eval "$(getoptlong set)"`.
    *   `getoptlong parse "$@"`: Processes the script's arguments according to the defined options.
    *   `getoptlong set`: Generates the shell commands (e.g., `help=1` or `file="input.txt"`) to assign the parsed option values to variables.
    *   `eval`: Executes these generated commands in the current shell, making the variables available.

    ```bash
    getoptlong parse "$@" && eval "$(getoptlong set)"
    ```

5.  **Access option values:**
    Variables are created based on option names (unless `PREFIX` or `EXPORT=no` is used, which will be covered in more detail later).

    ```bash
    # For the options defined above (assuming default EXPORT=1 and no PREFIX):
    # Variables will be $help, $file, $output

    if [[ $help -gt 0 ]]; then # Flags become 1 (or more if repeated)
        echo "Help flag is active. Value: $help"
        # Add script usage display here
    fi

    if [[ $file ]]; then # Check if file variable is non-empty
        echo "File is: $file"
    fi

    # For optional arguments, check if the variable is set.
    # If the option was present without a value, it will be an empty string.
    if [[ -v output ]]; then 
        if [[ $output ]]; then
            echo "Output is: $output"
        else
            echo "Output option was specified without a value."
        fi
    else
        echo "Output option was not specified."
    fi
    ```

## Option Types and Behaviors

The suffix used in the option definition string determines how an option behaves:

*   **No Suffix** (e.g., `[verbose|v]`) - Standard Flag:
    *   Each occurrence of the flag increments its variable by 1. If the variable is not already a number, it's treated as 0 before the first increment, so its value becomes `1` on the first occurrence, `2` on the second, and so on.
    *   Example:
        ```bash
        # Options: declare -A OPTS=([verbose|v]=)
        # Command: your_script -vv --verbose
        # Result: $verbose will be 3
        ```
    *   For long options, a `--no-option` prefix (e.g., `--no-verbose`) sets the variable to an empty string (effectively false). This does not affect the incremental count if the positive version was also used.

*   **`:`** (Colon, e.g., `[file|f:]`) - Requires Argument:
    *   This option must be followed by an argument (e.g., `-f filename` or `--file=filename`).
    *   The provided argument is assigned as the value to the option's variable.
    *   Parsing will fail if no argument is provided.

*   **`?`** (Question Mark, e.g., `[output|o?]`) - Optional Argument:
    *   This option may be followed by an argument.
    *   **Behavior:**
        *   If the option is **not specified** on the command line, the corresponding variable (e.g., `$output`) remains **unset**.
        *   If the option **is specified without a value** (e.g., `-o` or `--output`), the variable is set to an **empty string** (`""`).
        *   If the option **is specified with a value** (e.g., `-o filename` or `--output=filename`), the variable is set to that `filename`.
    *   **Checking the state:** Because there's a difference between an option not being present and an option being present with an explicitly empty or default value, you must first check if the variable is set using `[[ -v var_name ]]`.

        ```bash
        # Example for [output|o?]
        # After: getoptlong parse "$@" && eval "$(getoptlong set)"

        if [[ -v output ]]; then
            # 'output' variable is set, meaning --output or -o was used.
            if [[ -z "$output" ]]; then
                echo "Output option is present, but no specific value was given (it's an empty string)."
                # Handle as a flag-like presence or use a default.
            else
                echo "Output option is present with value: '$output'."
            fi
        else
            # 'output' variable is not set.
            echo "Output option was not specified."
        fi
        ```
    *   This check (`[[ -v var_name ]]`) is crucial for correctly interpreting the intent behind an optional argument.

*   **`+`** (Plus Sign, e.g., `[count|c+]`) - Incremental Option:
    *   The variable associated with this option is treated as an integer. Each time the option is encountered, its variable is incremented by 1. If the variable is not already a number, it's treated as 0 before the first increment, so its value becomes `1` on the first occurrence.
    *   Example:
        ```bash
        # Options: declare -A OPTS=([count|c+]=)
        # Command: your_script -c --count -cc
        # Result: $count will be 4
        ```

*   **`@`** (At Sign, e.g., `[include|I@]`) - Array Option:
    *   Allows the option to be specified multiple times. Each argument provided to the option is added as a new element to a Bash array.
    *   The array will have the same name as the option (e.g., `include` for `[include|I@]`).
    *   Example: If `-I path1 --include path2 -I path3` is used:
        *   The `include` array will contain `("path1" "path2" "path3")`.
    *   Accessing values:
        ```bash
        # Assuming 'include' is the array name
        echo "Number of include paths: ${#include[@]}"
        for path in "${include[@]}"; do
            echo "Include path: $path"
        done
        ```
    *   If the option is not used, the array will be empty.

*   **`%`** (Percent Sign, e.g., `[define|D%]`) - Hash Option (Associative Array):
    *   Allows the option to be specified multiple times. Each argument is treated as a key-value pair for a Bash associative array (hash).
    *   The associative array will have the same name as the option (e.g., `define` for `[define|D%]`).
    *   Arguments should be in the format `key=value`.
    *   If an argument is provided without an `=` sign (e.g., `--define key_only`), the `key_only` is added to the hash with a default value of `1`.
    *   Example: If `-D name=value1 --define flag_key -D another=val2` is used:
        *   The `define` associative array will contain `([name]="value1" [flag_key]="1" [another]="val2")`.
    *   Accessing values:
        ```bash
        # Assuming 'define' is the associative array name
        echo "Keys in 'define': ${!define[@]}"
        for key in "${!define[@]}"; do
            echo "Define: $key = ${define[$key]}"
        done
        ```
    *   If the option is not used, the associative array will be empty.

## Callbacks

You can register a function to be executed when a specific option is encountered during parsing. This is particularly useful for options that should trigger immediate actions, like displaying help or version information, or for options that require complex argument processing.

### Basic Callback Usage

1.  **Define your callback function:**
    The callback function typically receives two arguments:
    *   `$1`: The name of the option that triggered the callback (e.g., "version").
    *   `$2`: The value assigned to the option. For flags, this will be its incremental count (`1` on first occurrence, `2` on second, etc.). For options with arguments, it's the argument value. For optional arguments (`?`) provided without a value, it's an empty string.

    ```bash
    # Example callback for a --version flag
    display_version() {
        local opt_name="$1" # e.g., "version"
        local opt_val="$2"  # e.g., 1 (if --version is used once)

        echo "Program Version 1.0.0 (triggered by --${opt_name}, value: ${opt_val})"
        # A version callback often exits the script
        exit 0
    }
    ```

2.  **Register the callback:**
    Use `getoptlong callback <opt_name> <callback_function_name>` after `getoptlong init`.

    ```bash
    declare -A OPTS=([version|V]=) # A standard flag
    getoptlong init OPTS
    getoptlong callback version display_version

    getoptlong parse "$@" && eval "$(getoptlong set)"
    # If display_version exits, script execution might not reach here.
    ```
    When `--version` or `-V` is parsed, `display_version` is executed.

### Advanced Callback Features

#### Passing Custom Static Arguments to Callbacks

You can pass additional static arguments to your callback function. These arguments will be passed to the callback *after* the standard option name and option value arguments.

*   **Usage**: `getoptlong callback <opt_name> <func_name> [custom_arg1] [custom_arg2] ...`
*   **Example**:
    ```bash
    # Callback function accepting custom static arguments
    my_custom_handler() {
        local opt_name="$1"    # e.g., "mode"
        local opt_val="$2"     # e.g., "1" (if --mode was used)
        local static_arg1="$3" # e.g., "custom_data_1"
        local static_arg2="$4" # e.g., "custom_data_2"

        echo "Option: $opt_name, Value: $opt_val"
        echo "Static Arg 1: $static_arg1"
        echo "Static Arg 2: $static_arg2"
        # Process these arguments as needed
    }

    # Option definition
    declare -A OPTS=([mode|m]=) # Standard flag
    getoptlong init OPTS

    # Register callback with static arguments
    getoptlong callback mode my_custom_handler "custom_data_1" "custom_data_2"

    # If --mode is parsed, my_custom_handler will receive:
    # $1 = "mode"
    # $2 = "1"
    # $3 = "custom_data_1"
    # $4 = "custom_data_2"
    ```

#### Using `-` for Default Callback Name

If the name of your callback function is identical to the long name of the option, you can use a hyphen (`-`) as a shortcut for the `<callback_function_name>`.

*   **Example**:
    ```bash
    # Define a function named 'help'
    help() {
        echo "Displaying help..."
        # Show usage information
        exit 0
    }
    declare -A OPTS=([help|h]=)
    getoptlong init OPTS
    # This registers the 'help' function as the callback for the 'help' option.
    getoptlong callback help - 
    # Equivalent to: getoptlong callback help help
    ```

#### Dynamic Registration of Multiple Callbacks

You can register multiple callbacks efficiently using command substitution, especially useful with the `-` shortcut.

*   **Example**:
    ```bash
    # Assume functions 'handle_foo', 'handle_bar', 'option1', 'option2' are defined.
    # Options 'foo', 'bar', 'option1', 'option2' are also defined in your OPTS array.

    # To make handle_foo the callback for option 'foo', and handle_bar for option 'bar':
    getoptlong callback foo handle_foo bar handle_bar

    # If the callback function names are the same as the option names (e.g., function 'option1' for option 'option1'):
    getoptlong callback $(printf "%s -\n" option1 option2)
    # This is equivalent to:
    # getoptlong callback option1 -
    # getoptlong callback option2 -
    ```
This approach is convenient when you have several options that map directly to functions with the same names.

## Configuration Parameters

Configurations can be passed to `getoptlong init` after the options array name (e.g., `getoptlong init OPTS PREFIX=myopt_ EXPORT=0`). They modify the parsing behavior and how option variables are handled.

*   **`PREFIX=<string>`**:
    *   Prepend `<string>` to variable names when they are set by `eval "$(getoptlong set)"`.
    *   Example: `getoptlong init OPTS PREFIX=cfg_`. If you have an option `[mode|m]`, the variable set will be `cfg_mode`.
    *   This is useful to avoid variable name collisions in your script.

*   **`EXPORT[=0|1]`**:
    *   Controls whether option variables are set as global shell variables.
    *   `EXPORT=1` (or `EXPORT=yes`, default): Variables are created in the global scope (respecting `PREFIX`).
    *   `EXPORT=0` (or `EXPORT=no`): Variables are *not* set globally. Instead, option values are stored only within the options associative array itself. To access the value for an option `[file|f:]=` (assuming your array is `OPTS`), you would use `${OPTS[file]}`.
    *   Example: `getoptlong init OPTS EXPORT=0`.

*   **`PERMUTE[=<array_name>]`**:
    *   Controls how non-option arguments (arguments that are not options or option arguments) are handled.
    *   **Default behavior (no `PERMUTE`)**: Parsing stops at the first non-option argument. `eval "$(getoptlong set)"` will execute `shift $((OPTIND-1))` to remove all processed options from the script's positional parameters (`$@`). The first non-option argument will then be available as `$1`.
    *   **`PERMUTE`** (or `PERMUTE=GOL_ARGV`): All non-option arguments are collected, permuted to the end, and stored in the `GOL_ARGV` array (by default). `eval "$(getoptlong set)"` will also update the script's positional parameters (`$@`) to contain only these permuted non-option arguments. This allows options to be interspersed with non-option arguments (e.g., `command --option1 arg1 --option2 arg2`).
    *   **`PERMUTE=<custom_array>`**: Same as `PERMUTE`, but non-option arguments are stored in the specified `<custom_array>` name. `$@` is also updated to this custom array's content.
    *   Example: `getoptlong init OPTS PERMUTE=my_remaining_args`.

*   **`EXIT_ON_ERROR[=0|1]`**:
    *   Determines the script's behavior when a parsing error occurs (e.g., an option requiring an argument is missing it, or an unrecognized option is used).
    *   `EXIT_ON_ERROR=1` (or `EXIT_ON_ERROR=yes`, default): `getoptlong.sh` will print an error message to stderr and the script will exit with a non-zero status.
    *   `EXIT_ON_ERROR=0` (or `EXIT_ON_ERROR=no`): Suppresses the automatic exit. `getoptlong parse` will return a non-zero status code, allowing the script to perform custom error handling. Error messages from `getoptlong.sh` are still printed to stderr unless `SILENT=1` is also active.

*   **`SILENT[=0|1]`**:
    *   Controls whether the underlying `getopts` Bash builtin prints its own error messages for common issues like illegal options or missing arguments.
    *   `SILENT=0` (or `SILENT=no`, default): `getopts` is allowed to print its standard error messages.
    *   `SILENT=1` (or `SILENT=yes`): Suppresses `getopts` error messages. `getoptlong.sh` prepends the option string with a colon (`:`), which is the standard way to make `getopts` silent. `getoptlong.sh` may still print its own more specific error messages (e.g., for unknown long options), especially if `EXIT_ON_ERROR=1`.

*   **`DEBUG[=0|1]`**:
    *   Controls diagnostic output from `getoptlong.sh` itself.
    *   `DEBUG=0` (or `DEBUG=no`, default): No debug messages are printed.
    *   `DEBUG=1` (or `DEBUG=yes`): Prints detailed debug information to stderr, showing the internal state, option processing steps, and variable assignments. This is very useful for troubleshooting how options are parsed and why variables are set to certain values.

### Modifying Configurations After Initialization

You can change configuration parameters dynamically after `getoptlong init` has been called using the `getoptlong configure` command. This allows for temporary adjustments to parsing behavior within different parts of your script.

*   **Purpose**: To change configuration parameters after initial setup.
*   **Usage**: `getoptlong configure PARAMETER=value ...`
*   **Parameters**: It accepts the same parameters as `getoptlong init` (e.g., `PREFIX`, `EXPORT`, `PERMUTE`, `EXIT_ON_ERROR`, `SILENT`, `DEBUG`).
*   **Setting Boolean-like Values**:
    *   For true: `DEBUG=1` or `DEBUG=yes`. Simply using the parameter name like `DEBUG` also defaults to setting it to `1` (true).
    *   For false: `DEBUG=0` or `DEBUG=no`.
*   **Example**:
    ```bash
    # Initial setup with error exit suppressed
    getoptlong init OPTS EXIT_ON_ERROR=0

    # ... some script logic ...

    # Enable DEBUG mode for a specific parsing operation or section
    getoptlong configure DEBUG=1
    # ... potentially another getoptlong parse call or related logic ...
    
    # Disable DEBUG mode afterwards
    getoptlong configure DEBUG=0
    ```

## Utility Functions

`getoptlong.sh` provides a few utility functions that can be useful for script authors.

1.  **`getoptlong export`**:
    *   **Purpose**: Manually exports option variables into the global shell environment. This is primarily useful if `EXPORT=no` (or `EXPORT=0`) was set during `getoptlong init`.
    *   **Use Case**: You might initialize `getoptlong` with `EXPORT=0` to parse options and keep their values contained within the options associative array. After performing initial validation or logic based on the array values, you can then call `getoptlong export` to make these option variables globally available in the shell, adhering to any `PREFIX` that was set.
    *   **Example**:
        ```bash
        declare -A OPTS=([file|f:]= [verbose|v]=)
        # Initialize without global export
        getoptlong init OPTS EXPORT=0 

        getoptlong parse "$@" && eval "$(getoptlong set)" 
        # At this point, $file and $verbose are not global.
        # Values are in ${OPTS[file]} and ${OPTS[verbose]}.

        echo "Initial verbose state from OPTS: ${OPTS[verbose]}"

        # ... some logic based on OPTS array ...
        # For instance, decide to proceed only if verbose is 1
        if [[ "${OPTS[verbose]}" -eq 1 ]]; then
            echo "Verbose mode activated. Exporting variables globally."
            getoptlong export
            # Now $file and $verbose are available globally
            echo "Global File: $file, Global Verbose: $verbose"
        else
            echo "Not running in verbose mode. Variables remain local to OPTS."
        fi
        ```

2.  **`getoptlong dump`**:
    *   **Purpose**: Prints the internal state of the options associative array that was passed to `getoptlong init`. This output shows how `getoptlong.sh` has interpreted your option definitions (e.g., their types, associated arguments, if they are flags, etc.) and what their current values are after parsing. It also displays the current configuration settings (like `PREFIX`, `EXPORT`, `SILENT`, etc.).
    *   **Use Case**: This function is primarily intended for debugging your option parsing logic. If options are not behaving as expected, `getoptlong dump` can provide valuable insight into the library's internal state.
    *   **Readability Tip**: The output can be verbose. Piping it to `column -t` can significantly improve readability by formatting it into columns.
    *   **Example**:
        ```bash
        declare -A OPTS=(
            [file|f:]=foobar.txt  # Option with a default value in definition
            [verbose|v]=          # Standard flag
            [user|u:]=            # Option requiring argument
        )
        getoptlong init OPTS PREFIX=my_ EXPORT=0 SILENT=1

        # Example parsing some arguments
        getoptlong parse -v --file=test.txt --user=alice --unknown-opt -x
        eval "$(getoptlong set)" # Apply settings to OPTS, but not globally yet

        echo "Dumping options state:"
        getoptlong dump | column -t 
        
        # Example output might look like (columnated):
        # :file     test.txt
        # ~verbose  1
        # :user     alice
        # &EXPORT   0
        # &PREFIX   my_
        # &SILENT   1
        # ... and other internal or configuration entries ...
        ```

## Error Handling

`getoptlong.sh` provides mechanisms to handle parsing errors, ranging from automatic error reporting and exiting to more controlled custom handling.

1.  **Automatic Error Reporting & Exiting:**
    *   By default, if `EXIT_ON_ERROR=1` (which is the default configuration), `getoptlong.sh` will print an error message to stderr and cause the script to exit if a parsing error is encountered.
    *   Common parsing errors include:
        *   An option defined to require an argument is provided without one.
        *   An unrecognized option (not defined in your options array) is used on the command line.
        *   A long option is ambiguous (e.g. `--verb` when `--verbose` and `--verbA` are defined).

2.  **Disabling Automatic Exit (`EXIT_ON_ERROR=0`):**
    *   You can prevent `getoptlong.sh` from automatically exiting by setting `EXIT_ON_ERROR=0` (or `EXIT_ON_ERROR=no`) during `getoptlong init` or via `getoptlong configure`.
    *   In this mode, if a parsing error occurs, `getoptlong parse` will return a non-zero exit status (typically `1`). Your script can then check this status to implement custom error handling logic.
    *   Example:
        ```bash
        getoptlong init OPTS EXIT_ON_ERROR=0
        if ! getoptlong parse "$@"; then
            echo "An error occurred during option parsing. Please check your input." >&2
            # exit 1 # Or display usage, etc.
        fi
        eval "$(getoptlong set)"
        ```
    *   Note: Even with `EXIT_ON_ERROR=0`, `getoptlong.sh` itself (or the underlying Bash `getopts`) may still print error messages to stderr unless `SILENT=1` is also active.

3.  **Controlling `getopts` Built-in Messages (`SILENT=1`):**
    *   The `SILENT=1` (or `SILENT=yes`) configuration controls the verbosity of the Bash `getopts` command, which `getoptlong.sh` uses internally for short option parsing.
    *   When `SILENT=1`, `getopts` is instructed not to print its own standard error messages (e.g., "illegal option -- x" or "option requires an argument -- y"). This is achieved by `getoptlong.sh` prepending the internal option string with a colon (`:`).
    *   This allows you to provide all error messages yourself, perhaps via the error callbacks (see below) or custom checks.
    *   `getoptlong.sh` might still output its own specific errors, especially for long option parsing issues (like ambiguous long options or missing arguments for long options).

4.  **Error Callbacks (Advanced):**
    *   For fine-grained control when `EXIT_ON_ERROR=0` and `SILENT=1` are active, you can define callbacks for specific `getopts` error conditions. This is an advanced feature.
    *   **`getoptlong callback : <function_name>`**:
        *   Registers `<function_name>` to be called when a short option is missing its required argument.
        *   The callback function receives two arguments: the string `":"` and the character of the short option that was missing its argument.
    *   **`getoptlong callback ? <function_name>`**:
        *   Registers `<function_name>` to be called when an unrecognized short option is encountered.
        *   The callback function receives two arguments: the string `"?"` and the character of the unrecognized short option.
    *   **Example**:
        ```bash
        handle_parse_error() {
            local error_type="$1" # Will be ":" or "?"
            local bad_option="$2" # The problematic option character

            if [[ "$error_type" == ":" ]]; then
                echo "Custom Error: Option '-$bad_option' is missing its required argument." >&2
            elif [[ "$error_type" == "?" ]]; then
                echo "Custom Error: Unknown option '-$bad_option' was used." >&2
            fi
            # Custom exit or further handling logic
            exit 2 # Important to exit if the error is fatal for the script
        }

        # Setup
        declare -A OPTS=([file|f:]= [verbose|v]=)
        # Disable auto-exit and silence getopts to fully use callbacks for these errors
        getoptlong init OPTS EXIT_ON_ERROR=0 SILENT=1 
        getoptlong callback : handle_parse_error
        getoptlong callback ? handle_parse_error

        # Parse
        if ! getoptlong parse "$@"; then
            # If handle_parse_error did not exit, it implies a different kind of error 
            # (e.g., a long option error not covered by : or ? callbacks, or callback didn't exit).
            # Or, if callbacks are designed not to exit, this is where general error handling goes.
            echo "A parsing error occurred (potentially a long option issue or callback didn't exit)." >&2
            # exit 1 
        fi
        eval "$(getoptlong set)"
        # ... rest of your script ...
        ```
    *   **Note**: Using error callbacks effectively usually means setting `EXIT_ON_ERROR=0`. If the callback itself doesn't exit, `getoptlong parse` will still return a non-zero status, and your script must handle this return value to manage the error flow. These callbacks do not handle errors related to long options (e.g., `--unknown-long-opt`, `--long-opt-missing-arg`); those are typically handled by `getoptlong.sh`'s main error reporting (respecting `EXIT_ON_ERROR` and `SILENT` for its own messages).

## Advanced Usage: Re-initializing for Multiple Parse Contexts

A powerful feature of `getoptlong.sh` is the ability to call `getoptlong init` multiple times within the same script. Each invocation effectively resets the library's internal state, allowing for independent parsing tasks with different option sets and configurations. This is particularly useful in complex scripts.

**Key Concepts:**
*   **State Reset**: Every `getoptlong init` command re-initializes `getoptlong.sh`. Previous option definitions, configurations (like `PREFIX`, `EXPORT`, `PERMUTE`), and callback registrations are cleared before the new ones are applied.
*   **Independent Parsing**: This allows different parts of your script (e.g., main script vs. subcommands, or different stages of argument processing) to have their own distinct option parsing rules.

**Use Cases:**

*   **Subcommands**: If your script implements subcommands (e.g., `mytool deploy --target hostA` vs. `mytool test --all`), each subcommand can define and parse its own specific options after global options have been processed.
*   **Complex Callbacks**: A callback function triggered by an initial option parse might itself need to parse further arguments specific to that callback's action. The `help()` function in `ex/cmap` demonstrates this by parsing arguments like `--man` or `--usage` passed to the help action.
*   **Staged Parsing**: You might parse an initial set of arguments, then based on those, re-initialize to parse a subsequent set of arguments under different rules or configurations.

**Conceptual Example: Subcommand Parsing**

```bash
#!/bin/bash
. getoptlong.sh

# --- Global Options Setup ---
declare -A GLOBAL_OPTS=(
    [verbose|v]=
    [global_config|g:]=
)
# Initialize for global options, perhaps with PERMUTE to gather subcommand and its args
getoptlong init GLOBAL_OPTS PREFIX=g_ PERMUTE

# --- First Pass: Parse Global Options ---
# This parse will process global options and leave non-option arguments 
# (subcommand + its arguments) in GOL_ARGV and subsequently in $@ after 'eval'.
if ! getoptlong parse "$@"; then
    echo "Error parsing global options." >&2
    exit 1
fi
eval "$(getoptlong set)" # Sets $g_verbose, $g_global_config, and updates $@

# --- Subcommand Dispatch ---
# After 'eval', $@ contains only the non-option arguments.
# The first of these is assumed to be the subcommand name.
subcommand="${1:-}" # Default to empty if no subcommand
shift || true       # Shift subcommand name off, leaving its arguments in $@

if [[ "$subcommand" == "deploy" ]]; then
    echo "Global Verbose: $g_verbose, Global Config: $g_global_config"
    echo "Executing 'deploy' subcommand with arguments: $@"

    declare -A DEPLOY_OPTS=(
        [target|t:]=
        [dry-run|n]=
    )
    # Re-initialize for deploy subcommand options. No PERMUTE needed if only options expected.
    getoptlong init DEPLOY_OPTS PREFIX=deploy_ EXIT_ON_ERROR=1
    
    # Parse only the arguments intended for the subcommand (which are now in "$@")
    if getoptlong parse "$@"; then # Pass remaining arguments
        eval "$(getoptlong set)" # Sets $deploy_target, $deploy_dry_run
        echo "Deploying to target: '$deploy_target', Dry-run: '$deploy_dry_run'"
    else
        echo "Error parsing deploy options." >&2
        exit 1 # Or display deploy-specific help
    fi

elif [[ "$subcommand" == "test" ]]; then
    echo "Global Verbose: $g_verbose, Global Config: $g_global_config"
    echo "Executing 'test' subcommand with arguments: $@"
    # ... similar re-initialization and parsing for 'test' options ...
    echo "Test subcommand (options not parsed in this specific snippet)"

elif [[ -n "$subcommand" ]]; then
    echo "Unknown subcommand: $subcommand" >&2
    exit 1
else
    echo "No subcommand provided."
    # Display global help or default action
fi
```

**Note on Argument Handling for Subcommands:**
The exact method for isolating subcommand arguments (`subcommand_args` in the conceptual example) depends on whether `PERMUTE` was used for the initial global parse.
*   If `PERMUTE` was used globally: `GOL_ARGV` (or your custom permute array) will hold all non-option arguments. You'd typically take the first element as the subcommand and the rest as its arguments. `eval "$(getoptlong set)"` also makes these the new `$@`.
*   If `PERMUTE` was *not* used globally: `getoptlong parse` stops at the first non-option argument. `eval "$(getoptlong set)"` shifts processed global options, so `$1` becomes the subcommand, and `$2`, `$3`, etc., are its arguments.

For a concrete, working example of re-initialization within a callback, refer to the `help()` function in the `ex/cmap` script included with `getoptlong.sh`.

## Examples

The `ex/` directory contains various scripts that demonstrate different features and usage patterns of `getoptlong.sh`. These can be very helpful for understanding how to apply the library to specific needs.

*   **`ex/cmap`**: A complex script showcasing advanced option parsing, including array (`@`) and hash (`%`) option types, callbacks, and the use of `PERMUTE` for handling interspersed non-option arguments.
*   **`ex/no-export.sh`**: Demonstrates the `EXPORT=no` configuration (note: `EXPORT=1` is the default, meaning true/on). With `EXPORT=no`, option values are accessed directly from the options associative array instead of global shell variables.
*   **`ex/prefix.sh`**: Illustrates the `PREFIX` configuration for adding a prefix to the names of variables set by `getoptlong.sh`.
*   **`ex/repeat.sh`**: A utility that repeats a command, showing various option types like array (`@`), incremental (`+` / standard flags), and optional arguments (`?`) with default value handling.

Review these examples to see `getoptlong.sh` in action.
