################################################################################
################################################################################
##
## GetOptLong: Getopt Library for Bash Script
##
################################################################################
################################################################################
gol_warn() { echo "$@" >&2 ; }
gol_die()  { gol_warn "$@" ; exit 1 ; }
gol_opts() {
    (($# == 2)) && { _opts["$1"]="$2" ; return 0 ; }
    [[ -v _opts[$1] ]] && echo "${_opts[$1]}" || return 1
}
gol_conf()  { gol_opts \&"$1" "${@:2}" ; }
gol_dest()  { gol_opts \:"$1" "${@:2}" ; }
gol_alias() { gol_opts \~"$1" "${@:2}" ; }
gol_hook()  { gol_opts \!"$1" "${@:2}" ; }
gol_valid() { [[ -v _opts[:$1] ]] ; }
gol_debug() { [[ ${_opts["&DEBUG"]:-} ]] || return 0; gol_warn DEBUG: "${@}" ; }
gol_dump() {
    local declare="$(declare -p GOL_OPTIONS)"
    if [[ "$declare" =~ \"(.+)\" ]] ; then
	local name=${BASH_REMATCH[1]}
	declare -p $name | grep -oE '\[[^]]*\]="[^"]*"' | sort
    fi
}
gol_init() { local key ;
    (( $# == 0 )) && { echo 'local GOL_OPTIONS OPTIND=1' ; return ; }
    declare -A GOL_CONFIG=(
	[EXIT_ON_ERROR]=yes [SILENT]= [SAVETO]= [TRUE]=yes [FALSE]= [DEBUG]=
	[EXPORT]= [PREFIX]=opt_
    )
    declare -n _opts=$1
    for key in "${!GOL_CONFIG[@]}" ; do _opts[&$key]="${GOL_CONFIG[$key]}" ; done
    GOL_OPTIONS=$1
    gol_redirect "${@:2}"
}
gol_redirect() {
    declare -n _opts=$GOL_OPTIONS
    declare -n MATCH=BASH_REMATCH
    gol_debug "${FUNCNAME[1]}(${@@Q})"
    local MARKS=':~!&' MK_DATA=':' MK_ALIAS='~' MK_HOOK='!' MK_CONF='&' \
	  KINDS=':@%+?' IS_ARGS=":@%" IS_NEED=":" IS_MAY="?" IS_ARRAY="@" IS_HASH="%" IS_INCR="+"
    local TRUE=${_opts[${MK_CONF}TRUE]} FALSE=${_opts[${MK_CONF}FALSE]}
    "${FUNCNAME[1]}_" "$@"
}
gol_init_() { local key ;
    (( $# > 0 )) && gol_configure_ "$@"
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[$MARKS] ]] && continue
	[[ $key =~ ^([-_ \|[:alnum:]]+)([$KINDS]*)( *)$ ]] || gol_die "[$key] -- invalid"
	local names=${MATCH[1]} dest=${MATCH[2]} aliases alias
	IFS=' |' read -a aliases <<<$names
	local name=${aliases[0]}
	gol_dest "$name" "$dest"
	for alias in "${aliases[@]:1}" ; do
	    gol_alias "$alias" "$name"
	    gol_dest  "$alias" "$dest"
	done
	case $dest in
	    [$IS_MAY]) ;;
	    [$IS_ARRAY]|[$IS_HASH])
		local arrayname="$(gol_conf PREFIX)$name"
		declare -n array=$arrayname
		_opts[$name]=$arrayname
		local initial="${_opts[$key]}"
		[[ $dest == $IS_ARRAY && ! -v $arrayname ]] && declare -ga $arrayname
		[[ $dest == $IS_HASH  && ! -v $arrayname ]] && declare -gA $arrayname
		if [[ $initial =~ ^\(.*\)$ ]] ; then
		    eval "$arrayname=$initial"
		else
		    [[ $dest == $IS_ARRAY ]] && array=(${initial:+"$initial"})
		    [[ $dest == $IS_HASH  ]] && gol_die "$initial: invalid"
		fi
		;;
	    *) [[ $name != $key ]] && _opts[$name]=${_opts[$key]} ;;
	esac
    done
    return 0
}
gol_configure () { gol_redirect "$@" ; }
gol_configure_() { local param key val ;
    for param in "$@" ; do
	[[ $param =~ ^[[:alnum:]] ]] || gol_die "$param -- invalid config parameter"
	key="${MK_CONF}${param%%=*}"
	[[ $param =~ =(.*) ]] && val="${MATCH[1]}" || val="$TRUE"
	[[ -v _opts[$key] ]] || gol_die "$param -- invalid config parameter"
	_opts[$key]="$val"
    done
    return 0
}
gol_optstring () { gol_redirect "$@" ; }
gol_optstring_() { local key string ;
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^${MK_DATA}(.)$ ]] || continue
	string+=${MATCH[1]}
	[[ ${_opts[$key]} =~ [$IS_ARGS] ]] && string+=:
    done
    [[ $(gol_conf SILENT) ]] && string=":$string"
    string+="-:"
    gol_debug "Return $string"
    echo "$string"
}
gol_getopts () { gol_redirect "$@" ; }
gol_getopts_() { local name val dest callback ;
    local opt="$1"; shift;
    case $opt in
	[:?])
	    local hook=$(gol_hook "$opt")
	    [[ $hook ]] && $hook "$OPTARG"
	    [[ $(gol_conf EXIT_ON_ERROR) ]] && exit 1
	    return 0
	    ;;
	-)
	    [[ $OPTARG =~ ^(no-?)?([-_[:alnum:]]+)(=(.*))? ]] || die "$OPTARG: unrecognized option"
	    local no="${MATCH[1]}" nm="${MATCH[2]}" param="${MATCH[3]}"; val="${MATCH[4]}"
	    name=$(gol_alias $nm) || name=$nm
	    dest=$(gol_dest $name)
	    gol_valid $name || gol_die "no such option -- $name"
	    if [[ $param ]] ; then
		[[ $dest =~ [${IS_ARGS}${IS_MAY}] ]] || die "does not take an argument -- $name"
	    else
		case $dest in
		    [$IS_MAY]) ;;
		    [$IS_INCR]) val=$(( _opts[$name] + 1 )) ;;
		    [$IS_ARGS])
			(( OPTIND > $# )) && gol_die "option requires an argument -- $name"
			val=${@:$OPTIND:1}
			(( OPTIND++ ))
			;;
		    *) [[ $no ]] && val="$FALSE" || val="$TRUE" ;;
		esac
	    fi
	    ;;
	*)
	    name=$(gol_alias $opt) || name=$opt
	    case ${dest:=$(gol_dest "$name")} in
		[$IS_MAY])  val="${OPTARG:-}" ;;
		[$IS_INCR]) val=$(( _opts[$name] + 1 )) ;;
		[$IS_ARGS]) val="${OPTARG}" ;;
		*)          val="$TRUE" ;;
	    esac
	    ;;
    esac
    case $dest in
	[$IS_ARRAY]|[$IS_HASH])
	    local arrayname="${_opts[$name]}"
	    declare -n array="$arrayname"
	    if [[ $dest == $IS_ARRAY ]] ; then
		[[ -v $arrayname ]] || declare -ga "$arrayname"
		array+=($val)
	    else
		[[ -v $arrayname ]] || declare -gA "$arrayname"
		[[ $val =~ = ]] && array["${val%%=*}"]="${val#*=}" || array[$val]=$TRUE
	    fi
	    ;;
	*)
	    _opts[$name]="$val" ;;
    esac
    callback="$(gol_hook $name)" && $callback "$val"
    return 0
}
gol_callback () { gol_redirect "$@" ; }
gol_callback_() {
    declare -a config=("$@")
    while (($# > 0)) ; do
	local name=$1 callback=${2:-$1}
	[[ $callback == - ]] && callback=$name
	gol_hook "$name" "$callback"
	shift $(( $# >= 2 ? 2 : 1 ))
    done
    return 0
}
gol_export () { gol_redirect "$@" ; }
gol_export_() { local key ;
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[[:alnum:]_] ]] || continue
	[[ $(gol_dest "$key") =~ [${IS_ARRAY}${IS_HASH}] ]] && continue
	local name="$(gol_conf PREFIX)${key}"
	gol_debug "exporting $name=${_opts[$key]@Q}"
	printf -v "${name}" '%s' "${_opts[$key]}";
    done
    return 0
}
gol_parse () { gol_redirect "$@" ; }
gol_parse_() { local gol_OPT ;
    local optstring="$(gol_optstring_)"
    while getopts "$optstring" gol_OPT ; do
	gol_getopts_ "$gol_OPT" "$@"
    done
    shift $(( OPTIND - 1 ))
    gol_debug "ARGV=(${@@Q})"
    local array="$(gol_conf SAVETO)"
    [[ $array ]] && { declare -n argv=$array ; argv=("$@") ; }
    [[ $(gol_conf EXPORT) ]] && gol_export_
    return 0
}
getoptlong () {
    case $1 in
	init|parse|callback|configure|export|getopts|dump)
	    gol_$1 "${@:2}" ;;
	*)
	    gol_die "unknown subcommand -- $1" ;;
    esac
}
################################################################################
################################################################################
