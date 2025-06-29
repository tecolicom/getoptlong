# getoptlong.sh

`getoptlong.sh` is a Bash library for parsing command-line options in
shell scripts.  It provides a flexible way to handle options including
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

- Automatic generation of help option and help messages.  Help option
  is implemented without explicit definition.  Help message is
  generated from the option definition.

## Table of Contents

- [Usage](#usage)
- [Option Types in Definition](#option-types-in-definition)
- [Functions](#functions)
- [Help Message Generation](#help-message-generation)
- [How to Specify Option Values](#how-to-specify-option-values)
  - [Flag Options (defined with no suffix)](#flag-options-defined-with-no-suffix)
  - [Callback Options (defined with !)](#callback-options-defined-with-)
  - [Options Requiring an Argument (defined with :)](#options-requiring-an-argument-defined-with-)
  - [Options with Optional Arguments (defined with ?)](#options-with-optional-arguments-defined-with-)
  - [Array Options (defined with @)](#array-options-defined-with-)
  - [Hash Options (defined with %)](#hash-options-defined-with-)
- [Data Validation](#data-validation)
  - [Built-in Type Validation](#built-in-type-validation)
  - [Custom Regex Validation](#custom-regex-validation)
  - [Using Callbacks for Validation](#using-callbacks-for-validation)
- [Examples](#examples)
- [See Also](#see-also)

## Usage

The following is a sample script from [repeat.sh](ex/repeat.sh) as an
example to illustrate the use of [getoptlong.sh](getoptlong.sh).

1. **Source the library:**

   ```bash
   . getoptlong.sh
   ```

2. **Define your options:**

   Create an associative array (e.g., `OPTS`) to define your script's
   options.  Each key is a string representing the option names (short
   and long, separated by `|`) and its storage type character (`+`:
   switch flag, `:`: required, `?`: optional, `@`: list, `%`: hash,
   `!`: callback).  Storage type can be followed `=` and data type
   character (e.g., `i`: integer, `f`: float).  White spaces are all
   ignored.

   Following `#` is a comment for that option, and they can be used in
   the generated help message.

   Their values are used as an initial value for variables.

   Help option `--help` (`-h`) is set by default unless you explicitly
   define it.  If given, show help message and exit.

   ```bash
   declare -A OPTS=(
        # LONG NAME   SHORT NAME
        # |           | OPTION TYPE
        # |           | | VALUE RULE
        # |           | | |   DESCRIPTION                 INITIAL VALUE
        # |           | | |   |                           |
        [ verbose   | v     # verbose output            ]=  # flag
        [ debug     | d +   # debug level               ]=0 # counter
        [ count     | c :=i # repeat count              ]=1 # required
        [ paragraph | p ?   # print newline after cycle ]=  # optional
        [ sleep     | i @=f # interval time             ]=  # list
        [ message   | m %   # print message             ]=  # hash
        [ trace     | x !   # trace execution           ]=  # callback
   )
   ```

3. **Initialize the library:**

   Call `getoptlong init` with the name of your options array. You can
   provide configuration parameters after the array name.

   ```bash
   getoptlong init OPTS
   ```

4. **Setup callback function:**

   Callbacks allow you to execute custom functions when an option is
   parsed.  This can be used for various purposes, such as triggering
   actions, setting complex states, or performing specialized argument
   processing.  You register a callback using `getoptlong callback
   <opt_name> [callback_function]`.  If `callback_function` is omitted
   or is `-`, it defaults to `opt_name`.

   Callback function is called with the option name as `$1` and the
   value as `$2`.  Next code execute `set -x` by `--trace` option, and
   `set +x` by `--no-trace` option.

   ```bash
   trace() { [[ $2 ]] && set -x || set +x ; }
   getoptlong callback help - trace -
   ```

5. **Parse the arguments:**

   Call `getoptlong parse` with the script's arguments (`"$@"`).
   Then, use `eval "$(getoptlong set)"` to set the variables according
   to the parsed options.

   ```bash
   getoptlong parse "$@" && eval "$(getoptlong set)" 
   ```

6. **Access option values:**

   - By default, options will be available as simple variables like
     `$count`, `$debug`.  Variables for flag-type options (those
     without `:`, `?`, `@`, or `%`) are assigned string `1` at the
     first time, and incremented each time the flag is encountered.

   - Any dashes (`-`) included in the option name will be replaced by
     underscores (`_`).  So the `--help-me-please` option sets the
     variable `$help_me_please`.

   - Values for array options are stored in Bash arrays (e.g., access
     with `"${sleep[@]}"`).

   - Values for hash options are stored in Bash associative arrays
     (e.g., access keys with `"${!message[@]}"` and values with
     `"${message[key]}"`).

   - Accessing value of optional argument (e.g., `[paragraph|p?]`) is
     a bit tricky.

     * If (and only if) `--paragraph='string'` is used, `$paragraph`
       will be `string`.

     * If `-p` or `--paragraph` is used (no value provided after
       `=`), `$paragraph` will be an empty string.

     * If the option is not present in the arguments, `$paragraph`
       remains unset.  You can use `-v` operator or something like
       `${paragraph+_}` notation to check if it is set or not.

   ```
   (( debug >= 2 )) && {
       getoptlong dump | column >&2
   }
   
   [[ ${1:-} =~ ^[0-9]+$ ]] && { count=$1 ; shift ; }
   
   message() { [[ -v message[$1] ]] && echo "${message[$1]}" || : ; }
   
   message BEGIN
   for (( i = 0; i < count ; i++ ))
   do
       message EACH
       (( debug > 0 )) && echo "# [ ${@@Q} ]" >&2
       "$@"
       if (( count > 0 ))
       then
           [[ -v paragraph ]] && echo "$paragraph"
           (( ${#sleep[@]} > 0 )) && {
               time=${sleep[$(( i % ${#sleep[@]} ))]}
               (( debug > 0 )) && echo "# sleep $time" >&2
               sleep $time
           }
       fi
   done
   message END
   ```

## Option Types in Definition

When defining options in the associative array:

- No suffix (e.g., `[help|h]`): A simple flag that **does not take an
  argument** (e.g., used as `-h` or `--help`).  Its associated
  variable set as empty string initially, and is incremented each time
  the option is found (e.g., if `-h` is specified, `$help` becomes
  `1`; if specified again, it becomes `2`).  They can be nagated with
  prefix `no-` like `--no-help` for `--help`, and the variable is set
  to empty.

- `:` (e.g., `[count|c:]`): Option **requires an argument**.

- `?` (e.g., `[paragraph|p?]`): Option takes an **optional argument**.
  Its associated variable is unset initially.  If no argument is
  provided when the option is used, its variable is set to an empty
  string.

- `@` (e.g., `[sleep|i@]`): **Array option**.  Collects one or more
  arguments into a Bash array.  Array options inherently expect
  arguments (the items of the array).

- `%` (e.g., `[message|m%]`): **Hash option**.  Collects one or more
  `key=value` pairs into a Bash associative array.  Hash options
  inherently expect arguments (the `key=value` pairs).

- `!` (e.g., `[count|c:!]`): **Callback option**.  This type can be
  appended to all of the above types.  If it is specified, a function
  with the same name as the option is set as the callback function.

You may be able to put prefix `no-` for non-flag type options, but the
result is undefined.

## Functions

- **`getoptlong init <opts_array_name> [CONFIGURATIONS...]`**:

  Initializes the library with the provided options definition array.
  See "How to Specify Option Values" for details on value formats.

  - `PERMUTE=<array_name>`: Non-option arguments will be collected
    into `<array_name>` (default: `GOL_ARGV`).  Setting an empty
    string disables the permutation, and stop parsing when encounted
    non-option argument.

  - `PREFIX=<string>`: Prepend `<string>` to variable names when
    setting them (default: empty).

  - `HELP=<SPEC>`: Default help option specification.  If the help
    option is not defined, the option is automatically set according
    to this specification.  (default: `help|h#show help`).

  - `EXIT_ON_ERROR=<BOOL>`: Whether to exit if an error occurs during
    parsing (default: `1`).

  - `DELIM=<string>`: Field separator (default: space, tab, comma).
    This is used to split array and hash parameters.

  - `SILENT=<BOOL>`: Suppress error messages (default: empty).

  - `DEBUG=<BOOL>`: Enable debug messages (default: empty).

- **`getoptlong parse "$@"`**:

  Parses the command-line arguments according to the initialized
  options.

- **`getoptlong set`**:

  Returns a string of shell commands to set the variables based on
  parsed options.  This should be evaluated using `eval`.

- **`getoptlong callback [-b|--before] <opt_name> [callback_function] ...`**:

  Registers a callback function.  Provide the option name and the
  corresponding callback function name.  If the function name is `-`
  or omitted, it defaults to the option name.  In that case, hyphens
  (`-`) in the option name are changed to underscores (`_`).  The
  callback is invoked when the option is parsed.

  By default the function is called after setting the value.  This
  type function is called with the option name as the first argument
  and the value as the second.  If any arguments are given in the
  callback function name, they are placed between name and value.

  With the `--before` (or `-b`) option, the function is called before
  setting the value.  This type function is called without vaue, so
  that you can detect it is called before or after.  Array type
  options can only be used to add values, but can also be pre-cleared
  by using a `before` type callback function.

- **`getoptlong configure <CONFIG_PARAM=VALUE> ...`**:

  Changes configuration parameters after initialization.  Note that
  some parameters (e.g., `PREFIX`) might not take full effect if
  changed after `getoptlong init` has processed option definitions.

- **`getoptlong dump [-a|--all]`**:

  Prints the internal state of the options and their values.  Useful
  for debugging.  By default, dumps corresponding variable names and
  their values.  With `--all` or `-a` option, dumps all administrative
  parameters.

- **`getoptlong help <SYNOPSIS>`**:

  Prints generated help message with the leading first line
  `<SYNOPSIS>`.

## Help Message Generation

`getoptlong.sh` provides robust capabilities for automatically
generating help messages for your script. This simplifies the process
of providing clear usage instructions to your users. These
automatically generated messages are then displayed in alphabetical
order by option name (long name, then short name if no long name
exists).

Key features of the help message generation include:

- **Custom Option Descriptions**: If you include a comment next to an
  option definition (e.g., `[myoption|m # This text becomes the help
  message]`), that comment will be used as the help message for that
  option. This is the primary way to set help text.

- **Automatic `--help` and `-h` Options**: If you don't define a help
  option explicitly in your `OPTS` array, `getoptlong.sh`
  automatically defines `--help` and `-h` options. When invoked, these
  options will display the generated help message and exit.

- **Fallback to Type-Based Messages**: When a custom description isn't
  provided for an option, the generated help message will
  automatically reflect its type. This indicates, for example, whether
  it's a simple flag, if it requires an argument (and its type, like
  integer or float), if an argument is optional, or if it accepts
  multiple values (for array/list and hash types). Using descriptive
  long option names (e.g., `--backup-location` instead of just
  `--loc`) can significantly enhance the clarity of these
  automatically generated messages.

- **Default Option Specification in `HELP` Config Parameter**:

  - You can customize the default help option (names, description)
    using the `HELP` configuration parameter during `getoptlong
    init`. For example: `getoptlong init OPTS HELP="myhelp|H#Show
    custom help"`.

  - The `HELP` parameter can also be set via the `&HELP` key in your
    option definition array itself (e.g., `declare -A
    OPTS=([&HELP]="myhelp|H#Show custom help" ...)`). This definition
    in the array takes precedence over the `init` option.

- **Display of Default Values**: If an option has an initial value
  assigned in the `OPTS` array (e.g., `[count|c:=i]=1`), this default
  value will be displayed in the help message (e.g., `(default: 1)`).

- **Counter Type for Flag Options**: If a flag option is given a
  numeric initial value in the `OPTS` array (e.g., `[debug|d]=0`),
  it's treated as a counter. The help message will reflect this, and
  its default value will be shown.

- **`USAGE` Config Parameter for Custom First Line**:

  - You can specify a custom first line (synopsis) for the help
    message using the `USAGE` configuration parameter during
    `getoptlong init`. For example: `getoptlong init OPTS
    USAGE="Usage: myscript [options] <file>"`.

  - The `USAGE` parameter can also be set via the `&USAGE` key in your
    option definition array (e.g., `declare -A OPTS=([&USAGE]="Usage:
    myscript [options] <file>" ...)`). This definition in the array
    takes precedence over the `init` option.

- **Manual Display with `getoptlong help`**:

  - You can manually trigger the display of the help message from
    anywhere in your script using the `getoptlong help` command.

  - Optionally, you can provide an argument to `getoptlong help` which
    will be used as the first line of the help message, overriding any
    `USAGE` parameter for that specific invocation. Example:
    `getoptlong help "Custom usage for this specific context"`.

## How to Specify Option Values

This section details how values are provided for options based on
their definition in the "Option Types in Definition" section.

* **Flag Options (defined with no suffix)**

  * Examples: `-v` or `--verbose` for `[verbose|v]`.

  * These options **do not take an argument**.  Their corresponding
    variable is typically used as a boolean state (empty or not), or a
    counter (incremented if the flag is present).

  * Prefix `no-` (e.g., `--no-verbose` or `--no-v`) can be used to
    reset the corresponding variable to empty.

* **Callback Options (defined with `!`)**

  * Examples: `-x` or `--trace` for `[trace|x]`.

  * These options are same as flag options, but register the callback
    function in the name of the option itself.  So funciton `trace()`
    is called with the value `1` when option `--trace` used, and
    called with empty string when `--no-trace` is used.

* **Options Requiring an Argument (defined with `:`)**

  * These options *must* receive an argument.

  * **Long form** (e.g., `--output` for `[output|o:]`):

    * `--output=value`: The value is part of the same argument.

    * `--output value`: The value is the next distinct command-line
      argument.

  * **Short form** (e.g., `-o` for `[output|o:]`):

    * `-ovalue`: The value immediately follows the option letter,
      without an intervening space.  This is a single command-line
      argument.

    * `-o value`: The value is the next distinct command-line
      argument.

  * **Important**: For short options, the syntax `-o=value` (using an
    equals sign) is **NOT** supported by `getoptlong.sh` as it's not
    standard for POSIX `getopts`.  Use one of the valid short form
    syntaxes above.

* **Options with Optional Arguments (defined with `?`)**

  * **Long form** (e.g., `--param` for `[param|p?]`):

    * `--param=value`: Provides `value` to the option.  The variable
      `$param` will be set to `value`.

    * `--param` (without `=value`): The variable `$param` will be set
      to an empty string.  If the option is not used at all, the
      variable is unset.

  * **Short form** (e.g., `-p` for `[param|p?]`):

    * Using just `-p`: The variable `$param` will be set to an empty
      string.

    * The form `-pvalue` (attempting to attach a value directly to a
      short option with an optional argument) is **not supported**.
      To provide a value, use the long option form (`--param=value`).

* **Array Options (defined with `@`)**

  * These options collect multiple values into a Bash array.
    Typically, array options are used by specifying the option
    multiple times (e.g., `--array val1 --array val2` or `-a val1 -a
    val2` if `-a` is defined as an array option, e.g., `[array|a@]`).
    This adds each `val` as a new element to the array.

  * As a convenience for providing multiple items at once, you can
    also use a single option instance.  For example, to provide the
    list for `[myarray|a@]` as a single argument:

    * `--myarray val1,val2,val3` or `--myarray "val1 val2 val3"`

    * `-a val1,val2,val3` or `-a "val1 val2 val3"` (if `-a` is the
      short option)

  * In this convenience form, values within the list are separated by
    commas, spaces, or tabs (controlled by the `DELIM` setting).

  * The variable (e.g., `$myarray`) will be a Bash array; access
    elements with `${myarray[0]}`, etc.

* **Hash Options (defined with `%`)**

  * These options collect key-value pairs into a Bash associative
    array.  Typically, hash options are used by specifying the option
    multiple times (e.g., `--hash key1=val1 --hash key2=val2` if
    `--hash` is defined as a hash option, e.g., `[myhash|h%]` ).  This
    adds each `key=value` pair to the associative array.  When
    `=value` part is omitted, `=1` is assumed.

  * As a convenience for providing multiple items at once, you can
    also use a single option instance.  For example, to provide the
    pairs for `[myhash|h%]` as a single argument:

    * `--myhash key1=val1,key2=val2`

    * `-h key1=val1,key2=val2` (if `-h` is the short option)

  * In this convenience form, key-value pairs are separated by
    commas.  Each pair is `key=value`.

  * The variable (e.g., `$myhash`) will be a Bash associative array;
    access values with `${myhash[key1]}`, etc.

For the array and hash type options, each line is expanded as an
element if the parameter contains newline characters.  For example,
`'BEGIN=hello world'` will expand to `BEGIN=hello` and `world`, while
`$'BEGIN=hello world\n'` will expand to `BEGIN=hello world`.

## Data Validation

`getoptlong.sh` provides mechanisms to validate the arguments passed
to options.  This helps ensure that your script receives data in the
expected format.

### Built-in Type Validation

For options that take arguments (i.e., those defined with `:`, `@`, or
`%`), you can enforce basic data types:

* **Integer Validation (`=i`)**: Appending `=i` to an option
  definition ensures that the provided argument (or each item in an
  array/each value in a hash) is a valid integer.

  * Example for an option requiring an argument: `[count|c:=i]`

  * Example for an array option: `[ids|id@=i]` (e.g., `--ids=1,2,3` or
    `--ids 1 --ids 2`)

  * Example for a hash option: `[config_levels|cl%=i]` (e.g.,
    `--config_levels=main=1,aux=2`)

  * If an argument is not a valid integer, `getoptlong.sh` will report
    an error and the script will exit.

* **Float Validation (`=f`)**: Appending `=f` to an option definition
  ensures that the provided argument(s) must be valid floating-point
  numbers.

  * Example for an option requiring an argument: `[rate|r:=f]`

  * Example for an array option: `[measurements|m@=f]` (e.g.,
    `--measurements=1.2,3.05`)

  * Example for a hash option: `[tolerances|t%=f]` (e.g.,
    `--tolerances=low=0.01,high=0.05`)

  * Similar to integer validation, a non-float argument will result in
    an error and script termination.

  * Note: Float validation (`=f`) supports formats like `123.45`.
    Exponential notation (e.g., `1.2e-3`) is **not** supported.

### Custom Regex Validation

For more specific validation needs, you can provide a Bash extended
regular expression (ERE) using the `=(<regex>)` syntax (open
parenthesis right after `=` until the last close parenthesis).  The
argument(s) provided to the option must match this regex.

* **Syntax**: `[option_name|opt_char:<validation_type>=(<regex>)]`
  (applies to options defined with `:`, `@`, or `%`).

* **Examples**:

  * Option requiring a specific string set:
    `[mode|m:=(^(fast|slow|debug)$)]` (accepts only "fast", "slow", or
    "debug")

  * Array of simple names: `[names|n@=(^[A-Za-z_]+$)]` (e.g.,
    `--names=foo,bar_baz` ensures each name consists of letters and
    underscores)

  * Hash with specific key-value format:
    `[params|p%:=(^[a-z_]+=\d+$)]` (e.g., `--params=rate=10,count=100`
    ensures keys are lowercase letters/underscores and values are
    digits).

* If the argument (or any item in an array/hash) does not match the
  regex, `getoptlong.sh` will report an error and the script will
  exit.

### Using Callbacks for Validation

For more complex or procedural validation logic that goes beyond
simple type or regex checks, callback functions offer maximum
flexibility.

When a callback is defined for an option, the option's argument
(value) is passed as the second parameter (`$2`) to the callback
function.  The callback can then perform any necessary checks.  If
validation fails, the callback should typically `exit 1` often after
printing a custom error message to `stderr`.

For example, to check if a 'count' option is a positive number:

```bash
# Callback function for the 'count' option
count_check() {
    if [[ "$2" =~ ^[0-9]+$ && "$1" -gt 0 ]]; then
        return 0
    else
        echo "Error: 'count' must be a positive integer, got '$2'." >&2
        exit 1
    fi
}
getoptlong callback count count_check
```

## Examples

The `ex/` directory contains example scripts demonstrating various
features of `getoptlong.sh`:

- [repeat.sh](ex/repeat.sh): A utility to repeat commands, showcasing
  various option types including array, hash and incrementals.

- [prefix.sh](ex/prefix.sh): Shows usage with the `PREFIX`
  configuration.

- [cmap](ex/cmap): Demonstrates color mapping, complex option parsing,
  and callbacks.

Refer to these examples for practical usage patterns.

## See Also

- [`Getopt::Long`](https://metacpan.org/dist/Getopt-Long)

- [`getoptions`](https://github.com/ko1nksm/getoptions)

- [`bash_option_parser`](https://github.com/MihirLuthra/bash_option_parser)

- [`getopts_long.sh`](https://github.com/stephane-chazelas/misc-scripts/blob/master/getopts_long.sh)
