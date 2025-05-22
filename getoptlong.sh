#!/usr/bin/env bash

set -e

define() { IFS='\n' read -r -d '' ${1} || true ; }

myname="${0##*/}"

define pod <<"=cut"

=encoding utf-8

=head1 NAME

    noname - Term::ANSIColor::Concise demo/test script

=head1 SYNOPSIS

    noname [ options ]

        -f # , --format    specify color format (*hsl, rgb, lch)
        -m # , --mod       set color modifier (ex. +r180%y50)
        -r   , --reverse   flip foreground/background color
        -l # , --lead      set leader string
        -l # , --label     set label string
        -C # , --column    set column number
        -o # , --order     set X,Y,Z order
        -[XYZ] #           set X,Y,Z values

        -h   , --help      show help
        -d   , --debug     debug
        -n   , --dryrun    dry-run
        -t   , --terse     terse message
        -q   , --quiet     quiet mode
        -v   , --verbose   verbose mode
        -I # , --include   include Perl module path

=cut

note()   { [[ ${opt[quiet]} ]] && return ; echo ${1+"$@"} ; }
warn()   { note ${1+"$@"} >&2 ; }
die()    { warn ${1+"$@"} ; exit 1 ; }

help() {
    sed -r \
	-e '/^$/N' \
	-e '/^\n*(#|=encoding)/d' \
	-e 's/^(\n*)=[a-z]+[0-9]* */\1/' \
	-e '/Version/q' \
	<<< $pod
}

ansiecho=ansiecho

is_single() { [[ $1 =~ ^.$ ]] ; }
has_arg()   {
    local alias=${alias[$1]}
    if [[ $alias ]]
    then
	[[ ${opt_type[${alias[$1]}]} ]]
    else
	[[ ${opt_type[$1]} ]]
    fi
}

opt_setup() {
    declare -n _desc=$1 _table=$2 _type=$3 _alias=$4
    local key

    for key in "${!_desc[@]}"
    do
	if [[ $key =~ ^([-_ \|[:alnum:]]+)([:@]*)( *)$ ]]
	then
	    local names=${BASH_REMATCH[1]}
	    local type=${BASH_REMATCH[2]}
	    local _names a
	    IFS=' |' read -a _names <<<$names
	    local name=${_names[0]}
	    _table[$name]=${_desc[$key]}
	    _type[$name]=$type
	    for a in "${_names[@]:1}"
	    do
		_alias[$a]=$name
		_type[$a]=$type
	    done
	else
	    die "[$key] -- option description error"
	fi
    done
}
opt_string() {
    declare -n _desc=$1 _table=$2 _type=$3 _alias=$4
    local string
    for key in ${!_table[@]} ${!_alias[@]}
    do
	[[ $key =~ ^.$ ]] || continue
	if [[ ${_type[$key]} == : ]]
	then
	    string+="${key}:"
	else
	    string+=$key
	fi
    done
    echo $string
}
opt_longopt() {
    declare -n _table=$1 _type=$2 _alias=$3 _argv=$4
    [[ $OPTARG =~ ^(no-?)?([-_[:alnum:]]+)(=(.*))? ]] \
	|| die "$OPTARG: unrecognized option"
    local \
	neg="${BASH_REMATCH[1]}" \
	name="${BASH_REMATCH[2]}" \
	param="${BASH_REMATCH[3]}" \
	val="${BASH_REMATCH[4]}"
    [[ ${_table[$name]+_} ]] || { die "--$name: no such option"; }
    if [[ ! $param ]]
    then
	if [[ ${_type[$name]} == : ]]
	then
	    (( OPTIND <= ${#_argv[@]} )) || die "option requires an argument -- $name"
	    val=${_argv[$((OPTIND-1))]}
	    (( OPTIND++ ))
	else
	    [[ $neg ]] && val= || val=yes ;
	fi
    fi
    _table[$name]="$val"
}
opt_singleopt() {
    declare -n _table=$1 _type=$2 _alias=$3 _argv=$4
    local alias=${_alias[$OPT]}
    if [[ ! $alias ]]
    then
	opt[$OPT]=${OPTARG:-yes}
    else
	opt[$alias]=${OPTARG:-yes}
    fi
}

declare -A opt_desc=(
    [  format | f : ]=hsl
    [    mods | m : ]="+r180%y50"
    [     pkg | M : ]=
    [    lead | l : ]="██  "
    [           X : ]=
    [           Y : ]=
    [           Z : ]=
    [   order | o : ]=
    [   terse | t   ]=
    [   quiet | q   ]=
    [   label | l : ]=
    [ reverse | r   ]=
    [  column | C : ]=
    [ verbose | v   ]=
    [  dryrun | n   ]=
    [   debug | d   ]=
    [    help | h   ]=
    [ include | I   ]=./lib
)
declare -A opt opt_type alias
opt_setup opt_desc opt opt_type alias
opt_string=$(opt_string opt_desc opt opt_type alias)

opt()  { [[ ${opt[$1]} ]] ; }
opts() { echo ${opt[$1]} ; }

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

opt format && format $(opts format)

#
# 引数として与えられた連想配列に、残りの要素の前半をキー、後半を値として設定する
#
zipto() {
    declare -n ref=$1; shift
    local param=("$@") half=$((${#param[@]} / 2))
    for ((i = 0; i < $half; i++))
    do
	ref["${param[$i]}"]="${param[$((i+half))]}"
    done
}

ARGV=(${1+"$@"})
while getopts "${opt_string}x-:" OPT
do
    old_format=${opt[format]}
    case $OPT in
	x) set -x ;;
	-) opt_longopt   opt opt_type alias ARGV ;;
	*) opt_singleopt opt opt_type alias ARGV ;;
    esac
    [[ ${opt[format]} != $old_format ]] && format ${opt[format]}
done
shift $((OPTIND - 1))

opt help && { help; exit 0; }

if opt include
then
    export PERL5LIB=${opt[include]}:$PERL5LIB
fi

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
	    opt terse || option+=("x=$x,y=$ys-$ye,z=$z")
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
