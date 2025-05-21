#!/usr/bin/env bash

export PERL5LIB=$(pwd)/lib:$PERL5LIB

ansiecho=ansiecho

declare -A opt=(
    [model]=hsl
      [mod]=
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
    [r]=reverse!
    [q]=quiet!
    [l]=label
    [o]=order
    [M]=mod
    [m]=model
    [v]=verbose!
    [d]=debug!
)

model() {
    case $1 in
    hsl)
        opt[order]="y x z"
        opt[X]="20 80 100"       # Saturation
        opt[Y]="$(seq 0 60 359)" # Hue
        opt[Z]="$(seq 0 5 99)"   # Lightness
	;;
    rgb)
	opt[order]="x y z"
	opt[X]="0 128 255"            # Red
	opt[Y]="0 51 102 153 204 255" # Green
	opt[Z]="$(seq 0 15 255)"      # Blue
	;;
    lch)
	opt[order]="z x y"
	opt[X]="20 60 100"       # Chroma
	opt[Y]="$(seq 0 60 359)" # Hue
	opt[Z]="$(seq 0 5 99)"   # Luminance
	;;
    *)
	die "$1: unknown model"
    esac
}

opt() { [[ ${opt[$1]} ]] ; }
opts() { echo ${opt[$1]} ; }
warn() {
    [[ ${opt[quiet]} ]] && return
    echo ${1+"$@"} >&2
}
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

[[ ${opt[model]} ]] && model ${opt[model]}

while getopts "${optdef}x-:" OPT
do
    name=
    case $OPT in
	-)
	    if [[ $OPTARG =~ ^([-_.a-zA-Z]+)(=(.*))? ]]
	    then
		name="${BASH_REMATCH[1]}" val="${BASH_REMATCH[3]}"
		[[ ${BASH_REMATCH[2]} ]] && val="${BASH_REMATCH[3]}" || val=yes
		[[ ${opt[$name]+_} ]] || { echo "--$name: no such option"; exit 1; }
		opt[$name]="$val"
	    else
		die "$OPTARG: unrecognized option"
	    fi
	    ;;
	x) set -x ;;
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
    [[ $name == model ]] && model ${opt[model]}
done
shift $((OPTIND - 1))

opt mod && export TAC_COLOR_PACKAGE=${opt[mod]}

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
    for x in ${opt[X]}
    do
	option=(--separate $'\n')
	for y in ${opt[Y]}
	do
	    [[ ${opt[quiet]} ]] || option+=("(x=$x, y=$y)")
	    for z in ${opt[Z]}
	    do
		col=$(printf "%s(%03d,%03d,%03d)" ${opt[model]} $(reorder $x $y $z))
		opt reverse && arg="$col/$col$mod" \
		            || arg="$col$mod/$col"
		label="${opt[lead]}${opt[label]:-$col$mod}"
		option+=(-c "$arg" "$label")
	    done
	done
	Y=(${opt[Y]})
	$ansiecho "${option[@]}" | ansicolumn -C ${opt[column]:-${#Y[@]}} --cu=1 --margin=0
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
