#!/usr/bin/env bash

export PERL5LIB=$(pwd)/lib:$PERL5LIB

ansiecho=ansiecho

declare -A opt=(
    [B]="██  "
    [H]="$(seq 0 60 359)"
    [L]="$(seq 0 5 99)"
    [S]="100"
)
opt() { [[ ${opt[$1]} ]] ; }
opts() { echo ${opt[$1]} ; }

declare -a option

while getopts m:l:rx OPT
do
    opt[$OPT]=${OPTARG:-yes}
    opt x && set -x
done
shift $((OPTIND - 1))

opt m && export COLOR_PACKAGE=${opt[m]}

table() {
    local mod=$1
    for s in ${opt[S]}
    do
	option=(--separate $'\n')
	for h in ${opt[H]}
	do
	    option+=("(h=$h, s=$s)")
	    for l in ${opt[L]}
	    do
		col=$(printf "hsl(%03d,%03d,%03d)" $h $s $l)
		opt r && arg="$col/$col$mod" \
		      || arg="$col$mod/$col"
		label=${opt[l]:-${opt[B]}$col$mod}
		option+=(-c "$arg" "$label")
	    done
	done
	H=(${opt[H]})
	$ansiecho "${option[@]}" | ansicolumn -C ${#H[@]} --cu=1 --margin=0
    done
}

if [[ $# > 0 ]]
then
    mods=($*)
else
    mods=(%l50 %y49 %y50+h180 %y50+r180)
    mods=(+r180%y50)
fi
for mod in ${mods[@]}
do
    table $mod
done
