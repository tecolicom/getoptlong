#!/usr/bin/env bash

################################################################################
################################################################################
##
## TECOLI Getopt Library for Bash Script
##
################################################################################
################################################################################

tgl_warn() { echo ${1+"$@"} >&2 ; }
tgl_die()  { tgl_warn ${1+"$@"} ; exit 1 ; }
tgl_dump() {
    declare -p $1 \
    | perl -nE 'say(${^MATCH})while/\[(".*?"|.)*?\]=".*?"/pg' \
    | sort
}
tgl_setup() {
    declare -n _opts=$1
    local key

    for key in "${!_opts[@]}"
    do
	[[ $key =~ ^[:@=] ]] && continue
	if [[ $key =~ ^([-_ \|[:alnum:]]+)([:@]*)( *)$ ]]
	then
	    local names=${BASH_REMATCH[1]}
	    local type=${BASH_REMATCH[2]}
	    local aliases alias
	    IFS=' |' read -a aliases <<<$names
	    local name=${aliases[0]}
	    [[ $name != $key ]] && _opts[$name]=${_opts[$key]}
	    _opts[:$name]=$type
	    for alias in "${aliases[@]:1}"
	    do
		_opts[=$alias]=$name
		_opts[:$alias]=$type
	    done
	else
	    tgl_warn "[$key] -- option description error"
	    exit 1
	fi
    done
}
tgl_string() {
    declare -n _opts=$1
    local key string
    for key in ${!_opts[@]}
    do
	[[ $key =~ ^:.$ ]] || continue
	if [[ ${_opts[$key]} == : ]]
	then
	    string+="${key#:}:"
	else
	    string+=${key#:}
	fi
    done
    string+="-:"
    echo "${string}"
}
tgl_getopts() {
    declare -n _opts=$1; shift
    local opt="$1"; shift;
    local name val
    case $opt in
	-)
	    [[ $OPTARG =~ ^(no-?)?([-_[:alnum:]]+)(=(.*))? ]] \
		|| die "$OPTARG: unrecognized option"
	    local    no="${BASH_REMATCH[1]}"
	    local _name="${BASH_REMATCH[2]}"
	    local param="${BASH_REMATCH[3]}"
	            val="${BASH_REMATCH[4]}"
	    name=${_opts[=$_name]:-$_name}
	    [[ ${_opts[$name]+_} ]] || { tgl_die "--$name: no such option"; }
	    if [[ ! $param ]]
	    then
		if [[ ${_opts[:$name]} == : ]]
		then
		    (( OPTIND > $# )) && tgl_die "option requires an argument -- $name"
		    val=${@:$((OPTIND)):1}
		    (( OPTIND++ ))
		else
		    [[ $no ]] && val= || val=yes ;
		fi
	    fi
	    ;;
	*)
	    name=${_opts[=$opt]:-$opt}
	    val=${OPTARG:-yes}
	    ;;
    esac
    _opts[$name]="$val"
    [[ ${_opts[!$name]} ]] && ${_opts[!$name]} "$val"
}
tgl_hook() {
    declare -n _opts=$1; shift
    while (($# >= 2))
    do
	_opts[!$1]="$2"
	shift 2
    done
}

################################################################################
################################################################################
################################################################################
################################################################################

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

note()   { opt quiet && return ; echo ${1+"$@"} ; }
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

declare -A OPTS=(
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
    [   trace | x   ]=
    [    help | h   ]=
    [ include | I : ]=./lib
)
tgl_setup OPTS
tgl_hook  OPTS format format trace trace

opt()   { [[ ${OPTS[$1]} ]] ; }
type()  { echo ${OPTS[:$1]} ; }
opts()  { echo ${OPTS[$1]} ; }
trace() { [[ $1 ]] && set -x || set +x ; }

format() {
   [[ $# == 0 ]] && return
    case $1 in
    hsl)
        OPTS[order]="x z y"
        OPTS[X]="$(seq -s, 0 60 359)"  # Hue
        OPTS[Y]="$(seq -s, 0 5 99)"    # Lightness
        OPTS[Z]="20,80,100"            # Saturation
	;;
    rgb)
	OPTS[order]="x y z"
	OPTS[X]="0 51 102 153 204 255" # Red
	OPTS[Y]="$(seq -s, 0 15 255)"  # Green
	OPTS[Z]="0,128,255"            # Blue
	;;
    lch)
	OPTS[order]="y z x"
	OPTS[X]="$(seq -s, 0 60 359)"  # Hue
	OPTS[Y]="$(seq -s, 0 5 99)"    # Luminance
	OPTS[Z]="20,60,100"            # Chroma
	;;
    *)
	die "$1: unknown format"
    esac
}

opt format && format $(opts format)

opt_string=$(tgl_string OPTS)
while getopts ${opt_string} myOPT
do
    tgl_getopts OPTS $myOPT "$@"
done
shift $((OPTIND - 1))

opt help && { help; exit 0; }

if opt include
then
    export PERL5LIB=${OPTS[include]}:$PERL5LIB
fi

opt debug && tgl_dump OPTS | column

opt pkg && export TAC_COLOR_PACKAGE=${OPTS[pkg]}

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
		col=$(printf "%s(%03d,%03d,%03d)" ${OPTS[format]} $(reorder $x $y $z))
		opt reverse && arg="$col/$col$mod" \
		            || arg="$col$mod/$col"
		label="${OPTS[lead]}${OPTS[label]:-$col$mod}"
		option+=(-c "$arg" "$label")
	    done
	done
	if opt dryrun
	then
	    echo ansiecho "${option[@]}"
	else
	    ansiecho "${option[@]}" | ansicolumn -C ${OPTS[column]:-${#X[@]}} --cu=1 --margin=0
	fi
    done
}

for mod in $(IFS=, opts mods)
do
    table $mod
done
