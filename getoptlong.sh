#!/usr/bin/env bash

export PERL5LIB=$(pwd)/lib:$PERL5LIB

ansiecho=ansiecho

declare -A opt=(
      [format]=hsl
        [mods]="+r180%y50"
         [pkg]=
        [lead]="██  "
           [X]=
           [Y]=
           [Z]=
       [order]=
       [quiet]=
       [label]=
     [reverse]=
      [column]=
     [verbose]=
       [debug]=
)

#
# ! が付いていると引数を取らない
#
declare -A alias=(
    [C]=column
    [M]=pkg
    [m]=mods
    [r]=reverse!
    [q]=quiet!
    [l]=label
    [o]=order
    [f]=format
    [v]=verbose!
    [d]=debug!
)

format() {
   [[ $# == 0 ]] && return
    case $1 in
    hsl)
        opt[order]="x z y"
        opt[X]="$(seq -s, 0 60 359)" # Hue
        opt[Y]="$(seq -s, 0 5 99)"   # Lightness
        opt[Z]="20,80,100"       # Saturation
	;;
    rgb)
	opt[order]="x y z"
	opt[X]="0 51 102 153 204 255" # Red
	opt[Y]="$(seq -s, 0 15 255)"      # Green
	opt[Z]="0,128,255"            # Blue
	;;
    lch)
	opt[order]="y z x"
	opt[X]="$(seq -s, 0 60 359)" # Hue
	opt[Y]="$(seq -s, 0 5 99)"   # Luminance
	opt[Z]="20,60,100"       # Chroma
	;;
    *)
	die "$1: unknown format"
    esac
}

opt() { [[ ${opt[$1]} ]] ; }
opts() { echo ${opt[$1]} ; }
note() { [[ ${opt[quiet]} ]] && return ; echo ${1+"$@"} ; }
warn() { note ${1+"$@"} >&2; }
die() { warn ${1+"$@"}; exit 1; }

declare -a option

for key in ${!opt[@]} ${!alias[@]}
do
    [[ $key =~ ^.$ ]] || continue
    if [[ ${alias[$key]} =~ ^(.+)!$ ]]
    then
	optdef+=$key
    else
	optdef+="${key}:"
    fi
done

[[ ${opt[format]} ]] && format ${opt[format]}

while getopts "${optdef}x-:" OPT
do
    name=
    case $OPT in
	x) set -x ;;
	-)
	    if [[ $OPTARG =~ ^(no-)?([-_.a-zA-Z]+)(=(.*))? ]]
	    then
		name="${BASH_REMATCH[2]}" val="${BASH_REMATCH[4]}"
		[[ ${BASH_REMATCH[3]} ]] && val="${BASH_REMATCH[4]}" || val=yes
		[[ ${opt[$name]+_} ]] || { echo "--$name: no such option"; exit 1; }
		opt[$name]="$val"
	    else
		die "$OPTARG: unrecognized option"
	    fi
	    ;;
	*)
	    if [[ ${alias[$OPT]} =~ ^([^!]+)(!?)$ ]]
	    then
		name=${BASH_REMATCH[1]}
		opt[$name]=${OPTARG:-yes}
	    else
		opt[$OPT]=${OPTARG:-yes}
	    fi
	    ;;
    esac
    [[ $name == format ]] && format ${opt[format]}
done
shift $((OPTIND - 1))

opt pkg && export TAC_COLOR_PACKAGE=${opt[pkg]}

declare -A xyz=(
    [x]=0 [y]=1 [z]=2
    [0]=0 [1]=1 [2]=2
)
reorder() {
    local orig=(${1+"$@"}) ans p n
    for p in ${opt[order]}
    do
	n=${xyz[$p]}
	ans+=(${orig[$n]})
    done
    echo ${ans[@]}
}

table() {
    local mod=$1
    local IFS=$' \t\n,'
    Z=(${opt[Z]})
    for z in ${Z[@]}
    do
	option=(--separate $'\n')
	X=(${opt[X]})
	for x in ${X[@]}
	do
	    Y=(${opt[Y]})
	    local ys=${Y[0]} ye=${Y[$(( ${#Y[@]} - 1 ))]}
	    [[ ${opt[quiet]} ]] || option+=("x=$x,y=$ys..$ye,z=$z")
	    for y in ${opt[Y]}
	    do
		col=$(printf "%s(%03d,%03d,%03d)" ${opt[format]} $(reorder $x $y $z))
		opt reverse && arg="$col/$col$mod" \
		            || arg="$col$mod/$col"
		label="${opt[lead]}${opt[label]:-$col$mod}"
		option+=(-c "$arg" "$label")
	    done
	done
	$ansiecho "${option[@]}" | ansicolumn -C ${opt[column]:-${#X[@]}} --cu=1 --margin=0
    done
}

for mod in ${opt[mods]}
do
    table $mod
done
