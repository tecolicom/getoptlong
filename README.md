# getoptlong.sh

`getoptlong.sh` is a Bash library for parsing command-line options in
shell scripts. It provides a flexible way to handle both short and
long options, option arguments, and callbacks.

## Usage

1.  **Source the library:**

    ```bash
    . getoptlong.sh
    ```

2.  **Define your options:**

    Create an associative array (e.g., `OPT`) to define your script's
    options.  Each key is a string representing the option names
    (short and long, separated by `|`) and its storage type character.
    Storage type can be followed `=` and data type character (e.g.,
    `i`: integer, `f`: float).

    ```bash
    declare -A OPT=(
        [ count     | c :=i ]=1  # require argument
        [ paragraph | p ?   ]=   # optional argument
        [ sleep     | i @=f ]=   # array type
        [ message   | m %   ]=   # hash type
        [ help      | h     ]=   # flag type
        [ debug     | d     ]=0  # incremental 
    )
    ```

3.  **Initialize the library:**

    Call `getoptlong init` with the name of your options array.  You
    can provide configuration parameter at this point following array
    name.

    ```bash
    getoptlong init OPT
    ```

4.  **Setup callback function:**

    Specify the option name and corresponding call back function (`-`
    means same name) and it will be called with given value whenever
    the option is parsed.

    ```bash
    getoptlong callback help - count -
    ```

    You can validate the value like this;
	
	```bash
    count() {
        [[ "$1" =~ ^[0-9]+$ ]] || { echo "$1: not a number" >&2; exit 1 ; }
    }
    ```

5.  **Parse the arguments:**

    Call `getoptlong parse` with the script's arguments
    (`"$@"`). Then, use `eval "$(getoptlong set)"` to set the
    variables according to the parsed options.

    ```bash
    getoptlong parse "$@" && eval "$(getoptlong set)" 
    ```

6.  **Access option values:**

    - By default, options will be available as simple variables like
      `$help`, `$name`.  All flag type options are incremental.

    - Optional argument has `unset` value initially.  Because empty
      string is assigned if the parameter is not givien, you need
      check it by `-v` or such.

    - Array options will be available as Bash arrays (e.g.,
      `"${mode[@]}"`).

    - Hash options will be available as Bash associative arrays (e.g.,
      `"${!config[@]}"` for keys, `"${config[key]}"` for values).

## Functions

-   **`getoptlong init <opts_array_name> [CONFIGURATIONS...]`**:

    Initializes the library with the provided options definition array.

    -   `PERMUTE=<array_name>`: Non-option arguments will be collected
        into `<array_name>` (default: `GOL_ARGV`).

    -   `PREFIX=<string>`: Prepend `<string>` to variable names when
        setting them (default: empty).

    -   `EXIT_ON_ERROR=<BOOL>`: Whether to exit if an error occurs
        during parsing (default: `1`).

    -   `SILENT=<BOOL>`: Suppress error messages (default: empty).

    -   `DEBUG=<BOOL>`: Enable debug messages (default: empty).

-   **`getoptlong parse "$@"`**:

    Parses the command-line arguments according to the initialized
    options.

-   **`getoptlong set`**:

    Returns a string of shell commands to set the variables based on
    parsed options. This should be evaluated using `eval`.

-   **`getoptlong callback <opt_name> [callback_function] ...`**:

    Registers a callback function to be executed when a specific
    option is encountered. If `callback_function` is omitted or `-`,
    it defaults to `opt_name`.

-   **`getoptlong configure <CONFIG_PARAM=VALUE> ...`**:

    Changes configuration parameters after initialization.  Some
    parameter (e.g., `PREFIX`) won't take effect after initialization.

-   **`getoptlong dump`**:

    Prints the internal state of the options and their values. Useful
    for debugging.

## Option Types in Definition

When defining options in the associative array:

-   No suffix (e.g., `[help|h]`): A simple flag. Sets to `1` value if
    it is empty and incremented each time the option is found.

-   `:` (e.g., `[name|n:]`): Option requires an argument.

-   `?` (e.g., `[output|o?]`): Option takes an optional argument.

-   `@` (e.g., `[mode|m@]`): Array option. Arguments are collected into an array.

-   `%` (e.g., `[config|C%]`): Hash option. Arguments in `key=value`
    format are collected into an associative array.

## Examples

The `ex/` directory contains example scripts demonstrating various
features of `getoptlong.sh`:

-   `ex/repeat.sh`: A utility to repeat commands, showcasing various
    option types including array, hash and incrementals.

-   `ex/prefix.sh`: Shows usage with the `PREFIX` configuration.

-   `ex/cmap`: Demonstrates color mapping, complex option parsing, and
    callbacks.

Refer to these examples for practical usage patterns.
