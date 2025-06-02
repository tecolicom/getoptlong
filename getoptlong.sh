################################################################################
################################################################################
##
## GetOptLong: Getopt Library for Bash Script
##
################################################################################
################################################################################
_gol_warn() { echo "$@" >&2 ; }
_gol_die()  { _gol_warn "$@" ; exit 1 ; }
_gol_opts() {
    (($# == 2)) && { _opts["$1"]="$2" ; return 0 ; }
    [[ -v _opts[$1] ]] && echo "${_opts[$1]}" || return 1
}
_gol_alias() { _gol_opts \~"$1" "${@:2}" ; }
_gol_hook()  { _gol_opts \!"$1" "${@:2}" ; }
_gol_check() { _gol_opts \="$1" "${@:2}" ; }
_gol_debug() { [[ ${_opts["&DEBUG"]:-} ]] && _gol_warn DEBUG: "${@}" || : ; }
_gol_incr()  { [[ $1 =~ ^[0-9]+$ ]] && echo $(( $1 + 1 )) || echo 1 ; }
_gol_validate() {
    case $1 in
	i)   [[ "$2" =~ ^[-+]?[0-9]+$ ]]            || _gol_die "$2: not an integer" ;;
	f)   [[ "$2" =~ ^[-+]?[0-9]+(\.[0-9]*)?$ ]] || _gol_die "$2: not a number" ;;
	\(*) eval "[[ $2 =~ $1 ]]"                  || _gol_die "$2: invalid argument" ;;
	*)   _gol_die "$1: unkown validation pattern" ;;
    esac
}
_gol_redirect() { local name ;
    declare -n _opts=$GOL_OPTHASH
    declare -n MATCH=BASH_REMATCH
    _gol_debug "${FUNCNAME[1]}(${@@Q})"
    local MARKS='~!&=' MK_ALIAS='~' MK_HOOK='!' MK_CONF='&' MK_TYPE='=' \
	  IS_ANY=':@%+?' IS_NEED=":@%" IS_WANT=":" IS_FREE="?" IS_ARRAY="@" IS_HASH="%" IS_INCR="+"
    local CONFIG=(EXIT_ON_ERROR SILENT PERMUTE DEBUG PREFIX)
    for name in "${CONFIG[@]}" ; do declare $name="${_opts[&$name]}" ; done
    "${FUNCNAME[1]}_" "$@"
}
gol_dump() {
    declare -p $GOL_OPTHASH | grep -oE '\[[^]]*\]="[^"]*"' | sort
}
gol_init() { local key ;
    (( $# == 0 )) && { echo 'local GOL_OPTHASH OPTIND=1' ; return ; }
    declare -n _opts=$1
    declare -A GOL_CONFIG=([PERMUTE]=GOL_ARGV [EXIT_ON_ERROR]=1 [PREFIX]= [SILENT]= [DEBUG]=)
    for key in "${!GOL_CONFIG[@]}" ; do _opts[&$key]="${GOL_CONFIG[$key]}" ; done
    GOL_OPTHASH=$1
    (( $# > 1 )) && gol_configure "${@:2}"
    _gol_redirect
}
################################################################################
gol_init_() { local key aliases alias ;
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[$MARKS] ]] && continue
	[[ $key =~ ^([-_ \|[:alnum:]]+)([$IS_ANY]*)( *)(=([if]|\(.*\)))?( *)(#.*)?$ ]] \
	    || _gol_die "[$key] -- invalid"
	local names=${MATCH[1]} dtype=${MATCH[2]} type=${MATCH[5]} comment=${MATCH[7]}
	local initial="${_opts[$key]}"
	IFS=' |' read -a aliases <<<$names
	local name=${aliases[0]}
	local dname="${PREFIX}${name}"
	declare -n target=$dname
	unset _opts["$key"]
	case ${dtype:=$IS_INCR} in
	    [$IS_FREE]) ;;
	    [$IS_ARRAY]|[$IS_HASH])
		[[ $dtype == $IS_ARRAY && ! -v $dname ]] && declare -ga $dname
		[[ $dtype == $IS_HASH  && ! -v $dname ]] && declare -gA $dname
		if [[ $initial =~ ^\(.*\)$ ]] ; then
		    eval "$dname=$initial"
		else
		    [[ $dtype == $IS_ARRAY ]] && target=(${initial:+"$initial"})
		    [[ $dtype == $IS_HASH  ]] && [[ $initial ]] && _gol_die "$initial: invalid hash data"
		fi
		;;
	    [$IS_WANT]|[$IS_INCR])
		target=$initial ;;
	esac
	_opts[$name]="${dtype}${dname}"
	[[ $type ]] && _gol_check $name "$type"
	for alias in "${aliases[@]:1}" ; do
	    _opts[$alias]="${_opts[$name]}"
	    _gol_alias $alias $name
	done
    done
    return 0
}
gol_configure () { _gol_redirect "$@" ; }
gol_configure_() { local param key val ;
    for param in "$@" ; do
	[[ $param =~ ^[[:alnum:]] ]] || _gol_die "$param -- invalid config parameter"
	key="${MK_CONF}${param%%=*}"
	[[ $param =~ =(.*) ]] && val="${MATCH[1]}" || val=1
	[[ -v _opts[$key] ]] || _gol_die "$param -- invalid config parameter"
	_opts[$key]="$val"
    done
    return 0
}
gol_optstring_() { local key string ;
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[[:alnum:]]$ ]] || continue
	string+=$key
	[[ ${_opts[$key]} =~ ^[$IS_NEED] ]] && string+=:
    done
    echo "${SILENT:+:}${string}-:"
}
gol_getopts () { _gol_redirect "$@" ; }
gol_getopts_() { local optname val dtype dname alias rname callback type ;
    local opt="$1"; shift;
    case $opt in
	[:?])
	    callback=$(_gol_hook "$opt") && [[ $hook ]] && $callback "$OPTARG"
	    [[ $EXIT_ON_ERROR ]] && exit 1 || return 0
	    ;;
	-)
	    [[ $OPTARG =~ ^(no-)?([-_[:alnum:]]+)(=(.*))? ]] || die "$OPTARG: unrecognized option"
	    local no="${MATCH[1]}" optname="${MATCH[2]}" param="${MATCH[3]}"; val="${MATCH[4]}"
	    [[ ${_opts[$optname]-} =~ ^([$IS_ANY])([_[:alnum:]]+) ]] || _gol_die "no such option -- --$optname"
	    dtype=${MATCH[1]} dname=${MATCH[2]}
	    declare -n target=$dname
	    if [[ $param ]] ; then
		[[ $dtype =~ [${IS_NEED}${IS_FREE}] ]] || die "does not take an argument -- $optname"
	    else
		case $dtype in
		    [$IS_FREE]) ;;
		    [$IS_NEED])
			(( OPTIND > $# )) && _gol_die "option requires an argument -- $optname"
			val=${@:$OPTIND:1}
			(( OPTIND++ ))
			;;
		    *) [[ $no ]] && val= || unset val ;;
		esac
	    fi
	    ;;
	*)
	    optname=$opt
	    [[ ${_opts[$opt]-} =~ ^([$IS_ANY])([_[:alnum:]]+) ]] || _gol_die "no such option -- -$opt"
	    dtype=${MATCH[1]} dname=${MATCH[2]}
	    declare -n target="${MATCH[2]}"
	    [[ $dtype =~ [${IS_FREE}${IS_NEED}] ]] && val="${OPTARG:-}"
	    ;;
    esac
    case $dtype in
	[$IS_ARRAY]) target+=($val) ;;
	[$IS_HASH])  [[ $val =~ = ]] && target["${val%%=*}"]="${val#*=}" || target[$val]=1 ;;
	*)           target=${val-$(_gol_incr "$target")} ;;
    esac
    alias=$(_gol_alias $optname) && rname=$alias || rname=$optname
    type=$(_gol_check $rname) && _gol_validate "$type" "$val"
    callback="$(_gol_hook $rname)" && $callback "$target"
    return 0
}
gol_callback () { _gol_redirect "$@" ; }
gol_callback_() {
    while (($# > 0)) ; do
	local name=$1 callback=${2:-$1}
	[[ $callback =~ ^[_[:alnum:]] ]] || callback=$name
	_gol_hook "$name" "$callback"
	shift $(( $# >= 2 ? 2 : 1 ))
    done
    return 0
}
gol_parse () { _gol_redirect "$@" ; }
gol_parse_() { local gol_OPT SAVEARG=() SAVEIND= ;
    local optstring="$(gol_optstring_)" ; _gol_debug "OPTSTRING=$optstring" ;
    while (( OPTIND <= $# )) ; do
	while getopts "$optstring" gol_OPT ; do
	    gol_getopts_ "$gol_OPT" "$@"
	done
	: ${SAVEIND:=$OPTIND}
	[[ ! $PERMUTE || $OPTIND > $# || ${@:$(($OPTIND-1)):1} == -- ]] && break
	SAVEARG+=(${@:$((OPTIND++)):1})
    done
    [[ $PERMUTE ]] && set -- "${SAVEARG[@]}" "${@:$OPTIND}" || shift $(( OPTIND - 1 ))
    OPTIND=${SAVEIND:-$OPTIND}
    _gol_debug "ARGV=(${@@Q})"
    [[ $PERMUTE ]] && { declare -n _gol_argv=$PERMUTE ; _gol_argv=("$@") ; }
    return 0
}
gol_set () { _gol_redirect "$@" ; }
gol_set_() {
    if [[ $PERMUTE ]] ; then
	printf 'set -- "${%s[@]}"\n' "$PERMUTE"
    else
	echo 'shift $(( OPTIND-1 ))'
    fi
}
getoptlong () {
    case $1 in
	init|parse|set|configure|getopts|callback|dump)
	    gol_$1 "${@:2}" ;;
	*)
	    _gol_die "unknown subcommand -- $1" ;;
    esac
}
################################################################################
################################################################################
