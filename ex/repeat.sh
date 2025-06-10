#!/usr/bin/env bash

. "$(dirname $0)"/../getoptlong.sh

set -eu

SYNOPSIS='repeat [ count ] [ options ] command'
declare -A OPTS=(
    [ count     | c :=i # repeat count              ]=1
    [ sleep     | i @=f # interval time             ]=
    [ paragraph | p ?   # print newline after cycle ]=
    [ set-x     | x     # trace execution           ]=
    [ debug     | d     # debug level               ]=0
    [ help      | h     # show help                 ]=
    [ message   | m %=(^(BEGIN|END|EACH)=) # print message at BEGIN|END|EACH ]=
)
help() { getoptlong help "$SYNOPSIS" ; exit ; }
set_x() { [[ $1 ]] && set -x || set +x ; }

getoptlong init OPTS
getoptlong callback help - set-x -
getoptlong parse "$@" && eval "$(getoptlong set)"

(( debug >= 2 )) && getoptlong dump | column >&2

[[ ${1:-} =~ ^[0-9]+$ ]] && { count=$1 ; shift ; }

message() { [[ -v message[$1] ]] && echo "${message[$1]}" || : ; }

message BEGIN
for (( i = 0; $# > 0 && i < count ; i++ )) ; do
    message EACH
    (( debug > 0 )) && echo "# [ ${@@Q} ]" >&2
    "$@"
    if (( count > 0 )) ; then
	[[ -v paragraph ]] && echo "$paragraph"
	if (( ${#sleep[@]} > 0 )) ; then
	    time="${sleep[$(( i % ${#sleep[@]} ))]}"
	    (( debug > 0 )) && echo "# sleep $time" >&2
	    sleep $time
	fi
    fi
done
message END
