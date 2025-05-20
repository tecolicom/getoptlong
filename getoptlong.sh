#!/usr/bin/env bash

export PERL5LIB=$(pwd)/lib:$PERL5LIB

ansiecho=ansiecho

declare -A opt
declare -a opts
declare -a hue=($(seq 0 60 359))

while getopts m:l:rx OPT
do
    [[ ${opt[x]} ]] && set -x
    opt[$OPT]=${OPTARG:-yes}
done
shift $((OPTIND - 1))

[[ ${opt[m]} ]] && export COLOR_PACKAGE=${opt[m]}

table() {
    local mod=$1
    for s in 100
    do
	opts=(--separate $'\n')
	for h in ${hue[@]}
	do
	    opts+=("(h=$h, s=$s)")
	    for l in $(seq 0 5 99)
	    do
		col=$(printf "hsl(%03d,%03d,%03d)" $h $s $l)
		if [[ ${opt[r]} ]]
		then
		    arg="$col/$col$mod"
		else
		    arg="$col$mod/$col"
		fi
		label=${opt[l]:-██  $col$mod}
		opts+=(-c "$arg" "$label")
	    done
	done
	$ansiecho "${opts[@]}" | ansicolumn -C ${#hue[@]} --cu=1 --margin=0
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
