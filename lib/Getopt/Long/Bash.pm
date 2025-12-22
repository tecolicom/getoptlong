package Getopt::Long::Bash;

our $VERSION = "0.4.1";

1;

__END__

=encoding utf-8

=head1 NAME

Getopt::Long::Bash - Bash library for option parsing like Perl's Getopt::Long

=head1 SYNOPSIS

Install via CPAN:

    cpanm Getopt::Long::Bash

Then use in your bash script:

    #!/usr/bin/env bash

    declare -A OPTS=(
        [ debug     | d  ]=0
        [ count     | c: ]=1
    )

    . getoptlong.sh OPTS "$@"

    (( debug > 0 )) && echo "Debug mode is ON"
    echo "$@"

=head1 DESCRIPTION

B<getoptlong.sh> is a Bash library for parsing command-line options in
shell scripts. It provides a flexible way to handle options including:

=over 4

=item * Clear and expressive option syntax

=item * Supports both short options (e.g., C<-h>) and long options (e.g., C<--help>)

=item * Allows options and non-option arguments to be freely mixed (PERMUTE)

=item * Supports flag type incremental option as well as required arguments,
optional arguments, array-type, and hash-type options

=item * Provides validation for integer, floating-point, and custom regex patterns

=item * Enables registration of callback functions for each option

=item * Supports multiple calls for subcommands or function-level option analysis

=item * Automatic generation of help option and help messages

=back

=head1 OPTION TYPES

=over 4

=item B<Flag Options> (no suffix or C<+>)

Act as switches. First use sets to 1, multiple uses increment.
C<--no-option> resets to empty.

    [verbose|v]   # flag option
    [debug|d+]=0  # with initial value

=item B<Required Argument> (C<:>)

Options that always require a value.

    [output|o:]=/dev/stdout

=item B<Optional Argument> (C<?>)

Options that can take a value or be specified without one.

    [mode|m?]

=item B<Array Options> (C<@>)

Accept multiple values as an array.

    [include|I@]

=item B<Hash Options> (C<%>)

Accept C<key=value> pairs as an associative array.

    [define|D%]

=item B<Callback Options> (C<!>)

Execute a callback function when the option is parsed.

    [execute|x!]

=back

=head1 VALUE VALIDATION

=over 4

=item C<=i> - Integer validation

=item C<=f> - Float validation

=item C<=(<regex>)> - Custom regex validation

=back

Example:

    [count|c:=i]           # integer
    [ratio|r:=f]           # float
    [mode|m:=(^(fast|slow)$)]  # custom regex

=head1 COMMANDS

=over 4

=item B<getoptlong init> I<opts_array> [I<CONFIG>...]

Initialize the library with option definitions.

=item B<getoptlong parse> "$@"

Parse command-line arguments.

=item B<getoptlong set>

Generate shell commands to set variables (use with C<eval>).

=item B<getoptlong callback> [-b|--before] I<opt_name> [I<function>]

Register a callback function for an option.

=item B<getoptlong configure> I<KEY>=I<VALUE> ...

Change configuration at runtime.

=item B<getoptlong dump> [-a|--all]

Dump internal state for debugging.

=item B<getoptlong help> [I<SYNOPSIS>]

Display generated help message.

=back

=head1 CONFIGURATION

=over 4

=item B<PERMUTE>=I<array_name>

Store non-option arguments in specified array.

=item B<PREFIX>=I<string>

Add prefix to variable names.

=item B<EXIT_ON_ERROR>=I<0|1>

Exit on parse error (default: 1).

=item B<SILENT>=I<0|1>

Suppress error messages (default: 0).

=item B<DEBUG>=I<0|1>

Enable debug messages (default: 0).

=item B<DELIM>=I<string>

Delimiter for array/hash values (default: space, tab, comma).

=item B<HELP>=I<spec>

Customize help option (default: C<help|h#show help>).

=item B<USAGE>=I<string>

Synopsis string for help message.

=back

=head1 INSTALLATION

=head2 Via CPAN

    cpanm Getopt::Long::Bash

After installation, C<getoptlong.sh> will be available in your PATH.

=head2 Direct from GitHub

    # Latest stable version
    source <(curl -fsSL https://raw.githubusercontent.com/tecolicom/getoptlong/dist/getoptlong.sh)

    # Local download
    curl -fsSL https://raw.githubusercontent.com/tecolicom/getoptlong/dist/getoptlong.sh -o getoptlong.sh

=head1 SEE ALSO

L<https://github.com/tecolicom/getoptlong>

L<Getopt::Long>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

MIT License

=cut
