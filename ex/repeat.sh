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
	    -d , --debug              debug level
	END
    exit 0
}
trace() { [[ $1 ]] && set -x || set +x ; }

declare -A OPTS=(
    [ count     | c :=i ]=1
    [ sleep     | i @=f ]=
    [ paragraph | p ?   ]=
    [ trace     | x     ]=
    [ debug     | d     ]=0
    [ help      | h     ]=
    [ message   | m %=(^(BEGIN|END|EACH)=) ]=
)
getoptlong init OPTS
getoptlong callback help - trace -
getoptlong parse "$@" && eval "$(getoptlong set)"

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
