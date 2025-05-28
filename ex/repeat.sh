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
getoptlong init OPT - DEBUG=${DEBUG_ME:-}
getoptlong callback help - trace -
getoptlong parse "$@" && eval "$(getoptlong set)"
(( OPT[debug] >= 1 )) && echo "OPTIND=$OPTIND"
(( OPT[debug] >= 2 )) && gol_dump | column >&2
[[ ! -v OPT[paragraph] ]] && OPT[paragraph]= || : ${OPT[paragraph]:=$'\n'} 

case ${1:-} in
    [0-9]*) OPT[count]=$1 ; shift ;;
esac

while (( OPT[count]-- ))
do
    (( ${OPT[debug]} >= 1 )) && echo "[ ${COMMAND[@]@Q} ]" >&2
    eval "${@@Q}"
    if (( OPT[count] > 0 ))
    then
	[[ ${OPT[paragraph]} ]] && echo -n "${OPT[paragraph]}"
	[[ ${OPT[sleep]} ]] && sleep ${OPT[sleep]}
    fi
done
