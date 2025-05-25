#!/usr/bin/env bash

################################################################################
################################################################################
##
## TECOLI Getopt Library for Bash Script
##
################################################################################
################################################################################

tgl_warn() { echo "$@" >&2 ; }
tgl_die()  { tgl_warn "$@" ; exit 1 ; }
tgl_dump() {
    local declare="$(declare -p TGL_OPTS)"
    if [[ "$declare" =~ \"(.+)\" ]]
    then
	declare -p ${BASH_REMATCH[1]} | grep -o -E '\[[^]]*\]="[^"]*"' | sort
    fi
}
tgl_setup() {
    declare -A TGL_CONFIG=(
	[SILENT]=
	[TRUE]=yes
	[FALSE]=
	[EXIT_ON_ERROR]=yes
	[DEBUG]=
    )
    if (( $# == 0 ))
    then
	echo 'local TGL_OPTS OPTIND=1'
    else
	TGL_OPTS=$1
	tgl_setup_ "$@"
    fi
}
tgl_setup_() {
    declare -n _opts=$1; shift

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
    ##
    ## set config parameters
    ##
    for key in "${!TGL_CONFIG[@]}"
    do
	_opts["&$key"]=${TGL_CONFIG[$key]}
    done
    (( $# > 0 )) && tgl_configure "$@"
    return 0
}
tgl_redirect() {
    declare -n _opts=$TGL_OPTS
    [[ ${_opts[&DEBUG]} ]] && { echo "DEBUG: ${FUNCNAME[1]}($@)" ; }
    "${FUNCNAME[1]}_" $TGL_OPTS "$@"
}
tgl_configure () { tgl_redirect "$@" ; }
tgl_configure_() {
    declare -n _opts=$1; shift
    for param in "$@"
    do
	[[ $param =~ ^[[:alnum:]] ]] || tgl_die "$param -- invalid config parameter"
	local key val
	if [[ $param =~ = ]]
	then
	    key="&${param%%=*}"
	    val="${param#*=}"
	else
	    key="&${param}"
	    val="${_opts[&TRUE]}"
	fi
	if [[ ${_opts[$key]+_} ]]
	then
	    _opts[$key]="$val"
	else
	    tgl_die "$param -- invalid config parameter"
	fi
    done
    return 0
}
tgl_string () { tgl_redirect "$@" ; }
tgl_string_() {
    declare -n _opts=$1; shift
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
#   [[ ${_opts[&SILENT]} ]] && string=":$string"
#   string+="-:"
#   echo "${string}"
    echo "${_opts[&SILENT]+:}${string}-:"
}
tgl_getopts () { tgl_redirect "$@" ; }
tgl_getopts_() {
    declare -n _opts=$1; shift
    local opt="$1"; shift;
    local name val type
    case $opt in
    :|\?)
	[[ ${_opts[!$opt]} ]] && ${_opts[!$opt]} "$OPTARG"
	[[ ${_opts[&EXIT_ON_ERROR]} ]] && exit 1
	return
	;;
    -)
	[[ $OPTARG =~ ^(no-?)?([-_[:alnum:]]+)(=(.*))? ]] \
	    || die "$OPTARG: unrecognized option"
	local    no="${BASH_REMATCH[1]}"
	local _name="${BASH_REMATCH[2]}"
	local param="${BASH_REMATCH[3]}"
		val="${BASH_REMATCH[4]}"
	name=${_opts[=$_name]:-$_name}
	[[ ${_opts[$name]+_} ]] || { tgl_die "--$name: no such option" ; }
	if [[ ! $param ]]
	then
	    type=${_opts[:$name]}
	    case  $type in
	    [:@])
		(( OPTIND > $# )) && tgl_die "option requires an argument -- $name"
		val=${@:$((OPTIND)):1}
		(( OPTIND++ ))
		;;
	    *)
		[[ $no ]] && val=${_opts[&FALSE]} || val=${_opts[&TRUE]}
		;;
	    esac
	fi
	;;
    *)
	name=${_opts[=$opt]:-$opt}
	type=${_opts[:$name]}
	case $type in
	[:@])
	    val="${OPTARG}"
	    ;;
	*)
	    val=${_opts[&TRUE]}
	    ;;
	esac
	;;
    esac
    case $type in
    @) val="${_opts[$name]+${_opts[$name]} }${OPTARG}" ;;
    esac
    _opts[$name]="$val"
    [[ ${_opts[!$name]} ]] && ${_opts[!$name]} "$val"
    return 0
}
tgl_callback () { tgl_redirect "$@" ; }
tgl_callback_() {
    declare -n _opts=$1; shift
    declare -a config=("$@")
    while (($# > 0))
    do
	local name=$1 callback=${2:-$1}
	[[ $callback == - ]] && callback=$name
	_opts[!$name]="$callback"
	shift $(( $# >= 2 ? 2 : 1 ))
    done
    return 0
}
tgl_getoptions () { tgl_redirect "$@" ; }
tgl_getoptions_() {
    declare -n _opts=$1; shift
    local OPT optstring="$(tgl_string)"
    while getopts "$optstring" OPT
    do
	tgl_getopts "$OPT" "$@"
    done
}

################################################################################
################################################################################
################################################################################
################################################################################

set -e

define() { IFS='\n' read -r -d '' ${1} || true ; }

myname="${0##*/}"

define pod <<"=cut"

=encoding utf-8

=head1 NAME

    ... - Term::ANSIColor::Concise demo/test script

=head1 SYNOPSIS

    ... [ options ]

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
        -M # , --pkg       select color handling package
        -I # , --include   include Perl module path

=cut

note()   { opt quiet && return ; echo "$@" ; }
warn()   { note "$@" >&2 ; }
die()    { warn "$@" ; exit 1 ; }

help() {
    eval $(tgl_setup)
    declare -A OPTS=(
	[      man|m ]=
       	[     help|h ]=
       	[    usage|u ]=
       	[ continue|c ]=
    )
    tgl_setup OPTS
    tgl_getoptions "$@"
    shift $((OPTIND - 1))
    if [[ ${OPTS[man]} ]]
    then
	perldoc $0
    else
	sed -r \
	    -e '/^$/N' \
	    -e '/^\n*(#|=encoding)/d' \
	    -e 's/^(\n*)=[a-z]+[0-9]* */\1/' \
	    -e '/Version/q' \
	    <<< $pod
    fi
    [[ $1 && ! ${OPTS[continue]} ]] && exit 0
    return 0
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
    [   usage | u   ]=
    [     man       ]=
    [ include | I : ]=./lib
)
tgl_setup OPTS EXIT_ON_ERROR DEBUG=
tgl_callback help  'help --help'
tgl_callback man   'help --man'
tgl_callback usage 'help --usage'

opt()   { [[ ${OPTS[$1]} ]] ; }
type()  { echo ${OPTS[:$1]} ; }
opts()  { echo ${OPTS[$1]} ; }

trace() { [[ $1 ]] && set -x || set +x ; }
tgl_callback trace -

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
    rgb-chart)
	OPTS[format]=rgb
	OPTS[order]="x y z"
	OPTS[X]="$(seq -s, 0 2 255)"   # Red
	OPTS[Y]="$(seq -s, 0 15 255)"  # Green
	OPTS[Z]="0,128,255"            # Blue
	OPTS[label]=" "
	OPTS[terse]=yes
	OPTS[lead]=
	OPTS[mod]=";"
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
tgl_callback format -
opt format && format $(opts format)

tgl_getoptions "$@"
shift $((OPTIND - 1))

opt pkg     && export TAC_COLOR_PACKAGE=${OPTS[pkg]}
opt include && export PERL5LIB=${OPTS[include]}:$PERL5LIB
opt debug   && tgl_dump | column

declare -A xyz=(
    [x]=0 [y]=1 [z]=2
    [0]=0 [1]=1 [2]=2
)
reorder() {
    local orig=("$@") ans p n
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
