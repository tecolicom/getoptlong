# getoptlong.sh

`getoptlong.sh` is a Bash library for parsing command-line options in
shell scripts. It provides a flexible way to handle both short and
long options, option arguments, argument validation, and callbacks.

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

    Call `getoptlong init` with the name of your options array. You
    can provide configuration parameters after the array name.

    ```bash
    getoptlong init OPT
    ```

4.  **Setup callback function:**

    Callbacks allow you to execute custom functions when an option is
    parsed. This can be used for various purposes, such as triggering
    actions, setting complex states, or performing specialized
    argument processing.  You register a callback using `getoptlong
    callback <opt_name> [callback_function]`. If `callback_function`
    is omitted or is `-`, it defaults to `opt_name`.  For examples of
    using callbacks specifically for data validation, see the 'Using
    Callbacks for Validation' subsection within the '## Data
    Validation' section.  Example of a callback for a `help` option:

    ```bash
    # Help message function
    help_message() {
        echo "Usage: myscript [options] ..."
        echo "Options:"
        echo "  -h, --help    Show this help message and exit"
        # ... other help text ...
        exit 0
    }
    getoptlong callback help help_message
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
      `$help`, `$name`. Variables for flag-type options (those without
      ':', '?', '@', or '%') are incremented each time the flag is
      encountered, unless a specific value is assigned using the
      `option=value` syntax.

    - For an option with an optional argument (e.g., `[file|f?]`):

        *   If `--file=data` is used, `$file` will be `data`.

        *   If `--file` is used (no value provided after `=`), `$file`
            will be an empty string.

        *   If the option `[file|f?]=default` was defined with a
            default and `--file` is used, `$file` becomes an empty
            string.

        *   If the option is not present in the arguments, `$file`
            remains at its default value if one was set, or unset
            otherwise. You can use `${variable+isset}` or
            `${variable:-default}` bash constructs to handle these
            cases.

    - Values for array options are stored in Bash arrays (e.g., access
      with `"${mode[@]}"`).

    - Values for hash options are stored in Bash associative arrays
      (e.g., access keys with `"${!config[@]}"` and values with
      `"${config[key]}"`).

## Functions

-   **`getoptlong init <opts_array_name> [CONFIGURATIONS...]`**:

    Initializes the library with the provided options definition array.
    See "How to Specify Option Values" for details on value formats.

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

    Registers a callback function. Provide the option name and the
    corresponding callback function name. If the function name is `-` or
    omitted, it defaults to the option name. The callback is invoked
    with the option's value when the option is parsed.

-   **`getoptlong configure <CONFIG_PARAM=VALUE> ...`**:

    Changes configuration parameters after initialization. Note that
    some parameters (e.g., `PREFIX`) might not take full effect if
    changed after `getoptlong init` has processed option definitions.

-   **`getoptlong dump`**:

    Prints the internal state of the options and their values. Useful
    for debugging.

## How to Specify Option Values

This section details how values are provided for options based on
their definition in the "Option Types in Definition" section.

*   **Options Requiring an Argument (defined with `:`)**

    *   These options *must* receive an argument.

    *   **Long form** (e.g., `--output` for `[output|o:]`):

        *   `--output=value`: The value is part of the same argument.

        *   `--output value`: The value is the next distinct command-line argument.

    *   **Short form** (e.g., `-o` for `[output|o:]`):

        *   `-ovalue`: The value immediately follows the option
            letter, without an intervening space. This is a single
            command-line argument.

        *   `-o value`: The value is the next distinct command-line argument.

    *   **Important**: For short options, the syntax `-o=value` (using
        an equals sign) is **NOT** supported by `getoptlong.sh` as
        it's not standard for POSIX `getopts`. Use one of the valid
        short form syntaxes above.

*   **Flag Options (defined with no suffix)**

    *   These options **do not take an argument**. They are used to
        toggle features or indicate a boolean state.

    *   Examples: `-v` (for `[verbose|v]`) or `--verbose`.

    *   Their corresponding variable is typically used as a counter
        (incremented if the flag is present) or reflects a boolean
        state, as detailed in "Option Types in Definition".

*   **Options with Optional Arguments (defined with `?`)**

    *   **Long form** (e.g., `--param` for `[param|p?]`):

        *   `--param=value`: Provides `value` to the option. The
            variable `$param` will be set to `value`.

        *   `--param` (without `=value`): The variable `$param` will
            be set to an empty string. If a default value was defined
            for the option (e.g., `[param|p?]=defaultval`), this empty
            string assignment typically overrides the default for this
            specific invocation. If the option is not used at all, the
            predefined default (if any) remains.

    *   **Short form** (e.g., `-p` for `[param|p?]`):

        *   Using just `-p`: The variable `$param` will be set to an
            empty string (or default handling as described above for
            long options).

        *   The form `-pvalue` (attempting to attach a value directly
            to a short option with an optional argument) is generally
            **not supported or reliable.** To provide a value, the
            long option form (`--param=value`) is recommended.

*   **Array Options (defined with `@`)**

    *   These options collect multiple values into a Bash
        array. Typically, array options are used by specifying the
        option multiple times (e.g., `--array val1 --array val2` or
        `-a val1 -a val2` if `-a` is defined as an array option, e.g.,
        `[array|a@]`). This adds each `val` as a new element to the
        array.

    *   As a convenience for providing multiple items at once, you can
        also use a single option instance. For example, to provide the
        list for `[myarray|a@]` as a single argument:

        *   `--myarray=val1,val2,val3` or `--myarray "val1 val2 val3"`

        *   `-a val1,val2,val3` or `-a "val1 val2 val3"` (if `-a` is the short option)

    *   In this convenience form, values within the list are separated
        by commas, spaces, or tabs (controlled by the IFS setting,
        default is space, tab, newline). Quotes should be used if a
        single value within the list contains spaces/tabs, e.g.,
        `--myarray="first item,second item,third"`.

    *   The variable (e.g., `$myarray`) will be a Bash array; access elements with `${myarray[0]}`, etc.

*   **Hash Options (defined with `%`)**

    *   These options collect key-value pairs into a Bash associative
        array. Typically, hash options are used by specifying the
        option multiple times (e.g., `--hash key1=val1 --hash
        key2=val2` if `--hash` is defined as a hash option, e.g.,
        `[myhash|h%]` ). This adds each `key=value` pair to the
        associative array.

    *   As a convenience for providing multiple items at once, you can
        also use a single option instance. For example, to provide the
        pairs for `[myhash|h%]` as a single argument:

        *   `--myhash=key1=val1,key2=val2`

        *   `-h key1=val1,key2=val2` (if `-h` is the short option)

    *   In this convenience form, key-value pairs are separated by
        commas. Each pair is `key=value`.

    *   The variable (e.g., `$myhash`) will be a Bash associative
        array; access values with `${myhash[key1]}`, etc.

## Option Types in Definition

When defining options in the associative array:

-   No suffix (e.g., `[help|h]`): A simple flag that **does not take
    an argument** (e.g., used as `-h` or `--help`). Its associated
    variable is incremented each time the option is found (e.g., if
    `-h` is specified, `$help` becomes `1`; if specified again, it
    becomes `2`). While less common for typical flags, if a value is
    explicitly assigned using the long option form (e.g., `--help=5`),
    the variable will be set to that value.

-   `:` (e.g., `[name|n:]`): Option **requires an argument**. The
    methods for specifying this argument are detailed in the "How to
    Specify Option Values" section.

-   `?` (e.g., `[output|o?]`): Option takes an **optional
    argument**. If no argument is provided when the option is used,
    its variable is set to an empty string. See "How to Specify Option
    Values" for syntax details.

-   `@` (e.g., `[mode|m@]`): **Array option**. Collects one or more
    arguments into a Bash array. Array options inherently expect
    arguments (the items of the array) and **cannot** be combined with
    `?` (optional argument) or `:` (required argument) specifiers in
    their definition (e.g., `m@?` or `m@:` are invalid). See "How to
    Specify Option Values" for how these arguments are provided.

-   `%` (e.g., `[config|C%]`): **Hash option**. Collects one or more
    `key=value` pairs into a Bash associative array. Hash options
    inherently expect arguments (the `key=value` pairs) and **cannot**
    be combined with `?` (optional argument) or `:` (required
    argument) specifiers in their definition (e.g., `C%?` or `C%:` are
    invalid). See "How to Specify Option Values" for how these
    arguments are provided.

## Data Validation

`getoptlong.sh` provides mechanisms to validate the arguments passed
to options. This helps ensure that your script receives data in the
expected format.

**Scope of Validation:**

*   For options that take a single required (`:`) or optional (`?`)
    argument, the validation applies directly to that single argument.

*   When applied to array options (e.g., `[items|i@=i]`), the
    validation is performed on each individual item provided to the
    array.

*   For hash options (e.g., `[config|c%=(=(^[a-z]+=[0-9]+$))]`), the
    validation is applied to each `key=value` string as a whole.

### Built-in Type Validation

For options that take arguments (i.e., those defined with `:`, `@`, or
`%`), you can enforce basic data types:

*   **Integer Validation (`=i`)**: Appending `=i` to an option
    definition ensures that the provided argument (or each item in an
    array/each value in a hash) is a valid integer.

    *   Example for an option requiring an argument: `[count|c:=i]`

    *   Example for an array option: `[ids|id@=i]` (e.g., `--ids=1,2,3` or `--ids 1 --ids 2`)

    *   Example for a hash option: `[config_levels|cl%=i]` (e.g., `--config_levels=main=1,aux=2`)

    *   If an argument is not a valid integer, `getoptlong.sh` will
        report an error and the script will typically exit (this
        behavior is managed by the internal `_gol_validate` and
        `_gol_die` functions).

*   **Float Validation (`=f`)**: Appending `=f` to an option
    definition ensures that the provided argument(s) must be valid
    floating-point numbers.

    *   Example for an option requiring an argument: `[rate|r:=f]`

    *   Example for an array option: `[measurements|m@=f]` (e.g., `--measurements=1.2,3.05`)

    *   Example for a hash option: `[tolerances|t%=f]` (e.g., `--tolerances=low=0.01,high=0.05`)

    *   Similar to integer validation, a non-float argument will result in an error and script termination.

    *   Note: Float validation (`=f`) supports formats like
        `123.45`. Exponential notation (e.g., `1.2e-3`) and formats
        without digits on both sides of the decimal (e.g., `.9` or
        `9.`) are **not** supported.

### Custom Regex Validation

For more specific validation needs, you can provide a Bash extended
regular expression (ERE) using the `=(<regex>)` syntax. The
argument(s) provided to the option must match this regex.

*   **Syntax**: `[option_name|opt_char:<validation_type>=(<regex>)]`
    (applies to options defined with `:`, `@`, or `%`).

*   **Examples**:

    *   Option requiring a specific string set:
        `[mode|m:=(^(fast|slow|debug)$)]` (accepts only "fast",
        "slow", or "debug")

    *   Array of simple names: `[names|n@=(^[A-Za-z_]+$)]` (e.g.,
        `--names=foo,bar_baz` ensures each name consists of letters
        and underscores)

    *   Hash with specific key-value format:
        `[params|p%:=(^[a-z_]+=\d+$)]` (e.g.,
        `--params=rate=10,count=100` ensures keys are lowercase
        letters/underscores and values are digits).

*   If the argument (or any item in an array/hash) does not match the
    regex, `getoptlong.sh` will report an error and the script will
    exit.

### Using Callbacks for Validation

For more complex or procedural validation logic that goes beyond
simple type or regex checks, callback functions offer maximum
flexibility.

When a callback is defined for an option, the option's argument
(value) is passed as the first parameter (`$1`) to the callback
function. The callback can then perform any necessary checks. If
validation fails, the callback should typically `exit 1` (or `return
1` if `EXIT_ON_ERROR` is configured to be off or non-strict for the
script), often after printing a custom error message to `stderr`.

For example, to check if a 'count' option is a positive number:

```bash
# Callback function for the 'count' option
count_check() {
    if [[ "$1" =~ ^[0-9]+$ && "$1" -gt 0 ]]; then
        # Value is valid, optionally assign it or just return success
        # If the variable name is 'count', it's already set by getoptlong
        return 0
    else
        echo "Error: 'count' must be a positive integer, got '$1'." >&2
        exit 1 # Or return 1 if EXIT_ON_ERROR is configured differently
    fi
}
getoptlong callback count count_check
```

## Examples

The `ex/` directory contains example scripts demonstrating various
features of `getoptlong.sh`:

-   `ex/repeat.sh`: A utility to repeat commands, showcasing various
    option types including array, hash and incrementals.

-   `ex/prefix.sh`: Shows usage with the `PREFIX` configuration.

-   `ex/cmap`: Demonstrates color mapping, complex option parsing, and
    callbacks.

Refer to these examples for practical usage patterns.
