#!/usr/bin/env bash

export PERL5LIB=$(pwd)/lib:$PERL5LIB

note() { [[ ${opt[quiet]} ]] && return ; echo ${1+"$@"} ; }
warn() { note ${1+"$@"} >&2 ; }
die()  { warn ${1+"$@"} ; exit 1 ; }

ansiecho=ansiecho

declare -A opt_desc=(
      [format|f:]=hsl
        [mods|m:]="+r180%y50"
         [pkg|M:]=
        [lead|l:]="██  "
             [X:]=
             [Y:]=
             [Z:]=
         [order:]=
        [terse|t]=
        [quiet|q]=
       [label|l:]=
      [reverse|r]=
      [column|C:]=
      [verbose|v]=
       [dryrun|n]=
        [debug|d]=
)
declare -A opt opt_type alias
for key in ${!opt_desc[@]}
do
    if [[ $key =~ ^([-_[:alnum:]]+)(([|][[:alnum:]])*)([:@]*)$ ]]
    then
	name=${BASH_REMATCH[1]}
	aliases=${BASH_REMATCH[2]}
	mark=${BASH_REMATCH[4]}
	opt[$name]=${opt_desc[$key]}
	opt_type[$name]=$mark
	if [[ $aliases ]]
	then
	    IFS='|' read -a _aliases <<<$aliases
	    for a in ${_aliases[@]}
	    do
		alias[$a]=$name
	    done
	fi
    else
	die "$key -- option description error"
    fi
done

format() {
   [[ $# == 0 ]] && return
    case $1 in
    hsl)
        opt[order]="x z y"
        opt[X]="$(seq -s, 0 60 359)"  # Hue
        opt[Y]="$(seq -s, 0 5 99)"    # Lightness
        opt[Z]="20,80,100"            # Saturation
	;;
    rgb)
	opt[order]="x y z"
	opt[X]="0 51 102 153 204 255" # Red
	opt[Y]="$(seq -s, 0 15 255)"  # Green
	opt[Z]="0,128,255"            # Blue
	;;
    lch)
	opt[order]="y z x"
	opt[X]="$(seq -s, 0 60 359)"  # Hue
	opt[Y]="$(seq -s, 0 5 99)"    # Luminance
	opt[Z]="20,60,100"            # Chroma
	;;
    *)
	die "$1: unknown format"
    esac
}

opt()  { [[ ${opt[$1]} ]] ; }
opts() { echo ${opt[$1]} ; }

is_single() { [[ $1 =~ ^.$ ]] ; }
#has_arg()   { [[ ! ${alias[$1]} =~ ! ]] ; }
has_arg()   {
    local alias=${alias[$1]}
    if [[ $alias ]]
    then
	[[ ${opt_type[${alias[$1]}]} ]]
    else
	[[ ${opt_type[$1]} ]]
    fi
}

for key in ${!opt[@]} ${!alias[@]}
do
    is_single $key || continue
    if has_arg $key
    then
	optdef+="${key}:"
    else
	optdef+=$key
    fi
done

opt format && format $(opts format)

while getopts "${optdef}x-:" OPT
do
    name=
    case $OPT in
	x) set -x ;;
	-)
	    [[ $OPTARG =~ ^(no-?)?([-_[:alnum:]]+)(=(.*))? ]] \
		|| die "$OPTARG: unrecognized option"
	    neg="${BASH_REMATCH[1]}" name="${BASH_REMATCH[2]}" param="${BASH_REMATCH[3]}" val="${BASH_REMATCH[4]}"
	    [[ ${opt[$name]+_} ]] || { die "--$name: no such option"; }
	    if [[ ! $param ]]
	    then
		if [[ ${opt_type[$name]} == : ]]
		then
		    (( OPTIND <= $# )) || die "option requires an argument -- $name"
		    val=${@:$((OPTIND)):1}
		    (( OPTIND++ ))
		else
		    [[ $neg ]] && val= || val=yes ;
		fi
	    fi
	    opt[$name]="$val"
	    ;;
	*)
	    if [[ ! ${alias[$OPT]} ]]
	    then
		opt[$OPT]=${OPTARG:-yes}
	    else
		if [[ ${alias[$OPT]} =~ ^(.+)!$ ]]
		then
		    name=${BASH_REMATCH[1]}
		    opt[$name]=${OPTARG:-yes}
		else
		    name=${alias[$OPT]}
		    opt[$name]=${OPTARG:-yes}
		fi
	    fi
	    ;;
    esac
    [[ $name == format ]] && format ${opt[format]}
done
shift $((OPTIND - 1))

opt debug && declare -p opt opt_type alias

opt pkg && export TAC_COLOR_PACKAGE=${opt[pkg]}

declare -A xyz=(
    [x]=0 [y]=1 [z]=2
    [0]=0 [1]=1 [2]=2
)
reorder() {
    local orig=(${1+"$@"}) ans p n
    for p in $(opts order)
    do
	n=${xyz[$p]}
	ans+=(${orig[$n]})
    done
    echo ${ans[@]}
}

table() {
    local mod=$1
    local IFS=$' \t\n,'
    Z=($(opts Z))
    for z in ${Z[@]}
    do
	local option=(--separate $'\n')
	X=($(opts X))
	for x in ${X[@]}
	do
	    Y=($(opts Y))
	    local ys=${Y[0]} ye=${Y[$(( ${#Y[@]} - 1 ))]}
	    opt terse || option+=("x=$x,y=$ys..$ye,z=$z")
	    for y in ${Y[@]}
	    do
		col=$(printf "%s(%03d,%03d,%03d)" ${opt[format]} $(reorder $x $y $z))
		opt reverse && arg="$col/$col$mod" \
		            || arg="$col$mod/$col"
		label="${opt[lead]}${opt[label]:-$col$mod}"
		option+=(-c "$arg" "$label")
	    done
	done
	if opt dryrun
	then
	    echo ansiecho "${option[@]}"
	else
	    $ansiecho "${option[@]}" | ansicolumn -C ${opt[column]:-${#X[@]}} --cu=1 --margin=0
	fi
    done
}

for mod in $(IFS=, opts mods)
do
    table $mod
done
