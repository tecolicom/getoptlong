# getoptlong.sh

`getoptlong.sh` is a Bash library for parsing command-line options in
shell scripts.  It provides a flexible way to handle options including
followings.

- Supports both short options (e.g., `-h`) and long options (e.g.,
  `--help`)

- Allows options and non-option arguments to be freely mixed on the
  command line (PERMUTE)

- Supports required arguments, optional arguments, array-type, and
  hash-type options

- Provides validation for integer, floating-point, and custom regular
  expression patterns

- Enables registration of callback functions for each option for
  flexible processing

## Usage

The following is a sample script from [repeat.sh](ex/repeat.sh) as an
example to illustrate the use of [getoptlong.sh](getoptlong.sh).

1.  **Source the library:**

    ```bash
    . getoptlong.sh
    ```

2.  **Define your options:**

    Create an associative array (e.g., `OPT`) to define your script's
    options.  Each key is a string representing the option names
    (short and long, separated by `|`) and its storage type character.
    Storage type can be followed `=` and data type character (e.g.,
    `i`: integer, `f`: float).  White spaces are all ignored.

    ```bash
    declare -A OPTS=(
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
    getoptlong init OPTS
    ```

4.  **Setup callback function:**

    Callbacks allow you to execute custom functions when an option is
    parsed.  This can be used for various purposes, such as triggering
    actions, setting complex states, or performing specialized
    argument processing.  You register a callback using `getoptlong
    callback <opt_name> [callback_function]`.  If `callback_function`
    is omitted or is `-`, it defaults to `opt_name`.

    Callback function is called with the value as `$1`.  Next code
    execute `set -x` by `--trace` option, and `set +x` by `--no-trace`
    option.

    ```bash
    trace() { [[ $1 ]] && set -x || set +x ; }
    getoptlong callback help - trace -
    ```

5.  **Parse the arguments:**

    Call `getoptlong parse` with the script's arguments (`"$@"`).
    Then, use `eval "$(getoptlong set)"` to set the variables
    according to the parsed options.

    ```bash
    getoptlong parse "$@" && eval "$(getoptlong set)" 
    ```

6.  **Access option values:**

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
        `${paragraph+_}` notation to check it is set or not.

    ```
    (( debug >= 2 )) && {
        getoptlong dump | column >&2
        declare -p sleep
        declare -p message
    }
    
    : ${paragraph:=${paragraph+${paragraph:-$'\n'}}}
    
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
            [[ $paragraph ]] && echo -n "$paragraph"
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

You may be able to put prefix `no-` for non-flag type options, but the
result is undefined.

## Functions

- **`getoptlong init <opts_array_name> [CONFIGURATIONS...]`**:

  Initializes the library with the provided options definition array.
  See "How to Specify Option Values" for details on value formats.

  - `PERMUTE=<array_name>`: Non-option arguments will be collected
    into `<array_name>` (default: `GOL_ARGV`).

  - `PREFIX=<string>`: Prepend `<string>` to variable names when
    setting them (default: empty).

  - `EXIT_ON_ERROR=<BOOL>`: Whether to exit if an error occurs during
    parsing (default: `1`).

  - `IFS=<string>`: Input Field Separator (default: `$' \t,'`).  This
    is used to split array parameters.

  - `SILENT=<BOOL>`: Suppress error messages (default: empty).

  - `DEBUG=<BOOL>`: Enable debug messages (default: empty).

- **`getoptlong parse "$@"`**:

  Parses the command-line arguments according to the initialized
  options.

- **`getoptlong set`**:

  Returns a string of shell commands to set the variables based on
  parsed options.  This should be evaluated using `eval`.

- **`getoptlong callback <opt_name> [callback_function] ...`**:

  Registers a callback function.  Provide the option name and the
  corresponding callback function name.  If the function name is `-`
  or omitted, it defaults to the option name.  If the option string
  contains a hyphens (`-`), they are changed to underscores (`_`).
  The callback is invoked with the option's value when the option is
  parsed.

- **`getoptlong configure <CONFIG_PARAM=VALUE> ...`**:

  Changes configuration parameters after initialization.  Note that
  some parameters (e.g., `PREFIX`) might not take full effect if
  changed after `getoptlong init` has processed option definitions.

- **`getoptlong dump`**:

  Prints the internal state of the options and their values.  Useful
  for debugging.

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
    commas, spaces, or tabs (controlled by the `IFS` setting).

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
regular expression (ERE) using the `=(<regex>)` syntax.  The
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
(value) is passed as the first parameter (`$1`) to the callback
function.  The callback can then perform any necessary checks.  If
validation fails, the callback should typically `exit 1` often after
printing a custom error message to `stderr`.

For example, to check if a 'count' option is a positive number:

```bash
# Callback function for the 'count' option
count_check() {
    if [[ "$1" =~ ^[0-9]+$ && "$1" -gt 0 ]]; then
        return 0
    else
        echo "Error: 'count' must be a positive integer, got '$1'." >&2
        exit 1
    fi
}
getoptlong callback count count_check
```

## Examples

The `ex/` directory contains example scripts demonstrating various
features of `getoptlong.sh`:

- [repeat.sh](ex/repeat.sh): A utility to repeat commands, showcasing various
  option types including array, hash and incrementals.

- [prefix.sh](ex/prefix.sh): Shows usage with the `PREFIX` configuration.

- [cmap](ex/cmap): Demonstrates color mapping, complex option parsing, and
  callbacks.

Refer to these examples for practical usage patterns.

## See Also

- [Getopt::Long](https://metacpan.org/dist/Getopt-Long)

- [getoptions](https://github.com/ko1nksm/getoptions)
