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
tgl_opts() {
    (($# == 2)) && { _opts["$1"]="$2" ; return 0 ; }
    [[ -v _opts[$1] ]] && echo "${_opts[$1]}" || return 1
}
tgl_conf()  { tgl_opts \&"$1" "${@:2}" ; }
tgl_type()  { tgl_opts \:"$1" "${@:2}" ; }
tgl_alias() { tgl_opts \="$1" "${@:2}" ; }
tgl_hook()  { tgl_opts \!"$1" "${@:2}" ; }
tgl_debug() { [[ ${_opts["&DEBUG"]} ]] || return 0; tgl_warn DEBUG: "$@" ; }
tgl_dump() {
    local declare="$(declare -p TGL_OPTS)"
    if [[ "$declare" =~ \"(.+)\" ]] ; then
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
	[SAVETO]=
	[MARKS]=':=!&' [IS_TYPE]=':' [IS_ALIAS]='=' [IS_CALLBACK]='!' [IS_CONF]='&'
	[TYPES]=':@+' [TYPE_ARGS]=':@' [TYPE_ARG]=':' [TYPE_ARRAY]='@' [TYPE_INCR]='+'
    )
    if (( $# == 0 )) ; then
	echo 'local TGL_OPTS OPTIND=1'
    else
	TGL_OPTS=$1
	tgl_setup_ "$@"
    fi
}
tgl_setup_() {
    declare -n _opts=$1; shift
    # set default config parameters
    for key in "${!TGL_CONFIG[@]}" ; do tgl_conf "$key" "${TGL_CONFIG[$key]}" ; done
    local key marks="$(tgl_conf MARKS)" type_array=$(tgl_conf TYPE_ARRAY)
    local types=$(tgl_conf TYPES)
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[$marks] ]] && continue
	if [[ $key =~ ^([-_ \|[:alnum:]]+)([$types]*)( *)$ ]] ; then
	    local names=${BASH_REMATCH[1]}
	    local type=${BASH_REMATCH[2]}
	    local aliases alias
	    IFS=' |' read -a aliases <<<$names
	    local name=${aliases[0]}
	    tgl_type "$name" "$type"
	    for alias in "${aliases[@]:1}" ; do
		tgl_alias "$alias" "$name"
		tgl_type  "$alias" "$type"
	    done
	    case $type in
		$type_array)
		    declare -n array=$name
		    [[ ${_opts[$key]} ]] && array=("${_opts[$key]}") || array=()
		    ;;
		*) 
		    [[ $name != $key ]] && _opts[$name]=${_opts[$key]}
		    ;;
	    esac
	else
	    tgl_warn "[$key] -- option description error"
	    exit 1
	fi
    done
    (( $# > 0 )) && tgl_configure "$@"
    return 0
}
tgl_redirect() {
    declare -n _opts=$TGL_OPTS
    tgl_debug "${FUNCNAME[1]}($@)"
    "${FUNCNAME[1]}_" $TGL_OPTS "$@"
}
tgl_configure () { tgl_redirect "$@" ; }
tgl_configure_() {
    declare -n _opts=$1; shift
    for param in "$@" ; do
	[[ $param =~ ^[[:alnum:]] ]] || tgl_die "$param -- invalid config parameter"
	local key val
	if [[ $param =~ = ]] ; then
	    key="&${param%%=*}"
	    val="${param#*=}"
	else
	    key="&${param}"
	    val="$(tgl_conf TRUE)"
	fi
	if [[ ${_opts[$key]+_} ]] ; then
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
    local key string mark=$(tgl_conf IS_TYPE)
    local type_args="$(tgl_conf TYPE_ARG)$(tgl_conf TYPE_ARRAY)"
    for key in ${!_opts[@]} ; do
	[[ $key =~ ^${mark}.$ ]] || continue
	[[ ${_opts[$key]} =~ [$type_args] ]] && string+="${key#:}:" || string+=${key#:}
    done
    [[ $(tgl_conf SILENT) ]] && string=":$string"
    string+="-:"
    tgl_debug "Return $string"
    echo "$string"
}
tgl_getopts () { tgl_redirect "$@" ; }
tgl_getopts_() {
    declare -n _opts=$1; shift
    local opt="$1"; shift;
    local name val type
    local type_args="$(tgl_conf TYPE_ARGS)" \
          type_arg="$(tgl_conf TYPE_ARG)" type_array="$(tgl_conf TYPE_ARRAY)" type_incr=$(tgl_conf TYPE_INCR)
    case $opt in
	[:?])
	    local hook=$(tgl_hook "$opt")
	    [[ $hook ]] && $hook "$OPTARG"
	    [[ $(tgl_conf EXIT_ON_ERROR) ]] && exit 1
	    return 0
	    ;;
	-)
	    [[ $OPTARG =~ ^(no-?)?([-_[:alnum:]]+)(=(.*))? ]] \
		|| die "$OPTARG: unrecognized option"
	    local    no="${BASH_REMATCH[1]}"
	    local _name="${BASH_REMATCH[2]}"
	    local param="${BASH_REMATCH[3]}"
		    val="${BASH_REMATCH[4]}"
	    name=$(tgl_alias $_name) || name=$_name
	    type=$(tgl_type $name)
	    [[ -v _opts[$name] ]] || tgl_die "--$name: no such option"
	    if [[ ! $param ]] ; then
		case $type in
		    $type_incr)
			val=$(( _opts[$name] + 1 )) ;;
		    $type_args)
			(( OPTIND > $# )) && tgl_die "option requires an argument -- $name"
			val=${@:$((OPTIND)):1}
			(( OPTIND++ ))
			;;
		    *)
			[[ $no ]] && val=$(tgl_conf FALSE) || val=$(tgl_conf TRUE)
			;;
		esac
	    fi
	    ;;
	*)
	    name=$(tgl_alias $opt) || name=$opt
	    case ${type:=$(tgl_type "$name")} in
		[$type_incr])
		    val=$(( _opts[$name] + 1 )) ;;
		[$type_args])
		    val="${OPTARG}" ;;
		*)
		    val=$(tgl_conf TRUE) ;;
	    esac
	    ;;
    esac
    case $type in
	[$type_array])
	    declare -n array=${_opts[@$name]:-$name}; array+=($val) ;;
	*)
	    _opts[$name]="$val" ;;
    esac
    # callback
    local callback
    callback="$(tgl_hook $name)" && $callback "$val"
    return 0
}
tgl_callback () { tgl_redirect "$@" ; }
tgl_callback_() {
    declare -n _opts=$1; shift
    declare -a config=("$@")
    while (($# > 0)) ; do
	local name=$1 callback=${2:-$1}
	[[ $callback == - ]] && callback=$name
	tgl_hook "$name" "$callback"
	shift $(( $# >= 2 ? 2 : 1 ))
    done
    return 0
}
tgl_getoptlong () { tgl_redirect "$@" ; }
tgl_getoptlong_() {
    declare -n _opts=$1; shift
    local OPT optstring="$(tgl_string)"
    while getopts "$optstring" OPT ; do
	tgl_getopts "$OPT" "$@"
    done
    shift $(( OPTIND - 1 ))
    [[ ${_opts[&DEBUG]} ]] && echo "DEBUG: ARGV=$@"
    # save result
    local array="$(tgl_conf SAVETO)"
    [[ $array ]] && { declare -n argv=$array ; argv=("$@") ; }
    return 0
}

################################################################################
################################################################################
################################################################################
################################################################################

set -eu

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
    tgl_getoptlong "$@"
    shift $((OPTIND - 1))
    if [[ ${OPTS[man]} ]] ; then
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
    [ default | D : ]="+r180%y50"
    [    mods | m @ ]=
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
    [   debug | d + ]=
    [   trace | x   ]=
    [    help | h   ]=
    [   usage | u   ]=
    [     man       ]=
    [ include | I : ]=./lib
)
tgl_setup OPTS EXIT_ON_ERROR DEBUG=1 SAVETO=ARGV
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

tgl_getoptlong "$@"
# shift $((OPTIND - 1))
set -- "${ARGV[@]}"

opt pkg     && export TAC_COLOR_PACKAGE=${OPTS[pkg]}
opt include && export PERL5LIB=${OPTS[include]}:$PERL5LIB
opt debug   && tgl_dump | column

declare -A xyz=(
    [x]=0 [y]=1 [z]=2
    [0]=0 [1]=1 [2]=2
)
reorder() {
    local orig=("$@") ans p n
    for p in $(opts order) ; do
	n=${xyz[$p]}
	ans+=(${orig[$n]})
    done
    echo ${ans[@]}
}

table() {
    local mod=$1
    local IFS=$' \t\n,'
    Z=($(opts Z))
    for z in ${Z[@]} ; do
	local option=(--separate $'\n')
	X=($(opts X))
	for x in ${X[@]} ; do
	    Y=($(opts Y))
	    local ys=${Y[0]} ye=${Y[$(( ${#Y[@]} - 1 ))]}
	    opt terse || option+=("x=$x,y=$ys-$ye,z=$z")
	    for y in ${Y[@]} ; do
		col=$(printf "%s(%03d,%03d,%03d)" ${OPTS[format]} $(reorder $x $y $z))
		opt reverse && arg="$col/$col$mod" \
		            || arg="$col$mod/$col"
		label="${OPTS[lead]}${OPTS[label]:-$col$mod}"
		option+=(-c "$arg" "$label")
	    done
	done
	if opt dryrun ; then
	    echo ansiecho "${option[@]}"
	else
	    ansiecho "${option[@]}" | ansicolumn -C ${OPTS[column]:-${#X[@]}} --cu=1 --margin=0
	fi
    done
}

(( $# > 0 )) && echo "$@"
[[ ${#mods[@]} == 0 ]] && mods=(${OPTS[default]})

for mod in "${mods[@]}" ; do
    table $mod
done
