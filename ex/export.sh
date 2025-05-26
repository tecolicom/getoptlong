#!/usr/bin/env bash

. "${0%/*}"/../getoptlong.sh

set -eu

help() {
    cat <<-END
	repeat count command
	repeat [ options ] command
	    -c#, --count=#        repeat count
	    -i#, --sleep=#        interval time
	    -p , --paragraph[=#]  print newline (or #) after each cycle
	    -x , --trace          trace execution (set -x)
	    -d , --debug          debug mode
	END
    exit 0
}
trace() { [[ $1 ]] && set -x || set +x ; }

declare -A OPT=(
    [ count     | c : ]=1
    [ sleep     | i : ]=0
    [ paragraph | p ? ]=
    [ trace     | x   ]=
    [ debug     | d + ]=0
    [ help      | h   ]=
)
gol_setup OPT EXPORT DEBUG=${DEBUG_ME:-}
gol_callback help - trace -
getoptlong "$@" && shift $((OPTIND - 1))
(( opt_debug >= 2 )) && gol_dump | column >&2
[[ ! -v opt_paragraph ]] && opt_paragraph= || : ${opt_paragraph:=$'\n'} 

case ${1:-} in
    [0-9]*) $opt_count=$1 ; shift ;;
esac

while (( opt_count-- ))
do
    eval "${@@Q}"
    if (( $opt_count > 0 ))
    then
	[[ $opt_paragraph ]] && echo -n "$opt_paragraph"
	[[ $opt_sleep ]] && sleep $opt_sleep
    fi
done
