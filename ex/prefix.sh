#!/usr/bin/env bash

. "$(dirname $0)"/../getoptlong.sh

set -eu

declare -A OPTS=(
    [&PREFIX]=opt_
    [&USAGE]="$(basename $0) [ count ] [ options ] command"
    [ count     | c :=i # repeat count              ]=1
    [ sleep     | i @=f # interval time             ]=
    [ paragraph | p ?   # print newline after cycle ]=
    [ trace     | x     # trace execution           ]=
    [ debug     | d     # debug level               ]=0
    [ help      | h     # show help                 ]=
    [ message   | m %=(^(BEGIN|END|EACH)=) # print message at BEGIN|END|EACH ]=
)
help() { getoptlong help ; exit ; }
trace() { [[ $1 ]] && set -x || set +x ; }

getoptlong init OPTS
getoptlong callback help - trace -
getoptlong parse "$@" && eval "$(getoptlong set)"

(( opt_debug >= 2 )) && getoptlong dump --all | column >&2

[[ ${1:-} =~ ^[0-9]+$ ]] && opt_count=$1 && shift

message() { [[ -v opt_message[$1] ]] && echo "${opt_message[$1]}" || : ; }

message BEGIN
for (( i = 0; $# > 0 && i < opt_count ; i++ )) ; do
    message EACH
    (( opt_debug > 0 )) && echo "# [ ${@@Q} ]" >&2
    "$@"
    if (( opt_count > 0 )) ; then
	[[ -v opt_paragraph ]] && echo "$opt_paragraph"
	if (( ${#opt_sleep[@]} > 0 )) ; then
	    time="${opt_sleep[$(( i % ${#opt_sleep[@]} ))]}"
	    (( opt_debug > 0 )) && echo "# sleep $time" >&2
	    sleep $time
	fi
    fi
done
message END
