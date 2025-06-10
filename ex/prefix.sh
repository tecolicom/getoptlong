#!/usr/bin/env bash

. "$(dirname $0)"/../getoptlong.sh

set -eu

help() {
    cat <<-END
	repeat count command
	repeat [ options ] command
	    -c#, --count=#            repeat count
	    -i#, --sleep=#            interval time
	    -p , --paragraph[=#]      print newline (or #) after each cycle
	    -m#, --message=WHEN=WHAT  print WHAT for WHEN (BEGIN, END, EACH)
	    -x , --set-x              trace execution
	    -d , --debug              debug level
	END
    exit 0
}
set_x() { [[ $1 ]] && set -x || set +x ; }

declare -A OPTS=(
    [ count     | c :=i ]=1
    [ sleep     | i @=f ]=
    [ paragraph | p ?   ]=
    [ set-x     | x     ]=
    [ debug     | d     ]=0
    [ help      | h     ]=
    [ message   | m %=(^(BEGIN|END|EACH)=) ]=
)
getoptlong init OPTS PREFIX=opt_
getoptlong callback help - set-x -
getoptlong parse "$@" && eval "$(getoptlong set)"

(( opt_debug >= 2 )) && getoptlong dump | column >&2

[[ ${1:-} =~ ^[0-9]+$ ]] && { opt_count=$1 ; shift ; }

message() { [[ -v opt_message[$1] ]] && echo "${opt_message[$1]}" || : ; }

message BEGIN
for (( i = 0; i < opt_count ; i++ )) ; do
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
