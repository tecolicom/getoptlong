#!/usr/bin/env bash

. "${0%/*}"/../getoptlong.sh

set -eu

help() {
    cat <<-END
	repeat count command
	repeat [ options ] command
	    -c#, --count=#            repeat count
	    -i#, --sleep=#            interval time
	    -p , --paragraph[=#]      print newline (or #) after each cycle
	    -m#, --message=WHEN=WHAT  print WHAT for WHEN (BEGIN, END, EACH)
	    -x , --trace              trace execution (set -x)
	    -d , --debug              debug mode
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
    [ message   | m % ]=
)
getoptlong init OPT ARGV EXPORT DEBUG=${DEBUG_ME:-}
getoptlong callback help - trace -
getoptlong parse "$@" && set -- "${ARGV[@]}"

(( opt_debug >= 2 )) && gol_dump | column >&2
[[ ! -v opt_paragraph ]] && opt_paragraph= || : ${opt_paragraph:=$'\n'} 

case ${1:-} in
    [0-9]*) opt_count=$1 ; shift ;;
esac

message() {
    if [[ ${opt_message[$1]:-} ]] ; then
	echo "${opt_message[$1]}"
    fi
}

message BEGIN
while (( opt_count-- ))
do
    (( opt_debug >= 1 )) && echo "[ ${@@Q} ]" >&2
    message EACH
    eval "${@@Q}"
    if (( $opt_count > 0 ))
    then
	[[ $opt_paragraph ]] && echo -n "$opt_paragraph"
	[[ $opt_sleep ]] && sleep $opt_sleep
    fi
done
message END
