# getoptlong.sh

`getoptlong.sh` is a Bash library for parsing command-line options in
shell scripts. It provides a flexible way to handle options including
followings.

- Clear and expressive option syntax
- Supports both short options (e.g., `-h`) and long options (e.g.,
  `--help`)
- Allows options and non-option arguments to be freely mixed on the
  command line (PERMUTE)
- Supports flag type incremental option as well as required arguments,
  optional arguments, array-type, and hash-type options
- Provides validation for integer, floating-point, and custom regular
  expression patterns
- Enables registration of callback functions for each option for
  flexible processing
- Supports multiple calls, which enables to use different options in
  subcommands or perform own option analysis within functions
- Automatic generation of help option and help messages. Help option
  is implemented without explicit definition. Help message is
  generated from the option definition.

## Table of Contents

- [1. Introduction](#1-introduction)
- [2. Basic Usage](#2-basic-usage)
  - [2.1. Sourcing the Library](#21-sourcing-the-library)
  - [2.2. Creating the Option Definition Array](#22-creating-the-option-definition-array)
  - [2.3. Initializing getoptlong](#23-initializing-getoptlong)
  - [2.4. Parsing Command-Line Arguments](#24-parsing-command-line-arguments)
  - [2.5. Setting Parsed Results to Variables](#25-setting-parsed-results-to-variables)
  - [2.6. Accessing and Using Variables](#26-accessing-and-using-variables)
- [3. Detailed Option Definition](#3-detailed-option-definition)
  - [3.1. Basic Syntax](#31-basic-syntax)
  - [3.2. Option Types and Type Specifiers](#32-option-types-and-type-specifiers)
    - [3.2.1. Flag Options (No Suffix or `+`)](#321-flag-options-no-suffix-or-)
    - [3.2.2. Required Argument Options (`:`)](#322-required-argument-options--)
    - [3.2.3. Optional Argument Options (`?`)](#323-optional-argument-options--)
    - [3.2.4. Array Options (`@`)](#324-array-options--)
    - [3.2.5. Hash Options (`%`)](#325-hash-options--)
    - [3.2.6. Callback Options (`!`)](#326-callback-options--)
  - [3.3. Value Validation](#33-value-validation)
    - [3.3.1. Integer Validation (`=i`)](#331-integer-validation-i)
    - [3.3.2. Float Validation (`=f`)](#332-float-validation-f)
    - [3.3.3. Custom Regex Validation (`=(<regex>)`](#333-custom-regex-validation-regex)
- [4. Help Message Generation and Customization](#4-help-message-generation-and-customization)
  - [4.1. Automatic Help Option](#41-automatic-help-option)
  - [4.2. Help Message Content](#42-help-message-content)
    - [4.2.1. Option Descriptions (Comments `#`)](#421-option-descriptions-comments-)
    - [4.2.2. Type-Based Automatic Messages](#422-type-based-automatic-messages)
    - [4.2.3. Displaying Initial (Default) Values](#423-displaying-initial-default-values)
    - [4.2.4. Treating Flag Options as Counters](#424-treating-flag-options-as-counters)
  - [4.3. Overall Help Message Format](#43-overall-help-message-format)
    - [4.3.1. Customizing Synopsis (`USAGE` Setting)](#431-customizing-synopsis-usage-setting)
    - [4.3.2. Manual Display with `getoptlong help`](#432-manual-display-with-getoptlong-help)
  - [4.4. Help Message Structure](#44-help-message-structure)
- [5. Advanced Topics](#5-advanced-topics)
  - [5.1. Callback Function Details](#51-callback-function-details)
    - [5.1.1. Normal Callbacks (Post-processing)](#511-normal-callbacks-post-processing)
    - [5.1.2. Pre-processing Callbacks (`--before` / `-b`) (Newer Feature)](#512-pre-processing-callbacks---before---b-newer-feature)
    - [5.1.3. Error Handling in Callback Functions](#513-error-handling-in-callback-functions)
    - [5.1.4. Custom Validation using Callbacks](#514-custom-validation-using-callbacks)
  - [5.2. Specifying Destination (Newer Feature)](#52-specifying-destination-newer-feature)
  - [5.3. Option Pass-through](#53-option-pass-through)
  - [5.4. Runtime Configuration Changes (`getoptlong configure`)](#54-runtime-configuration-changes-getoptlong-configure)
  - [5.5. Dumping Internal State (`getoptlong dump`)](#55-dumping-internal-state-getoptlong-dump)
- [6. Standalone Usage](#6-standalone-usage)
- [7. Command Reference](#7-command-reference)
  - [7.1. `getoptlong init <opts_array_name> [CONFIGURATIONS...]`](#71-getoptlong-init-opts_array_name-configurations)
  - [7.2. `getoptlong parse "$@"`](#72-getoptlong-parse--)
  - [7.3. `getoptlong set`](#73-getoptlong-set)
  - [7.4. `getoptlong callback [-b|--before] <opt_name> [callback_function] ...`](#74-getoptlong-callback--b---before-opt_name-callback_function--)
  - [7.5. `getoptlong configure <CONFIG_PARAM=VALUE> ...`](#75-getoptlong-configure-config_paramvalue--)
  - [7.6. `getoptlong dump [-a|--all]`](#76-getoptlong-dump--a---all)
  - [7.7. `getoptlong help <SYNOPSIS>`](#77-getoptlong-help-synopsis)
- [8. Practical Examples](#8-practical-examples)
  - [8.1. Combining Required Options and Optional Arguments](#81-combining-required-options-and-optional-arguments)
  - [8.2. Script with Subcommands (Simple Version)](#82-script-with-subcommands-simple-version)
  - [8.3. Sample Scripts in `ex/` Directory](#83-sample-scripts-in-ex-directory)
- [9. Configuration Keys](#9-configuration-keys)
- [10. See Also](#10-see-also)

## 1. Introduction

`getoptlong.sh` is a Bash library designed for parsing command-line
options within shell scripts. It offers a robust and flexible
alternative to the built-in `getopts` command, providing support for
GNU-style long options, option permutation, various argument types
(required, optional, array, hash), data validation, callback
mechanisms, and automatic help message generation.  Its goal is to
simplify the often complex task of command-line argument processing in
Bash, making scripts more user-friendly and maintainable.

## 2. Basic Usage

Here are the basic steps to process command-line options in your
script using `getoptlong.sh`.

### 2.1. Sourcing the Library

First, source the `getoptlong.sh` file from within your script using
the `source` command (or the `.` command).

```bash
. /path/to/getoptlong.sh # Replace with the actual path to getoptlong.sh
# Or, if getoptlong.sh is in your execution path:
# . getoptlong.sh
```

### 2.2. Creating the Option Definition Array

Next, define the options your script will accept as a Bash associative
array.  The array name is arbitrary, but `OPTS` is commonly used by
convention.  For the format of each option key and the available
types, refer to Section "3. Detailed Option Definition".

```bash
declare -A OPTS=(
    [help      |h          # Display help message ]=
    [verbose   |v+         # Increase verbosity (cumulative) ]=0
    [output    |o:         # Specify output file ]=/dev/stdout
    [config    |c?         # Specify configuration file (optional) ]=
    [library   |L@         # Add library path ]=()
    [define    |D%         # Define a variable (e.g., key=val) ]=()
)
```

**Note:** The help option (`--help`, `-h`) is automatically added by
`getoptlong.sh` even if not explicitly defined. It will display the
help message and exit. This behavior can be customized with the `HELP`
setting (see Sections "7.1. `getoptlong init ...`" and "4. Help
Message Generation and Customization").  You can also define it
explicitly as shown in the example above.

### 2.3. Initializing getoptlong

Pass the defined option array to the `getoptlong init` command to
initialize the library.

```bash
getoptlong init OPTS
```

During initialization, you can also specify various configuration
parameters that control option parsing behavior. See Section
"7.1. `getoptlong init ...`" for details.

Example: Store non-option arguments in the `ARGS` array and prevent
the script from exiting on a parse error.

```bash
declare -a ARGS # It's good practice to declare the array specified by PERMUTE beforehand
getoptlong init OPTS PERMUTE=ARGS EXIT_ON_ERROR=0
```

### 2.4. Parsing Command-Line Arguments

Pass all script arguments (`"$@"`) to the `getoptlong parse` command
to parse them based on your definitions.

```bash
if ! getoptlong parse "$@"; then
    # Handle parse error (if EXIT_ON_ERROR=0)
    echo "Failed to parse arguments." >&2
    getoptlong help "Usage: $(basename "$0") [options] arguments..." # Display help on error
    exit 1
fi
```

`getoptlong parse` returns an exit code of `0` on successful parsing
and non-zero otherwise. If `EXIT_ON_ERROR` is `1` (default), the
script will automatically exit on a parse error.

### 2.5. Setting Parsed Results to Variables

After `getoptlong parse` succeeds, execute the output of the
`getoptlong set` command with `eval` to set the parsed option values
to corresponding shell variables.

```bash
eval "$(getoptlong set)"
```

This means, for example, if an option defined as `[output|o:]` in the
`OPTS` array was passed as `--output /tmp/out`, the shell variable
`$output` will be set to `/tmp/out`.

*   If a flag option (e.g., `[verbose|v]`) is specified, the
    corresponding variable (e.g., `$verbose`) will be set to `1`.

*   If a counter option (e.g., `[debug|d+]`) is specified, the
    variable value will be incremented for each occurrence.

*   Values for array options (e.g., `[library|L@]`) are stored in a
    Bash array (e.g., `"${library[@]}"`).

*   Values for hash options (e.g., `[define|D%]`) are stored in a Bash
    associative array (e.g., `declare -A define_vars="${define[@]}"`).

*   Hyphens (`-`) in option names are converted to underscores (`_`)
    in variable names (e.g., `--long-option` becomes `$long_option`).

### 2.6. Accessing and Using Variables

Use the variables set in the previous step in your script to perform
actions based on the options.

```bash
# If the help option was processed (automatically or manually),
# the script usually exits during 'getoptlong parse' or 'getoptlong set',
# but you can also check explicitly (e.g., for custom help processing).
if [[ -n "${help:-}" ]]; then
    # (Usually not reached if 'getoptlong help' was called)
    # Custom help display processing, etc.
    exit 0
fi

echo "Verbose output level: ${verbose:-0}" # Display 0 if not set

if [[ "$output" != "/dev/stdout" ]]; then
    echo "Output destination: $output"
fi

if [[ -n "${config:-}" ]]; then # Check if config is not an empty string or unset
    echo "Loading configuration file: $config..."
    # source "$config" or other processing
elif [[ -v config ]]; then # If config option was specified but has no value (set to empty string)
    echo "Configuration file specified, but path is missing."
else
    echo "Using default configuration."
fi

if (( ${#library[@]} > 0 )); then
    echo "Library paths:"
    for libpath in "${library[@]}"; do
        echo "  - $libpath"
    done
fi

if (( ${#define[@]} > 0 )); then
    echo "Defined variables:"
    for key in "${!define[@]}"; do
        echo "  - $key = ${define[$key]}"
    done
fi

# If PERMUTE=ARGS was specified in 'getoptlong init',
# non-option arguments are stored in the ARGS array.
# Ensure 'declare -a ARGS' was done beforehand.
if declare -p ARGS &>/dev/null && [[ "$(declare -p ARGS)" =~ "declare -a" ]]; then
    if (( ${#ARGS[@]} > 0 )); then
        echo "Remaining arguments (${#ARGS[@]}):"
        for arg in "${ARGS[@]}"; do
            echo "  - $arg"
        done
    fi
fi
```

## 3. Detailed Option Definition

Command-line options for `getoptlong.sh` are defined using a Bash
associative array. This section explains the detailed definition
method and available option types.

### 3.1. Basic Syntax

Options are defined as keys in an associative array. The key string
takes the following format:

`long_name|short_name <type_char>[<value_rule_char>][=<validation_type>]`

The value corresponding to this key specifies the initial value of the
option. Additionally, anything after a `#` in the key string is
treated as a comment and used as the description in the auto-generated
help message.

Example:

```bash
declare -A OPTS=(
    # LONG NAME   SHORT NAME
    # |           | TYPE CHAR
    # |           | | VALUE RULE CHAR
    # |           | | | VALIDATION TYPE
    # |           | | | |   DESCRIPTION                 INITIAL VALUE
    # |           | | | |   |                           |
    [verbose    |v          # Output verbose information  ]=
    [level      |l+         # Set log level (cumulative)  ]=0
    [output     |o:         # Specify output file         ]=/dev/stdout
    [mode       |m?         # Operation mode (optional)   ]=
    [include    |i@=s       # Include path (multiple ok)  ]=() # =s indicates string type (effectively no validation)
    [define     |D%         # Definition (KEY=VALUE)      ]=()
    [execute    |x!         # Execute command             ]=my_execute_function
    [count      |c:=i       # Number of iterations (int)  ]=1
    [ratio      |r:=f       # Ratio (float)               ]=0.5
    [id         |n:=(^[a-z0-9_]+$) # ID (alphanum & _)     ]=default_id
)
```

*   **long_name:** The long option name following `--` (e.g.,
    `verbose`). Can contain hyphens (e.g., `very-verbose`).

*   **short_name:** The short option name following `-` (e.g.,
    `v`). Usually a single character.

*   `long_name` and `short_name` are separated by `|` (pipe). You can
    define only one of them.

*   **type_char (Type Specifier):** Specifies if the option takes an
    argument, how it handles arguments, etc. See details below.

*   **value_rule_char (Value Rule Specifier):** (Currently only `+`,
    mainly for flags)

*   **validation_type (Validation Type):** Specifies the type for
    validating the argument's value. See details below. `=s` indicates
    a string but is effectively the same as no validation.

*   **description:** Text following `#`, used in the help message.

*   **INITIAL VALUE:** Specified after `=`, this becomes the default
    value if the option is not provided on the command line. Behavior
    varies by type if not specified.

After parsing, variables corresponding to the options are set in the
shell environment.  Variable names are usually based on `long_name`,
with hyphens (`-`) converted to underscores (`_`) (e.g.,
`--very-verbose` becomes `$very_verbose`).  If only `short_name` is
defined, `short_name` becomes the variable name. The `PREFIX` setting
can add a prefix to these variable names.

### 3.2. Option Types and Type Specifiers

#### 3.2.1. Flag Options (No Suffix or `+`)

Act as switches that do not take arguments.

*   **Definition Examples:**
    *   `[verbose|v # Verbose output]`
    *   `[debug|d+ # Debug level (cumulative)]`

*   **How to Specify:** `-v`, `--verbose`

*   **Variable Storage:**

    *   No suffix (`verbose`):
        *   Initial value: Empty string `""` if not specified.
        *   When option specified: Set to `1`.
        *   Multiple specifications: Remains `1`.
        *   Specifying with `no-` prefix (e.g., `--no-verbose`) resets
            the variable value to an empty string `""`.
    *   With `+` (`debug`): Acts as a counter.
        *   Initial value: `0` if not specified. Can also be set to a
            numeric initial value (e.g., `]=0`).
        *   When option specified: Variable value increments by `1`.
        *   Specifying with `no-` prefix (e.g., `--no-debug`) resets
            the variable value to `0` (if the initial value was
            numeric).

*   **Use Cases:** Toggling features ON/OFF, incrementally increasing verbosity.

#### 3.2.2. Required Argument Options (`:`)

Options that always require a value.

*   **Definition Example:** `[output|o: # Output file]`

*   **How to Specify Value:**
    *   Long option: `--output=value`, `--output value`
    *   Short option: `-ovalue`, `-o value`
    *   Note: The `-o=value` form is not supported for short options.

*   **Variable Storage:** The specified value is stored as a string in
    the variable (e.g., `$output`).

*   **Initial Value:** Results in an error if not specified, but an
    initial value can be set during definition (e.g.,
    `]=/dev/stdout`).

*   **Use Cases:** Specifying file paths, required parameters.

#### 3.2.3. Optional Argument Options (`?`)

Options that can take a value or be specified without one.

*   **Definition Example:** `[mode|m? # Operation mode]`

*   **How to Specify Value:**
    *   Long option:
        *   `--mode=value`: Variable `$mode` is set to `value`.
        *   `--mode`: Variable `$mode` is set to an empty string `""`.
    *   Short option:
        *   `-m`: Variable `$mode` is set to an empty string `""`.
        *   Note: Directly appending a value like `-mvalue` is not
            supported for short options. Use the long option if you
            need to specify a value.

*   **Variable Storage:**
    *   If a value is specified: That value is stored in the variable.
    *   If the option is specified without a value: An empty string
        `""` is stored in the variable.
    *   If the option is not specified: The variable remains unset (if
        no initial value was defined). Existence can be checked with
        `${variable+_}` or `[[ -v variable ]]`.

*   **Initial Value:** Can be set during definition (e.g., `]=default_mode`).

*   **Use Cases:** Optional configuration values, parameters valid
    only in certain cases.

#### 3.2.4. Array Options (`@`)

Accept multiple values as an array.

*   **Definition Example:** `[include|I@ # Include path]`

*   **How to Specify Values:**
    *   Specify the option multiple times:
        `--include /path/a --include /path/b`, `-I /path/a -I /path/b`
    *   Specify multiple values with a single option (delimiter
        controlled by `DELIM` setting; defaults to comma, space, tab):
        *   `--include /path/a,/path/b`
        *   `--include "/path/a /path/b"`
        *   `-I /path/a,/path/b`

*   **Variable Storage:** Specified values are stored in a Bash array
    (e.g., `"${include[@]}"`).

*   **Initial Value:** Usually an empty array. An initial value can be
    set during definition (e.g., `]=(/default/path1 /default/path2)`).

*   **Use Cases:** Multiple input files, multiple configuration items.

#### 3.2.5. Hash Options (`%`)

Accept `key=value` pairs as an associative array (hash).

*   **Definition Example:**
    `[define|D% # Macro definition (e.g., KEY=VALUE)]`

*   **How to Specify Values:**
    *   Specify the option multiple times: `--define OS=Linux --define
        VER=1.0`, `-D OS=Linux -D VER=1.0`
    *   Specify multiple pairs with a single option (delimiter
        controlled by `DELIM` setting; defaults to comma):
        *   `--define OS=Linux,VER=1.0`
        *   `-D OS=Linux,VER=1.0`
    *   If the value (`=VALUE`) is omitted, it's treated as if `=1`
        was specified (e.g., `--define DEBUG` is interpreted as
        `DEBUG=1`).

*   **Variable Storage:** Specified keys and values are stored in a
    Bash associative array (e.g., `declare -A
    define_map="${define[@]}"; echo "${define_map[OS]}"`).

*   **Initial Value:** Usually an empty associative array. An initial
    value can be set during definition (e.g., `]=([USER]=$(whoami))`).

*   **Use Cases:** Environment variable-like settings, information
    managed as key-value pairs.

#### 3.2.6. Callback Options (`!`)

When the option is parsed, the specified callback function is
called. This `!` specifier can be appended to any of the above option
types (`+`, `:`, `?`, `@`, `%`).

*   **Definition Examples:**
    *   `[execute|x! # Execute a command]` (flag type callback)
    *   `[config|c:! # Load a configuration file]` (required argument
        type callback)

*   **Behavior:**
    *   When the option is specified on the command line, the
        associated callback function is executed.
    *   By default, the callback function name is the same as the
        option's long name (hyphens converted to underscores). An
        arbitrary function name can be specified using the `getoptlong
        callback` command.
    *   For callback function invocation timing and arguments, see
        Section "7.4. `getoptlong callback ...`" and "5.1. Callback
        Function Details".

*   **Use Cases:** Executing custom actions during option parsing,
    complex value processing, immediate configuration changes.

### 3.3. Value Validation

There is a feature to validate the values of arguments passed to
options. Validation is specified by appending `=<validation_type>` to
the end of the option definition.

#### 3.3.1. Integer Validation (`=i`)

Validates if the argument is an integer.

*   **Definition Example:** `[count|c:=i # Number of iterations]`

*   **Behavior:** If the argument is not an integer, an error message
    is displayed, and the script exits (default behavior, if
    `EXIT_ON_ERROR=1`).

*   Applicable to array options (`@=i`) and the value part of hash
    options (`%=i`).

#### 3.3.2. Float Validation (`=f`)

Validates if the argument is a floating-point number.

*   **Definition Example:** `[ratio|r:=f # Ratio]`

*   **Behavior:** If the argument is not a floating-point number
    (e.g., `123.45` is OK, `1.2e-3` may not be supported), an error
    message is displayed, and the script exits.

*   Applicable to array options (`@=f`) and the value part of hash
    options (`%=f`).

#### 3.3.3. Custom Regex Validation (`=(<regex>)`)

Validates if the argument matches the specified Bash extended regular
expression (ERE). The regex is from the `(` immediately following `=`
to the corresponding final `)`.

*   **Definition Examples:**
    *   `[mode|m:=(^(fast|slow|debug)$)]` (one of fast, slow, debug)
    *   `[name|N@=(^[A-Za-z_]+$)]` (each element contains only letters
        and underscores)
    *   `[param|P%:=(^[a-z_]+=[0-9]+$)]` (key is lowercase letters and
        _, value is numbers)

*   **Behavior:** If the argument does not match the regex, an error
    message is displayed, and the script exits.

*   Applicable to array and hash options. For arrays, each element is
    validated. For hashes, each `key=value` pair as a whole is
    validated against the regex.

## 4. Help Message Generation and Customization

`getoptlong.sh` provides a powerful feature to automatically generate
help messages that show users how to use the script. This
significantly reduces the developer's effort in manually managing help
text. The generated help message displays options in alphabetical
order of their long names (or short names if long names don't exist).

### 4.1. Automatic Help Option

*   **`--help` and `-h`:**

    Even if you don't explicitly define options named `help` or `h` in
    the option definition array (`OPTS`), `getoptlong.sh`
    automatically recognizes `--help` (and `-h`). When these options
    are specified on the command line, the generated help message is
    displayed, and the script exits automatically.

*   **Customizing Default Help Option Definition (`HELP` Setting):**

    The definition (option name, description) of this automatically
    added help option can be customized using the `HELP` parameter
    during `getoptlong init` or with the `&HELP` key in the option
    definition array.

    *   **Specify with `getoptlong init`:**

        ```bash
        getoptlong init OPTS HELP="myhelp|H#Display custom help for this script"
        ```

        In this case, `--myhelp` or `-H` will function as the help option.

    *   **Specify in Option Definition Array (`&HELP`):**

        ```bash
        declare -A OPTS=(
            [&HELP]="show-usage|u#Usage guide"
            # ... other option definitions ...
        )
        getoptlong init OPTS
        ```

        In this case, `--show-usage` or `-u` becomes the help
        option. The `&HELP` specification in the array takes
        precedence over the `HELP` parameter at `init`.

    *   The default if `HELP` or `&HELP` is not specified is
        `help|h#show help`.

### 4.2. Help Message Content

#### 4.2.1. Option Descriptions (Comments `#`)

The description for each option displayed in the help message is
written after a `#` at the end of the key string for each option
definition in the option definition array.

```bash
declare -A OPTS=(
    [output|o:   # Specify the output file path. ]=/dev/stdout
    [verbose|v+  # Enable verbose logging (multiple increases level). ]=0
)
```

Defined as above, the help message will display something like (order
depends on sorting by option name):

```
  -o, --output <value>     Specify the output file path. (default: /dev/stdout)
  -v, --verbose            Enable verbose logging (multiple increases level). (default: 0)
```

#### 4.2.2. Type-Based Automatic Messages

If no description is provided via `#` in the option definition,
`getoptlong.sh` will auto-generate a basic description based on the
option's type information (whether it takes an argument, argument
type, etc.).

For example:

*   `[input|i:]` (no description) → `  -i, --input <value>        Requires an argument.`

*   `[force|f]` (no description) → `  -f, --force                Flag option.`

Using long, descriptive long option names (e.g., `--backup-location`)
improves the readability of auto-generated messages.

#### 4.2.3. Displaying Initial (Default) Values

If an initial value is specified during option definition (e.g.,
`[count|c:=i]=1`), that default value is displayed in the help message
like `(default: <value>)`.

```bash
declare -A OPTS=(
    [mode|m?     # Specify operation mode (fast, normal, slow) ]=normal
    [retries|r:=i # Maximum number of retries ]=3
)
```

Example help message display:

```
  -m, --mode [<value>]     Specify operation mode (fast, normal, slow) (default: normal)
  -r, --retries <value>    Maximum number of retries (default: 3)
```

#### 4.2.4. Treating Flag Options as Counters

If a numeric initial value is specified for a flag option (no type
suffix, or `+`) (e.g., `[debug|d+]=0`), that option is treated as a
counter.  The help message will also display this initial value.

### 4.3. Overall Help Message Format

#### 4.3.1. Customizing Synopsis (`USAGE` Setting)

The script usage line (Synopsis) displayed at the beginning of the
help message can be customized with the `USAGE` parameter.

*   **Specify with `getoptlong init`:**

    ```bash
    getoptlong init OPTS USAGE="Usage: myscript [options] <input_file> <output_file>"
    ```

*   **Specify in Option Definition Array (`&USAGE`):**

    ```bash
    declare -A OPTS=(
        [&USAGE]="Usage: $(basename "$0") [OPTIONS] SOURCE DEST"
        # ... other option definitions ...
    )
    getoptlong init OPTS
    ```

    The `&USAGE` specification in the array takes precedence over the
    `USAGE` parameter at `init`.

*   If `USAGE` is not specified, the Synopsis line is not displayed by
    default (unless an argument is passed to the `getoptlong help`
    command).

#### 4.3.2. Manual Display with `getoptlong help`

You can manually display the help message from anywhere in your script
by executing the `getoptlong help` command.

```bash
if [[ "$1" == "--show-manual" ]]; then
    getoptlong help "This is the detailed manual for $(basename "$0")."
    exit 0
fi
```

If you pass an argument to `getoptlong help`, that string will be used
as the first line (Synopsis) of the help message. This takes
precedence over `USAGE` or `&USAGE` settings. If no argument is
passed, the `USAGE` (or `&USAGE`) setting is used, and if that's also
absent, the option list is displayed without a Synopsis.

### 4.4. Help Message Structure

The generated help message generally has the following structure:

1.  **Synopsis Line:** (If specified by `USAGE` setting or `getoptlong help` argument)

2.  **Options List:**

    *   Each option is displayed with its short option (if any), long
        option (if any), argument placeholder (e.g., `<value>`), and
        description.

    *   Options are sorted alphabetically by their long name. If no
        long name, sorted by short name.

    *   The description may include the initial value (`(default:
        ...)`).

```
(Synopsis line, e.g., Usage: myscript [options] <file>)

Options:
  -h, --help                 Show this help message and exit.
  -f, --file <path>          Specify the input file. (default: input.txt)
      --force                Force operation without confirmation.
  -n, --count <number>       Number of times to operate. (integer, default: 1)
  -v, --verbose              Enable verbose output. (counter, default: 0)
      --version              Show version information.
```

(The above is just a general example of a help message. The actual
display will vary based on option definitions and settings.)

## 5. Advanced Topics

This section covers more advanced uses and convenient features of
`getoptlong.sh`.

### 5.1. Callback Function Details

Callback functions allow you to execute arbitrary shell functions when
specific options are parsed. This enables complex processing beyond
simple value setting to be integrated into option parsing.  Callback
functions are registered by adding a `!` suffix in the option
definition or by using the `getoptlong callback` command.

#### 5.1.1. Normal Callbacks (Post-processing)

By default, callback functions are called **after** the option's value
has been internally set.

*   **Call Format:** `callback_function "option_name" "option_value"
    [registered_arg1 registered_arg2 ...]`

    *   `$1`: The long name of the option (e.g., `my-option`).

    *   `$2`: The parsed value of the option. For flags, it's `1` (or
        an empty string if specified with `no-`). For options taking
        arguments, it's the argument value. For arrays or hashes, it's
        the last parsed element or pair.

    *   `$3...`: If additional arguments were specified during
        registration with `getoptlong callback <opt_name> <func_name>
        arg1 arg2...`, they are passed here.

*   **Example:**

    ```bash
    declare -A OPTS=(
        [process-item|p:! # Process an item]=
    )

    process_item_callback() {
        local opt_name="$1"
        local item_id="$2"
        echo "Callback: Option '$opt_name' was specified with value '$item_id'."
        # Perform processing using item_id here
        if [[ ! -f "$item_id" ]]; then
            echo "Error: File '$item_id' not found." >&2
            # exit 1 # Exit with error if necessary
        fi
    }
    # getoptlong callback process-item process_item_callback # Registered by default, but can be explicit
    # getoptlong callback process-item process_item_callback "Additional arg 1" # Can also pass extra args

    getoptlong init OPTS
    getoptlong parse "$@" && eval "$(getoptlong set)"
    ```

#### 5.1.2. Pre-processing Callbacks (`--before` / `-b`) (Newer Feature)

By specifying the `--before` (or `-b`) option with the `getoptlong
callback` command, you can call the callback function **before** the
option's value is internally set. This is a relatively new feature in
`getoptlong.sh`.

*   **Call Format:** `callback_function "option_name" [registered_arg1 registered_arg2 ...]`

    *   `$1`: The long name of the option.

    *   `$2...`: If additional arguments were specified during
        registration with `getoptlong callback -b <opt_name>
        <func_name> arg1 arg2...`, they are passed here.

    *   **Note:** The option's value is not passed to pre-processing
        callbacks. They are not intended for value processing but are
        suitable for state changes or preparation before the value is
        set.

*   **Use Cases:**

    *   Clearing the values of an array option before processing.

    *   Dynamically changing other default values when a specific
        option is specified.

    *   State initialization.

*   **Example: Pre-clearing an Array Option**

    ```bash
    declare -A OPTS=(
        [append-list|a@ # Append to list (can be cleared each time) ]=()
    )

    clear_append_list() {
        echo "Callback (--before): Clearing append_list (${append_list[*]})"
        append_list=() # Directly manipulate the global variable
    }
    # Call clear_append_list just before the append-list option is parsed
    getoptlong callback --before append-list clear_append_list

    getoptlong init OPTS
    # Example: ./myscript.sh --append-list x --append-list y
    # clear_append_list is called twice, and append_list will only contain "y" in the end.
    # Without --before, it would contain "x" "y".
    getoptlong parse "$@" && eval "$(getoptlong set)"

    echo "Final append_list: ${append_list[*]}"
    ```

#### 5.1.3. Error Handling in Callback Functions

If an error occurs within a callback function, it's common to output a
message to standard error and `exit` with a non-zero status. This
allows integration with `getoptlong.sh`'s error handling mechanisms
(e.g., `EXIT_ON_ERROR`).

#### 5.1.4. Custom Validation using Callbacks

Complex validation that cannot be handled by the option definition's
validation features (`=i`, `=f`, `=(regex)`) can be implemented using
callback functions. Typically, a normal (post-processing) callback
receives the value and executes the validation logic.

### 5.2. Specifying Destination (Newer Feature)

Normally, parsed option values are stored in variables automatically
determined based on the option's long name (or short name). The
`DESTINATION` setting (a relatively new feature) allows you to store
these values in a specified associative array.

*   **How to Set:** `getoptlong init OPTS DESTINATION=<array_name>`

    *   `<array_name>` specifies the name of the associative array to
        store values in. This array must be declared beforehand with
        `declare -A <array_name>`.

*   **Behavior:**

    *   When an option `--option value` is parsed, instead of a
        variable `$option`, the value is stored in
        `<array_name>[option]`.

    *   Hyphens in option names are not converted to underscores; the
        original option name becomes the key (e.g., `--my-option`
        results in `<array_name>[my-option]`).

    *   Works similarly for all option types, including flags,
        counters, arrays, and hashes.

    *   **Important:** For array and hash type options,
        `<array_name>[option_name]` might store the **name of the
        global variable holding the actual array/hash as a string**,
        or the array/hash might be **stored as a serialized
        string**. This depends on the specific implementation of
        `getoptlong.sh`. When accessing, check the output of
        `getoptlong dump -a` or `getoptlong set`, and dereference or
        deserialize appropriately. Direct access like
        `${<array_name>[option_name][index]}` might not work.

*   **Example:**

    ```bash
    declare -A MyVars
    declare -A OPTS=(
        [user-name|u: # User name]=
        [enable-feature|f # Enable feature]=
        [ids|i@=i # ID list]=()
    )

    getoptlong init OPTS DESTINATION=MyVars
    getoptlong parse --user-name "jules" --enable-feature --ids 10 --ids 20
    eval "$(getoptlong set)" # This is still needed to populate MyVars correctly for complex types

    echo "User name: ${MyVars[user-name]}"
    echo "Feature enabled: ${MyVars[enable-feature]}" # Stores "1"

    # Check the content of MyVars[ids] (e.g., with getoptlong dump -a)
    # Example: If MyVars[ids] stores a string like "MyVars_ids_array"
    # and the actual array is in $MyVars_ids_array:
    # declare -n ids_ref="${MyVars[ids]}"
    # echo "ID list: ${ids_ref[@]}"
    # Otherwise, processing depends on the content of MyVars[ids].
    # A more robust way after `eval "$(getoptlong set)"` if MyVars[ids] is set to the name of the array
    # is to use that name directly if it follows a predictable pattern, or inspect `getoptlong set` output.

    # Assuming 'eval "$(getoptlong set)"' populates 'MyVars_ids' or similar based on DESTINATION
    # For array options, 'getoptlong set' when DESTINATION is used might create
    # a variable like <DESTINATION_ARRAY_NAME>_<OPTION_NAME>
    # and MyVars[ids] might store the name of this actual array variable.
    # Let's assume 'getoptlong set' creates 'MyVars_ids' array.
    if declare -p MyVars_ids &>/dev/null; then
        echo "ID list: ${MyVars_ids[@]}"
    elif [[ -v MyVars[ids] ]]; then
        # If MyVars[ids] itself contains the serialized array (less common for `getoptlong set`)
        echo "ID list (from MyVars[ids]): ${MyVars[ids]}"
        echo "Note: This might be a serialized value or an indirect name."
    fi
    ```

*   **Use Cases:**

    *   Preventing pollution of global shell variables by collecting
        option-derived variables into a specific namespace
        (associative array).

    *   Making it easier to distinguish results when using multiple
        `getoptlong` instances.

### 5.3. Option Pass-through

Sometimes you want to pass some of the options received by your script
directly to another internal or external command. `getoptlong.sh` offers
two main ways to achieve this: general argument pass-through and specific
option collection.

#### 5.3.1. General Argument Pass-through (using `PERMUTE` and `--`)

This method is suitable when you want to pass all arguments after a certain
point, or all non-option arguments, to another command.

*   **`PERMUTE` and `--` (Double Dash):**

    *   Setting `PERMUTE` like `getoptlong init OPTS PERMUTE=RESTARGS`
        causes arguments not interpreted as options (non-option
        arguments) to be stored in the specified array (`RESTARGS`) in
        order.

    *   When `--` (double dash) appears in the command-line arguments,
        all subsequent arguments are not interpreted as options and
        are stored directly in the array specified by `PERMUTE` (or
        the default `GOL_ARGV`). This is the standard way to pass
        options to subsequent commands.

*   **Handling Undefined Options:**

    *   By default, if an option not defined in the `OPTS` array is
        passed, it results in an error (if `EXIT_ON_ERROR=1`).

    *   By setting `EXIT_ON_ERROR=0` and checking the return value of
        `getoptlong parse`, you can process an argument list
        containing undefined options. `getoptlong.sh` does not have a
        direct feature to "ignore undefined options and collect them
        into a specific array." In this case, you need to use
        `PERMUTE` and `--`, or preprocess the argument list yourself.

*   **How to Achieve Pass-through (General Approaches):**

    1.  **Using `--`:** Instruct users of your script to place `--`
        before the options they want to pass to the downstream
        command.

        ```bash
        # ./myscript.sh --my-opt val -- --downstream-opt --another val
        declare -a PassThroughArgs
        getoptlong init OPTS PERMUTE=PassThroughArgs
        getoptlong parse "$@" && eval "$(getoptlong set)"
        # PassThroughArgs will contain "--downstream-opt" "--another" "val" (when using PERMUTE)
        # other_command "${PassThroughArgs[@]}"
        ```

    2.  **Usage as a Wrapper Script and Manual Splitting:** If your
        script is a wrapper for a specific command, process its own
        options, then pass the remaining or transformed arguments to
        that command. Using `--` for explicit separation is robust.
        (Example code omitted for brevity, see previous version if needed)

#### 5.3.2. Specific Option Collection (using `-` in Option Definition)

This method allows you to collect specific options, along with their potential
values, into a designated array as they are parsed. This is useful when you
want to gather certain options for later processing or to pass them selectively
to another function or command.

To use this feature, append a hyphen (`-`) to the option type specifier in your
option definition.

*   **Basic Usage:**

    When an option is defined with a trailing `-`, the option itself (e.g.,
    `--option-name` or `-o`) and its value (if it takes one) are added as
    consecutive elements to a specified array.

    ```bash
    declare -A OPTS=(
        [collect-this|c:-:my_collection_array # Collect this option and its value]=
        [another-opt|a-:my_collection_array  # Collect this one too, into the same array]=
        [flag-collect|f-:flag_array          # Collect this flag]=
    )
    declare -a my_collection_array=()
    declare -a flag_array=()

    getoptlong init OPTS
    # Example: ./myscript.sh --collect-this foo -a bar --flag-collect
    # After parsing:
    # my_collection_array would contain: ("--collect-this" "foo" "-a" "bar")
    # flag_array would contain: ("--flag-collect")
    ```

*   **Destination Array:**

    *   The array where options are collected is determined by the string
        following the `-` (and other type specifiers like `!` or `:`).
        For example, in `[myopt|m:-:destination_array]`, options will be
        collected into the `destination_array`.
    *   If no array name is specified after the `-` (e.g., `[myopt|m:-]`),
        the options are collected into an array named after the option's
        long name, with hyphens converted to underscores (e.g., `myopt`
        would collect into `myopt` array, or if defined as `my-opt`,
        it would collect into `my_opt` array). Ensure this array is
        declared (e.g., `declare -a my_opt`).

*   **Combining with Other Types:**

    The `-` specifier can be combined with other type specifiers, such as
    `:` (required argument) or `!` (callback).

    *   `[myopt|m:-!:log_array # Log this option then collect it]`
        In this case, the callback associated with `myopt` would execute first,
        and then `--myopt` (and its value, if any, based on other type
        specifiers) would be added to `log_array`.
    *   `[param|p::my_params # Collect parameter and its required value]`
        If parsed as `--param value`, `my_params` would get `("--param" "value")`.

*   **Help Message:**

    Options defined with the `-` pass-through specifier will be described
    in the help message typically as "passthrough to ARRAY_NAME", where
    `ARRAY_NAME` is the name of the collection array in uppercase.

This specific option collection provides a flexible way to gather arguments
that might not be directly used by the script's main logic but are important
for other parts of the process or for passing to sub-commands.

### 5.4. Runtime Configuration Changes (`getoptlong configure`)

Some parameters set with `getoptlong init` can be changed later using
the `getoptlong configure` command.

*   **Command:** `getoptlong configure <CONFIG_PARAM=VALUE> ...`

*   **Example:**

    ```bash
    getoptlong init OPTS EXIT_ON_ERROR=1
    # ... some processing ...
    # Temporarily prevent exiting on error
    getoptlong configure EXIT_ON_ERROR=0
    # The following parse will not exit on error (check return value of parse for success)
    if ! getoptlong parse "${some_args[@]}"; then
        echo "Warning: Parsing some_args failed but script continues." >&2
    fi
    # Revert
    getoptlong configure EXIT_ON_ERROR=1
    ```

*   **Note:** Not all parameters are suitable for runtime
    changes. It's safest to use this for changing flags that control
    parsing behavior (`EXIT_ON_ERROR`, `SILENT`, `DEBUG`,
    `DELIM`). Parameters like `PREFIX` or those affecting option
    definitions themselves might not work as expected if changed after
    `init`.

### 5.5. Dumping Internal State (`getoptlong dump`)

For debugging purposes, you may want to inspect the option definition
information and current values held internally by `getoptlong.sh`. Use
the `getoptlong dump` command.

*   **Command:**

    *   `getoptlong dump`: Displays parsed option names, corresponding
        shell variable names, and their current values.

    *   `getoptlong dump -a` or `getoptlong dump --all`: Displays all
        internal management parameters and more detailed option
        information.

*   **Example:**

    ```bash
    declare -A OPTS=([file|f:]=foobar.txt [verbose|v+]=0)
    getoptlong init OPTS
    getoptlong parse --verbose --file new.txt -v

    # Display status of variables $file and $verbose, etc.
    getoptlong dump >&2
    # Example output (format depends on actual implementation):
    # file (file) = 'new.txt'
    # verbose (verbose) = '2'

    eval "$(getoptlong set)"
    echo "File is: $file, Verbose level is: $verbose"
    ```

*   **Use Cases:**
    *   Verifying if options are parsed correctly.
    *   Debugging if variables are set as expected.
    *   Checking the current option state within callback functions.

## 6. Standalone Usage

While `getoptlong.sh` is primarily used as a library by `source`-ing
it, there's a possibility of limited standalone command functionality
being provided in the future (specific implementation of this feature
does not exist at this time).

If `getoptlong.sh` were to offer any functionality as an external
command (e.g., version display, simple parse testing), its usage would
be described in this section.

**Current Primary Usage:**

Call library functions within a script via `source getoptlong.sh`,
following the steps of option definition, initialization, parsing, and
variable setting.

## 7. Command Reference

This section describes the main commands (functions) provided by
`getoptlong.sh`.

### 7.1. `getoptlong init <opts_array_name> [CONFIGURATIONS...]`

Initializes the library, loading option definitions and settings. This
command must be executed before calling `getoptlong parse`.

*   **`<opts_array_name>`**: (Required) Specifies the name of the Bash
    associative array containing option definitions (e.g., `OPTS`).

*   **`[CONFIGURATIONS...]`**: Optional configuration parameters
    specified in `KEY=VALUE` format. Key settings include:

    *   **`PERMUTE=<array_name>`**:

        Specifies the name of a Bash regular array to store arguments
        not interpreted as options (non-option arguments).  For
        example, with `PERMUTE=REMAINING_ARGS`, in `myscript --opt
        arg1 arg2`, `arg1` and `arg2` would be stored in the
        `REMAINING_ARGS` array.  If not specified or an empty string
        is provided, parsing stops at the first non-option argument
        (behavior similar to `POSIXLY_CORRECT`).  Default is
        `GOL_ARGV` (an internal library array name, usually not
        user-facing).

    *   **`PREFIX=<string>`**:

        Specifies a prefix to be added to variable names set by
        `getoptlong set`. For example, with `PREFIX=MYAPP_` and an
        option `--option`, the variable `$MYAPP_option` would be set.
        Default is an empty string (no prefix).

    *   **`DESTINATION=<array_name>` (Newer Feature)**:

        Stores parsed option values in the specified associative array
        `<array_name>`. Keys are the long names of options (or short
        names if defined, with long names taking precedence).  For
        example, with `DESTINATION=OptValues` and option `--my-opt
        val`, `OptValues[my-opt]="val"` would be stored.  The `PREFIX`
        setting does not apply to the keys in this `DESTINATION`
        array.  For specific storage methods and access for array/hash
        type options, refer to Section "5.2. Specifying Destination".
        This array must be declared beforehand with `declare -A
        <array_name>`.

    *   **`HELP=<SPEC>`**:

        Specifies the definition for the automatically added help
        option. `<SPEC>` follows the same format as keys in the option
        definition array (e.g., `myhelp|H#Custom help`).  Default is
        `help|h#show help`.

    *   **`EXIT_ON_ERROR=<BOOL>`**:

        Whether to exit the script on a parse error (`1` to exit, `0`
        not to exit).  Default is `1` (exit). If `0`, you must check
        the return value of `getoptlong parse` to detect errors.

    *   **`DELIM=<string>`**:

        Specifies the set of characters used to delimit multiple
        values or pairs within a single argument string for array
        (`@`) or hash (`%`) options.  Default is space, tab, comma
        (behavior similar to Bash's IFS). For example, `DELIM=,:`
        would delimit by comma and colon.

    *   **`SILENT=<BOOL>`**:

        Whether to suppress error messages (`1` to suppress, `0` to display).
        Default is `0` (display).

    *   **`DEBUG=<BOOL>`**:

        Whether to enable debug messages (`1` to enable, `0` to disable).
        Default is `0` (disable).

### 7.2. `getoptlong parse "$@"`

Parses command-line arguments according to the defined options.

*   **`"$@"`**: (Required) Pass all arguments passed to the script,
    exactly as received. It's important to enclose it in double
    quotes.

*   **Return Value**:

    *   Returns exit code `0` on successful parsing.
    *   Returns a non-zero exit code on parsing failure (undefined
        option, missing required argument, etc.).
    *   If `EXIT_ON_ERROR=1` (default), this command will cause the
        script to exit on a parse error, so checking the return value
        is usually unnecessary.
    *   If `EXIT_ON_ERROR=0`, you must check the return value of this
        command to handle errors.

### 7.3. `getoptlong set`

Generates a series of `eval`-able shell command strings to standard
output, which set corresponding shell variables based on parsed option
values.

*   Typically used as `eval "$(getoptlong set)"`. This sets variables
    corresponding to options in the current shell environment.  (e.g.,
    `--file /tmp/f` → `file="/tmp/f"`)

### 7.4. `getoptlong callback [-b|--before] <opt_name> [callback_function] ...`

Registers a callback function for a specified option or modifies the
settings of an already registered callback.

*   **`-b` or `--before` (Newer Feature)**:

    If this flag is specified, the callback function is called
    **before** the option's value is internally set.  The option's
    value is not passed to pre-processing callbacks. See Section
    "5.1.2. Pre-processing Callbacks" for details.

*   **`<opt_name>`**: (Required) The long name of the option to
    register the callback for (e.g., `my-option`).

*   **`[callback_function]`**:

    The name of the shell function to call.  If omitted or if `-` is
    specified, a function name is automatically generated from
    `<opt_name>` (hyphens `-` converted to underscores `_`, e.g.,
    `my_option`) and becomes the default callback function name.  If
    the `!` suffix was used in the option definition, the callback is
    automatically registered with this default name.

*   **`[...]`**: (Optional) Additional fixed arguments to be passed to
    the callback function. These arguments are passed after the option
    name and option value (for normal callbacks) when the callback
    function is invoked.

### 7.5. `getoptlong configure <CONFIG_PARAM=VALUE> ...`

Dynamically changes global configuration parameter values (set by
`getoptlong init`) during parsing or at other points.

*   **`<CONFIG_PARAM=VALUE>`**: (Required) Specifies a configuration
    parameter available in `getoptlong init` and its new value (e.g.,
    `EXIT_ON_ERROR=0`).

*   **Note**: Not all parameters are suitable for runtime
    modification. It's safest to change flags controlling parsing
    behavior (`EXIT_ON_ERROR`, `SILENT`, `DEBUG`, `DELIM`). Parameters
    like `PREFIX` or those related to option definitions themselves
    might not work as expected if changed after `init`.

### 7.6. `getoptlong dump [-a|--all]`

Dumps (displays) the internal state of `getoptlong.sh` (option
definitions, current values, settings, etc.) to standard error
output. Primarily used for debugging.

*   **`-a` or `--all`**:

    If specified, displays more detailed internal information
    (including management parameters). If not specified, primarily
    shows parsed option names, corresponding shell variable names, and
    current values.

### 7.7. `getoptlong help <SYNOPSIS>`

Generates and displays a formatted help message based on the defined
options to standard output.

*   **`<SYNOPSIS>`**: (Optional) A string indicating the script's
    usage, displayed at the beginning of the help message.  The string
    specified here takes precedence over `USAGE` or `&USAGE` settings.
    If omitted, the `USAGE` (or `&USAGE`) setting is used if present;
    otherwise, the option list is displayed without a Synopsis line.

*   This command is executed internally when automatic help options
    (`--help`, `-h`) are invoked.

## 8. Practical Examples

Previous sections have explained individual features of
`getoptlong.sh`.  This section shows some practical examples and usage
in more complex scenarios.  Also, refer to the `ex/` directory for
more sample scripts.

### 8.1. Combining Required Options and Optional Arguments

```bash
#!/usr/bin/env bash

# Assume getoptlong.sh is in PATH or current directory
if ! . getoptlong.sh; then echo "Error: getoptlong.sh not found." >&2; exit 1; fi

# Option definitions
declare -A OPTS=(
    [input|i:    # Specify input file (required) ]=
    [output|o:   # Specify output file (required) ]=
    [format|f?   # Output format (optional, expects value if given) ]= # Using without value is discouraged
    [compress|c  # Compress output (flag) ]=
    [level|l:=i  # Compression level (integer, only if compress is used) ]=1
    [verbose|v+  # Verbosity level ]=0
    [&USAGE]="Usage: $(basename "$0") -i <input> -o <output> [-f <format>] [-c [-l <level>]] [-v]"
    [&HELP]="process-data|H#Help for the data processing script"
)

# Callback function (e.g., uppercase the format if specified)
# Since '!' is not on the format option, register with getoptlong callback
format_callback() {
    local opt_name="$1"
    local val="$2"
    if [[ -n "$val" ]]; then
        format="${val^^}" # Directly modify the global 'format' variable
        (( verbose > 0 )) && echo "Debug: Format set to '$format' via callback." >&2
    else
        echo "Warning: Format option used without a value." >&2
    fi
}
getoptlong callback format format_callback

# Initialize getoptlong
getoptlong init OPTS

# Parse arguments
if ! getoptlong parse "$@"; then
    exit 1
fi
eval "$(getoptlong set)"

# Check for required options
if [[ -z "$input" ]] || [[ -z "$output" ]]; then
    echo "Error: Input file (-i) and output file (-o) are required." >&2
    getoptlong help # Display help on error
    exit 1
fi

# Main processing
echo "Input file: $input"
echo "Output file: $output"

if [[ -v format ]]; then # If format option was used (with value or empty string)
    if [[ -n "$format" ]]; then
        echo "Output format: $format"
    else
        echo "Output format: (not specified)" # Case of --format only
    fi
fi

if [[ -n "$compress" ]]; then
    echo "Compression: Enabled (Level: $level)"
    # Compression processing...
else
    echo "Compression: Disabled"
fi

echo "Verbosity level: $verbose"

# ...actual processing...
echo "Processing complete."
```

**Key points in this example:**

*   Checking for required options (`input`, `output`).

*   Handling optional arguments (`format`) and value processing via callback.

*   Combining a flag option (`compress`) with another related option (`level`).

*   Customizing the help message using `&USAGE` and `&HELP`.

### 8.2. Script with Subcommands (Simple Version)

`getoptlong.sh` can call `init` and `parse` multiple times. This can
be used to define and process different option sets for subcommands.

```bash
#!/bin/bash
if ! . getoptlong.sh; then echo "Error: getoptlong.sh not found." >&2; exit 1; fi

# Global options
declare -A GlobalOPTS=(
    [verbose|v+ # Verbose output ]=0
    [help|h     # Display help ]=
)
getoptlong init GlobalOPTS
declare -a RemainingArgs
# Parse only global options. Do not exit on error, store the rest in RemainingArgs.
getoptlong configure EXIT_ON_ERROR=0 PERMUTE=RemainingArgs
getoptlong parse "$@"
eval "$(getoptlong set)" # Set variables for global options

# If global help requested or no subcommand, show overall help
if [[ -n "$help" ]] || (( ${#RemainingArgs[@]} == 0 )); then
    echo "Usage: $(basename "$0") [global_options] <subcommand> [subcommand_options]"
    echo ""
    echo "Global Options:"
    getoptlong help # Help for GlobalOPTS
    echo ""
    echo "Subcommands:"
    echo "  commit    Record changes to the repository"
    echo "  push      Update remote refs along with associated objects"
    exit 0
fi

subcommand="${RemainingArgs[0]}"
# Subcommand arguments are RemainingArgs excluding the subcommand itself
SubcommandArgs=("${RemainingArgs[@]:1}")

case "$subcommand" in
    commit)
        declare -A CommitOPTS=(
            [message|m: # Commit message ]=
            [all|a      # Stage all changes ]=
            [help|h     # Help for commit subcommand ]= # Per-subcommand help
        )
        getoptlong init CommitOPTS # Re-initialize with new option set
        # Parse only subcommand arguments
        if ! getoptlong parse "${SubcommandArgs[@]}"; then exit 1; fi
        eval "$(getoptlong set)" # Set variables for commit

        if [[ -n "$help" ]]; then # Subcommand help
             getoptlong help "Usage: $(basename "$0") commit [options]"
             exit 0
        fi

        echo "Subcommand: commit"
        [[ -n "$message" ]] && echo "  Message: $message"
        [[ -n "$all" ]] && echo "  All: enabled"
        (( verbose > 0 )) && echo "  Verbose (global): $verbose"
        # e.g., execute git commit
        ;;
    push)
        declare -A PushOPTS=(
            [remote|r:  # Remote repository ]=origin
            [force|f   # Force push       ]=
            [help|h    # Help for push subcommand ]=
        )
        getoptlong init PushOPTS
        if ! getoptlong parse "${SubcommandArgs[@]}"; then exit 1; fi
        eval "$(getoptlong set)"

        if [[ -n "$help" ]]; then
             getoptlong help "Usage: $(basename "$0") push [options]"
             exit 0
        fi

        echo "Subcommand: push"
        echo "  Remote: ${remote}"
        [[ -n "$force" ]] && echo "  Force: enabled"
        (( verbose > 0 )) && echo "  Verbose (global): $verbose"
        # e.g., execute git push
        ;;
    *)
        echo "Error: Unknown subcommand '$subcommand'" >&2
        getoptlong init GlobalOPTS # Revert to GlobalOPTS for help display
        getoptlong help "Usage: $(basename "$0") [global_options] <subcommand> [subcommand_options]"
        exit 1
        ;;
esac
```

**Key points in this example:**

*   Separation of global options and subcommand-specific options.

*   Calling `getoptlong init` and `parse` multiple times.

*   Using `PERMUTE` to separate the subcommand and its arguments.

*   Consideration for per-subcommand help display (defining `help|h`
    in each OPTS).

*   **Note:** This example illustrates the basic idea. Real subcommand
    processing needs to consider more edge cases and error handling. A
    more detailed example can be found in `ex/subcmd.sh`.

### 8.3. Sample Scripts in `ex/` Directory

The `getoptlong.sh` repository includes sample scripts in the `ex/`
directory that demonstrate various features. These are very helpful
for learning more specific use cases and advanced techniques.

*   **`ex/repeat.sh`**: Shows basic usage of various option types
    (array, hash, incremental flags, etc.).

*   **`ex/prefix.sh`**: Example of `PREFIX` setting usage.

*   **`ex/cmap`**: A colorizing mapper. Good example of complex option
    parsing, callbacks, and data processing.

*   **`ex/cmap-prefix`**: `cmap` example with `PREFIX` applied.

*   **`ex/md`**: Sample Markdown parser.

*   **`ex/silent.sh`**: Example of `SILENT` setting usage.

*   **`ex/subcmd.sh`**: A more sophisticated example of a script with
    subcommands, including handling of global and local options, and
    shared help.

It's recommended to try running these samples and reading their code.

## 9. Configuration Keys

Within the option definition array (`OPTS`), you can use special keys
in the format `&KEY=VALUE` to configure the behavior of
`getoptlong.sh`, separate from regular option definitions.  These
settings take precedence over identically named settings specified as
arguments to the `getoptlong init` command.

*   **`&HELP=<SPEC>`**

    *   Description: Customizes the definition of the auto-generated
        help option. `<SPEC>` has the same format as a normal option
        definition (e.g., `myhelp|H#Custom help`).

    *   Default: `help|h#show help`

    *   Reference: Section "4.1. Automatic Help Option"

*   **`&USAGE=<string>`**

    *   Description: Specifies the usage (Synopsis) string to be
        displayed at the beginning of the help message.

    *   Default: Not specified (Synopsis is not displayed)

    *   Reference: Section "4.3.1. Customizing Synopsis (`USAGE`
        Setting)"

*   **Other Configuration Keys:**

    *   The current documentation does not explicitly mention other
        `&KEY` format settings, but depending on the library version,
        other settings (e.g., `&DELIM`, `&PREFIX`) might be
        supported. For accurate information, please check the
        documentation or source code corresponding to the version of
        `getoptlong.sh` you are using.

## 10. See Also

Other tools with similar purposes to `getoptlong.sh`, and related resources.

-   **GNU `getopt`**: C ライブラリの `getopt_long` 関数のコマンドラインユーティリティ版。複雑なオプションのパースに使われますが、シェルスクリプトでの利用は一手間必要な場合があります。
-   **Bash `getopts`**: Bash の組み込みコマンド。POSIX スタイルのショートオプションのみをサポートし、ロングオプションやオプションの自由な順序（permutation）には対応していません。
-   **Perl `Getopt::Long`**: Perl で非常に広く使われているコマンドラインオプション解析モジュール。`getoptlong.sh` はこのモジュールに影響を受けている部分があります。
-   **Python `argparse`**: Python の標準ライブラリで、コマンドライン引数をパースするための強力なモジュールです。
-   [`getoptions` (ko1nksm/getoptions)](https://github.com/ko1nksm/getoptions): Another powerful option parser for shell scripts, which inspired some features in `getoptlong.sh`.
-   [`argh` (adrienverge/argh)](https://github.com/adrienverge/argh): A minimalist argument handler for bash.

[end of README.md]
