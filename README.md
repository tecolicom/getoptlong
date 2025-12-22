[![Actions Status](https://github.com/tecolicom/getoptlong/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tecolicom/getoptlong/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/Getopt-Long-Bash.svg)](https://metacpan.org/release/Getopt-Long-Bash)
# NAME

getoptlong - Option parsing that does what you mean, for Bash

# SYNOPSIS

**One-liner:**

    declare -A OPTS=( [verbose|v]= [output|o:]= )
    . getoptlong.sh OPTS "$@"

**Multi-step:**

    . getoptlong.sh
    getoptlong init OPTS
    getoptlong parse "$@" && eval "$(getoptlong set)"

# DESCRIPTION

**getoptlong.sh** is a Bash library providing Perl's [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong)-style
option parsing.

Options are defined in a Bash associative array: the key specifies the
option name, aliases, type, and other attributes; the value sets the
default. The library parses command-line arguments, sets variables, and
leaves non-option arguments in `$@`.

Two usage modes are available: **one-liner** for simple scripts (source
with array name and arguments), and **multi-step** for advanced control
(separate init, parse, and set calls).

Supports short (`-v`) and long (`--verbose`) options with bundling
(`-vvv`). **Option types**: _flag_, _required argument_, _optional
argument_, _array_, _hash_, _callback_. **Validation**: _integer_,
_float_, _regex_. **Help message** generation. **Pass-through** for
wrapper scripts. **Multiple invocations** for subcommand support.

For a gentle introduction, see [Getopt::Long::Bash::Tutorial](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ABash%3A%3ATutorial).

# INSTALLATION

    cpanm -n Getopt::Long::Bash

# OPTION DEFINITION SYNTAX

The key format is:

    [NAME[|ALIAS...][TYPE[MOD]][DEST][=VALIDATE] # DESC]=DEFAULT

## COMPONENTS

- **NAME**

    Long option name (`--name`). Hyphens become underscores in variables
    (`--dry-run` → `$dry_run`).

- **ALIAS**

    Additional names separated by `|` (e.g., `verbose|v|V`).

- **TYPE**

    Argument type specifier:

        (none) or +  Flag (counter)
        :            Required argument
        ?            Optional argument
        @            Array (multiple values)
        %            Hash (key=value pairs)

- **MOD (MODIFIER)**

    Special behavior flags (can be combined):

        !   Callback - calls function when option is parsed
        >   Pass-through - collects option and value into array

- **DEST**

    Custom variable name (e.g., `[opt|o:MYVAR]` stores in `$MYVAR`).

- **VALIDATE**

    Value validation: `=i` (integer), `=f` (float), `=<regex>`.

- **DESC (DESCRIPTION)**

    Help message text (everything after `#`).

## EXAMPLE

    declare -A OPTS=(
        [verbose|v+     # Verbosity level         ]=0
        [output|o:      # Output file             ]=/dev/stdout
        [config|c?      # Config file (optional)  ]=
        [include|I@     # Include paths           ]=
        [define|D%      # Definitions             ]=
        [count|n:=i     # Count (integer)         ]=1
        [mode|m:=(^(fast|slow)$) # Mode           ]=fast
    )

# OPTION TYPES

Each option type determines how arguments are handled and stored.

## FLAG (`+` or none)

A flag takes no argument. First use sets to `1`, subsequent uses
increment (useful for verbosity levels). Use `--no-X` to reset to
empty string. Bundling supported: `-vvv` equals `-v -v -v`.

    [verbose|v]=        # $verbose: 1 when specified
    [debug|d+]=0        # $debug: increments (-d -d -d or -ddd)

Numeric initial value (like `0`) enables counter display in help.

## REQUIRED ARGUMENT (`:`)

The option requires an argument; error if missing. Use `--no-X` to
reset to empty string (useful for disabling defaults).

    [output|o:]=        # --output=file, --output file, -ofile, -o file

Short form `-o=value` is **not** supported (use `-ovalue` or `-o value`).

## OPTIONAL ARGUMENT (`?`)

The argument is optional. The variable has three possible states: a value
(`--config=file`), empty string (`--config` without value), or unset
(option not specified). Use `[[ -v config ]]` to check if the option
was specified.

    [config|c?]=        # --config=file or --config (sets to "")

**Syntax:**

- `--config=value`: variable set to `value`
- `--config`: variable set to empty string `""`
- `-c`: sets to empty string; `-cvalue` form is **not** supported

## ARRAY (`@`)

Collects multiple values into an array. Multiple specifications accumulate.
A single option can contain delimited values (default: space, tab, comma;
configurable via `DELIM`). Access with `"${include[@]}"`.

    [include|I@]=       # --include a --include b or --include a,b

## HASH (`%`)

Collects `key=value` pairs into an associative array. Key without value
is treated as `key=1`. Multiple pairs can be specified: `--define A=1,B=2`.
Access with `${define[KEY]}`, keys with `${!define[@]}`.

    [define|D%]=        # --define KEY=VAL or --define KEY (KEY=1)

## CALLBACK (`!`)

Calls a function when the option is parsed. Default function name is the
option name with hyphens converted to underscores; use `getoptlong callback`
to specify a custom function. Can combine with any type (`+!`, `:!`,
`?!`, `@!`, `%!`). See ["CALLBACKS"](#callbacks) for registration and timing details.

    [action|a!]=        # Calls action() when specified
    [file|f:!]=         # Calls file() with argument

# VALIDATION

Option values can be validated using type specifiers or regex patterns:
`=i` for integers, `=f` for floats, `=(` ... `)` for regex.

    [count:=i]=1                    # Integer (positive/negative)
    [ratio:=f]=0.5                  # Float (e.g., 123.45)
    [mode:=(^(a|b|c)$)]=a           # Regex: exactly a, b, or c

Validation occurs before the value is stored or callbacks are invoked.
For array options, each element is validated; for hash options, each
`key=value` pair is matched as a whole. Error on validation failure
(exits if `EXIT_ON_ERROR=1`).

# DESTINATION VARIABLE

By default, values are stored in variables named after the option.
A custom destination can be specified by adding the variable name after
TYPE/MODIFIER and before VALIDATE: `[NAME|ALIAS:!DEST=(REGEX)]`.
`PREFIX` setting applies to custom names too (see ["getoptlong init"](#getoptlong-init)).

    [count|c:COUNT]=1       # Store in $COUNT instead of $count
    [debug|d+DBG]=0         # Store in $DBG

# HELP MESSAGE

Help message is automatically generated from option definitions.

## AUTOMATIC HELP OPTION

By default, `--help` / `-h` displays help and exits. To customize
or disable, use one of these methods (in order of precedence):

    [&HELP]="usage|u#Show usage"            # 1. &HELP key in OPTS
    getoptlong init OPTS HELP="manual|m"    # 2. HELP parameter in init
    [help|h # Custom help text]=            # 3. Explicit option definition
    getoptlong init OPTS HELP=""            # Disable help option

## SYNOPSIS (USAGE)

Set the usage line displayed at the top of help output:

    [&USAGE]="Usage: cmd [options] <file>"  # In OPTS array
    getoptlong init OPTS USAGE="..."        # Or via init parameter

## OPTION DESCRIPTIONS

Text after `#` in the option definition becomes the help description.
If omitted, a description is auto-generated. Default values are shown
as `(default: value)`.

    [output|o: # Output file path]=/dev/stdout

# CALLBACKS

Callback functions are called when an option is parsed. The value is
stored in the variable as usual, and the callback is invoked for
additional processing such as validation or side effects. Callbacks
work the same way with pass-through options.

## REGISTRATION

Register callbacks with `getoptlong callback`. If function name is
omitted or `-`, uses option name (hyphens to underscores).

    getoptlong callback <option> [function] [args...]
    getoptlong callback --before <option> [function] [args...]

## CALLBACK TIMING

Normal callbacks are called **after** value is set, receiving the option
name and value. Pre-processing callbacks (`--before`/`-b`) are called
**before** value is set, without the value argument.

    callback_func "option_name" "value" [args...]   # normal
    callback_func "option_name" [args...]           # --before

## ERROR HANDLING

Callbacks must handle their own errors. `EXIT_ON_ERROR` only applies
to parsing errors, not callback failures. Use explicit `exit` if needed.

    validate_file() {
        [[ -r "$2" ]] || { echo "Cannot read: $2" >&2; exit 1; }
    }
    getoptlong callback input-file validate_file

# PASS-THROUGH (> Modifier)

Collects options and values into an array instead of storing in a
variable. Useful for passing options to other commands. The actual
option form used (`--pass`, `-p`, `--no-pass`) is collected, and
for options with values, both option and value are added. Multiple
options can collect to the same array. If no array name is specified
after `>`, uses the option name. Can combine with callback:
`[opt|o:!>array]`.

    [pass|p:>collected]=    # Option and value added to collected array

After `--pass foo`: `collected=("--pass" "foo")`

# COMMANDS

The `getoptlong` function provides the following subcommands.

## getoptlong init

Initialize with option definitions. Must be called before `parse`.

    getoptlong init <array_name> [CONFIG...]

**Configuration parameters:**

    PERMUTE=<array>     Non-option storage (default: GOL_ARGV)
    PREFIX=<string>     Variable name prefix (default: none)
    HELP=<spec>         Help option (default: help|h#show help)
    USAGE=<string>      Synopsis line
    EXIT_ON_ERROR=0|1   Exit on parse error (default: 1)
    SILENT=0|1          Suppress error messages (default: 0)
    DEBUG=0|1           Debug output (default: 0)
    DELIM=<string>      Array/hash delimiter (default: space,tab,comma)

## getoptlong parse

Parse arguments. Returns 0 on success, non-zero on error. Always
quote `"$@"`. With `EXIT_ON_ERROR=1` (default), script exits on
error. With `EXIT_ON_ERROR=0`, check return value:

    getoptlong parse "$@"

    if ! getoptlong parse "$@"; then
        echo "Parse error" >&2
        exit 1
    fi

## getoptlong set

    eval "$(getoptlong set)"

Outputs shell commands to set variables and update positional parameters.
Variables are actually set during `parse`; this updates `$@`.

## getoptlong callback

Register callback function for option. Use `-b`/`--before` to call
before value is set. If `func` is omitted, uses option name (hyphens
to underscores). Additional `args` are passed to the callback.

    getoptlong callback [-b|--before] <opt> [func] [args...]

## getoptlong configure

Change configuration at runtime. Safe to change: `EXIT_ON_ERROR`,
`SILENT`, `DEBUG`, `DELIM`. Changing `PREFIX` after init may cause issues.

    getoptlong configure KEY=VALUE ...

## getoptlong dump

Debug output to stderr showing option names, variables, and values.
Use `-a`/`--all` to show all internal state.

    getoptlong dump [-a|--all]

## getoptlong help

Display help message. Optional `SYNOPSIS` overrides `&USAGE`/`USAGE`.

    getoptlong help [SYNOPSIS]

# CONFIGURATION KEYS IN OPTS

Special keys in options array (take precedence over init parameters):

    [&HELP]=<spec>          Help option (e.g., "usage|u#Show usage")
    [&USAGE]=<string>       Synopsis string
    [&REQUIRE]=<version>    Minimum version (e.g., "0.2")

Version check exits with error if current version is older.

# MULTIPLE INVOCATIONS

`getoptlong init` and `parse` can be called multiple times for
subcommand support:

    # Parse global options
    getoptlong init GlobalOPTS PERMUTE=REST
    getoptlong parse "$@" && eval "$(getoptlong set)"

    # Parse subcommand options
    case "${REST[0]}" in
        commit)
            getoptlong init CommitOPTS
            getoptlong parse "${REST[@]:1}" && eval "$(getoptlong set)"
            ;;
    esac

# EXAMPLES

See `ex/` directory for sample scripts:

- `repeat.sh` - basic option types
- `prefix.sh` - PREFIX setting
- `dest.sh` - custom destination variables
- `subcmd.sh` - subcommand handling
- `cmap` - complex real-world example

# SEE ALSO

- [Getopt::Long::Bash::Tutorial](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ABash%3A%3ATutorial) - getting started guide
- [Getopt::Long::Bash](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ABash) - module information
- [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) - Perl module inspiration
- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong) - repository

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

Copyright 2025 Kazumasa Utashiro

# LICENSE

MIT License
