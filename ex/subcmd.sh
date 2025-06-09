#!/usr/bin/env bash

. $(dirname $0)/../getoptlong.sh

help_main() {
    cat <<-END
	repeat [ options ] command
	    -h , --help  show help
	    -d , --debug debug level
	END
    exit 0
}
declare -A OPTS=([debug|d]=0 [help|h]= [message|m%]=)
getoptlong init OPTS PERMUTE=
getoptlong callback help help_main

echo "Args before main parse: [$@]" >&2
getoptlong parse "$@"
echo "Args after main parse, before eval-set: [$@]" >&2
echo "OPTIND after main parse: [$OPTIND]" >&2
eval "$(getoptlong set)"
echo "Args after main parse, after eval-set: [$@]" >&2


# Explicit debug output
echo "Debug var after main parse: [$debug]" >&2
echo "Message var after main parse: [${message[*]}]" >&2
# Remaining args after main parse is now the 3rd echo above.

# declare -p message # Original debug line, can be removed

# Simplified subcmd logic
subcmd_val="$1"
if [[ -n "$subcmd_val" ]]; then
    shift
    echo "Subcommand identified: [$subcmd_val]" >&2
else
    echo "Error: Subcommand is required." >&2
    exit 1
fi
echo "Args for sub-parser: [$@]" >&2

case $subcmd_val in
    flag) declare -A SUB_OPTS=([flag|F]=) ;;
    data) declare -A SUB_OPTS=([data|D:]=) ;;
    list) declare -A SUB_OPTS=([list|L@]=) ;;
    hash) declare -A SUB_OPTS=([hash|H%]=) ;;
    *)    echo "$subcmd_val: unknown subcommand" >&2 ; exit 1 ;;
esac

getoptlong init SUB_OPTS
getoptlong parse "$@" && eval "$(getoptlong set)"

[[ "$debug" -gt 0 ]] && getoptlong dump SUB_OPTS

case $subcmd_val in
    flag) declare -p flag ;;
    data) declare -p data ;;
    list) declare -p list ;;
    hash) declare -p hash ;;
esac

if (( $# > 0 )); then
    echo "Remaining args after sub-parser: [$@]" >&2
fi
