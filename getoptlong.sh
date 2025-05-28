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
_gol_dest()  { _gol_opts \:"$1" "${@:2}" ; }
_gol_alias() { _gol_opts \~"$1" "${@:2}" ; }
_gol_hook()  { _gol_opts \!"$1" "${@:2}" ; }
_gol_valid() { [[ -v _opts[:$1] ]] ; }
_gol_debug() { [[ ${_opts["&DEBUG"]:-} ]] && _gol_warn DEBUG: "${@}" || : ; }
_gol_redirect() {
    declare -n _opts=$GOL_OPTIONS
    declare -n MATCH=BASH_REMATCH
    _gol_debug "${FUNCNAME[1]}(${@@Q})"
    local MARKS=':~!&' MK_DATA=':' MK_ALIAS='~' MK_HOOK='!' MK_CONF='&' \
	  KINDS=':@%+?' IS_ARGS=":@%" IS_NEED=":" IS_MAY="?" IS_ARRAY="@" IS_HASH="%" IS_INCR="+"
    for key in EXIT_ON_ERROR SILENT SAVETO TRUE FALSE PERMUTE DEBUG EXPORT PREFIX ; do
	declare $key="${_opts[&$key]}"
    done
    "${FUNCNAME[1]}_" "$@"
}
gol_dump() {
    declare -p $GOL_OPTIONS | grep -oE '\[[^]]*\]="[^"]*"' | sort
}
gol_init() { local key ;
    (( $# == 0 )) && { echo 'local GOL_OPTIONS OPTIND=1' ; return ; }
    declare -A GOL_CONFIG=(
	[EXIT_ON_ERROR]=yes [SILENT]= [SAVETO]= [TRUE]=yes [FALSE]= [PERMUTE]= [DEBUG]=
	[EXPORT]= [PREFIX]=opt_
    )
    declare -n _opts=$1
    for key in "${!GOL_CONFIG[@]}" ; do _opts[&$key]="${GOL_CONFIG[$key]}" ; done
    GOL_OPTIONS=$1
    _gol_redirect "${@:2}"
}
gol_init_() { local key ;
    (( $# > 0 )) && gol_configure_ "$@"
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[$MARKS] ]] && continue
	[[ $key =~ ^([-_ \|[:alnum:]]+)([$KINDS]*)( *)$ ]] || _gol_die "[$key] -- invalid"
	local names=${MATCH[1]} dest=${MATCH[2]} aliases alias
	IFS=' |' read -a aliases <<<$names
	local name=${aliases[0]}
	_gol_dest "$name" "$dest"
	for alias in "${aliases[@]:1}" ; do
	    _gol_alias "$alias" "$name"
	    _gol_dest  "$alias" "$dest"
	done
	case $dest in
	    [$IS_MAY]) ;;
	    [$IS_ARRAY]|[$IS_HASH])
		local arrayname="${PREFIX}${name}"
		declare -n array=$arrayname
		_opts[$name]=$arrayname
		local initial="${_opts[$key]}"
		[[ $dest == $IS_ARRAY && ! -v $arrayname ]] && declare -ga $arrayname
		[[ $dest == $IS_HASH  && ! -v $arrayname ]] && declare -gA $arrayname
		if [[ $initial =~ ^\(.*\)$ ]] ; then
		    eval "$arrayname=$initial"
		else
		    [[ $dest == $IS_ARRAY ]] && array=(${initial:+"$initial"})
		    [[ $dest == $IS_HASH  ]] && [[ $initial ]] && _gol_die "$initial: invalid hash data"
		fi
		;;
	    *) [[ $name != $key ]] && _opts[$name]=${_opts[$key]} ;;
	esac
    done
    return 0
}
gol_configure () { _gol_redirect "$@" ; }
gol_configure_() { local param key val ;
    for param in "$@" ; do
	[[ $param =~ ^[[:alnum:]] ]] || _gol_die "$param -- invalid config parameter"
	key="${MK_CONF}${param%%=*}"
	[[ $param =~ =(.*) ]] && val="${MATCH[1]}" || val="$TRUE"
	[[ -v _opts[$key] ]] || _gol_die "$param -- invalid config parameter"
	_opts[$key]="$val"
    done
    return 0
}
gol_optstring () { _gol_redirect "$@" ; }
gol_optstring_() { local key string ;
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^${MK_DATA}(.)$ ]] || continue
	string+=${MATCH[1]}
	[[ ${_opts[$key]} =~ [$IS_ARGS] ]] && string+=:
    done
    [[ $SILENT ]] && string=":$string"
    string+="-:"
    _gol_debug "Return $string"
    echo "$string"
}
gol_getopts () { _gol_redirect "$@" ; }
gol_getopts_() { local name val dest callback ;
    local opt="$1"; shift;
    case $opt in
	[:?])
	    local hook=$(_gol_hook "$opt")
	    [[ $hook ]] && $hook "$OPTARG"
	    [[ $EXIT_ON_ERROR ]] && exit 1
	    return 0
	    ;;
	-)
	    [[ $OPTARG =~ ^(no-?)?([-_[:alnum:]]+)(=(.*))? ]] || die "$OPTARG: unrecognized option"
	    local no="${MATCH[1]}" nm="${MATCH[2]}" param="${MATCH[3]}"; val="${MATCH[4]}"
	    name=$(_gol_alias $nm) || name=$nm
	    dest=$(_gol_dest $name)
	    _gol_valid $name || _gol_die "no such option -- $name"
	    if [[ $param ]] ; then
		[[ $dest =~ [${IS_ARGS}${IS_MAY}] ]] || die "does not take an argument -- $name"
	    else
		case $dest in
		    [$IS_MAY]) ;;
		    [$IS_INCR]) val=$(( _opts[$name] + 1 )) ;;
		    [$IS_ARGS])
			(( OPTIND > $# )) && _gol_die "option requires an argument -- $name"
			val=${@:$OPTIND:1}
			(( OPTIND++ ))
			;;
		    *) [[ $no ]] && val="$FALSE" || val="$TRUE" ;;
		esac
	    fi
	    ;;
	*)
	    name=$(_gol_alias $opt) || name=$opt
	    case ${dest:=$(_gol_dest "$name")} in
		[$IS_MAY])  val="${OPTARG:-}" ;;
		[$IS_INCR]) val=$(( _opts[$name] + 1 )) ;;
		[$IS_ARGS]) val="${OPTARG}" ;;
		*)          val="$TRUE" ;;
	    esac
	    ;;
    esac
    case $dest in
	[$IS_ARRAY]|[$IS_HASH])
	    declare -n array="${_opts[$name]}"
	    if [[ $dest == $IS_ARRAY ]] ; then
		array+=($val)
	    else
		[[ $val =~ = ]] && array["${val%%=*}"]="${val#*=}" || array[$val]=$TRUE
	    fi
	    ;;
	*)
	    _opts[$name]="$val" ;;
    esac
    callback="$(_gol_hook $name)" && $callback "$val"
    return 0
}
gol_callback () { _gol_redirect "$@" ; }
gol_callback_() {
    declare -a config=("$@")
    while (($# > 0)) ; do
	local name=$1 callback=${2:-$1}
	[[ $callback == - ]] && callback=$name
	_gol_hook "$name" "$callback"
	shift $(( $# >= 2 ? 2 : 1 ))
    done
    return 0
}
gol_export () { _gol_redirect "$@" ; }
gol_export_() { local key ;
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[[:alnum:]_] ]] || continue
	[[ $(_gol_dest "$key") =~ [${IS_ARRAY}${IS_HASH}] ]] && continue
	local name="${PREFIX}${key}"
	_gol_debug "exporting $name=${_opts[$key]@Q}"
	printf -v "${name}" '%s' "${_opts[$key]}";
    done
    return 0
}
gol_parse () { _gol_redirect "$@" ; }
gol_parse_() { local gol_OPT SAVEARG=() SAVEIND ;
    local optstring="$(gol_optstring_)"
    while (( OPTIND <= $# )) ; do
	while getopts "$optstring" gol_OPT ; do
	    gol_getopts_ "$gol_OPT" "$@"
	done
	: ${SAVEIND:=$OPTIND}
	[[ ! $PERMUTE || $OPTIND > $# || ${@:$(($OPTIND-1)):1} == -- ]] && break
	SAVEARG+=(${@:$((OPTIND++)):1})
    done
    [[ $PERMUTE ]] && set -- "${SAVEARG[@]}" "${@:$OPTIND}" || shift $(( OPTIND - 1 ))
    OPTIND=$SAVEIND
    _gol_debug "ARGV=(${@@Q})"
    [[ $SAVETO ]] && { declare -n _gol_argv=$SAVETO ; _gol_argv=("$@") ; }
    [[ $EXPORT ]] && gol_export_
    return 0
}
getoptlong () {
    case $1 in
	init|parse|configure|getopts|callback|export|dump)
	    gol_$1 "${@:2}" ;;
	*)
	    _gol_die "unknown subcommand -- $1" ;;
    esac
}
################################################################################
################################################################################
