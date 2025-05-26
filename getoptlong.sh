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
gol_type()  { gol_opts \:"$1" "${@:2}" ; }
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
gol_setup() { local key ;
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
    local MARKS=':~!&' MK_TYPE=':' MK_ALIAS='~' MK_HOOK='!' MK_CONF='&' \
	  TYPES=':@%+?' TP_ARGS=":@%" TP_NEED=":" TP_MAY="?" TP_ARRAY="@" TP_HASH="%" TP_INCR="+"
    local TRUE=${_opts[${MK_CONF}TRUE]} FALSE=${_opts[${MK_CONF}FALSE]}
    "${FUNCNAME[1]}_" "$@"
}
gol_setup_() { local key ;
    (( $# > 0 )) && gol_configure "$@"
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[$MARKS] ]] && continue
	if [[ $key =~ ^([-_ \|[:alnum:]]+)([$TYPES]*)( *)$ ]] ; then
	    local names=${MATCH[1]} type=${MATCH[2]} aliases alias
	    IFS=' |' read -a aliases <<<$names
	    local name=${aliases[0]}
	    gol_type "$name" "$type"
	    for alias in "${aliases[@]:1}" ; do
		gol_alias "$alias" "$name"
		gol_type  "$alias" "$type"
	    done
	    case $type in
		[$TP_ARRAY]|[$TP_HASH])
		    local arrayname="$(gol_conf PREFIX)$name"
		    declare -n array=$arrayname
		    _opts[$name]=$arrayname
		    local initial="${_opts[$key]}"
		    [[ $type == $TP_ARRAY && ! -v $arrayname ]] && declare -ga $arrayname
		    [[ $type == $TP_HASH  && ! -v $arrayname ]] && declare -gA $arrayname
		    if [[ $initial =~ ^\(.*\)$ ]] ; then
			eval "$arrayname=$initial"
		    else
			[[ $type == $TP_ARRAY ]] && array=(${initial:+"$initial"})
			[[ $type == $TP_HASH  ]] && gol_die "$initial: invalid"
		    fi
		    ;;
		[$TP_MAY]) ;;
		*) [[ $name != $key ]] && _opts[$name]=${_opts[$key]} ;;
	    esac
	else
	    gol_warn "[$key] -- option description error"
	    exit 1
	fi
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
gol_string () { gol_redirect "$@" ; }
gol_string_() { local key string ;
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^${MK_TYPE}(.)$ ]] || continue
	string+=${MATCH[1]}
	[[ ${_opts[$key]} =~ [$TP_ARGS] ]] && string+=:
    done
    [[ $(gol_conf SILENT) ]] && string=":$string"
    string+="-:"
    gol_debug "Return $string"
    echo "$string"
}
gol_getopts () { gol_redirect "$@" ; }
gol_getopts_() { local name val type callback ;
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
	    type=$(gol_type $name)
	    gol_valid $name || gol_die "no such option -- $name"
	    if [[ $param ]] ; then
		[[ $type =~ [${TP_ARGS}${TP_MAY}] ]] || die "does not take an argument -- $name"
	    else
		case $type in
		    [$TP_MAY]) ;;
		    [$TP_INCR]) val=$(( _opts[$name] + 1 )) ;;
		    [$TP_ARGS])
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
	    case ${type:=$(gol_type "$name")} in
		[$TP_MAY])  val="${OPTARG:-}" ;;
		[$TP_INCR]) val=$(( _opts[$name] + 1 )) ;;
		[$TP_ARGS]) val="${OPTARG}" ;;
		*)          val="$TRUE" ;;
	    esac
	    ;;
    esac
    case $type in
	[$TP_ARRAY]|[$TP_HASH])
	    local arrayname="${_opts[$name]}"
	    declare -n array="$arrayname"
	    if [[ $type == $TP_ARRAY ]] ; then
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
	local type=$(gol_type "$key")
	[[ $type == $TP_ARRAY ]] && continue
	local name="$(gol_conf PREFIX)${key}"
	gol_debug "exporting $name=${_opts[$key]@Q}"
	printf -v "${name}" '%s' "${_opts[$key]}";
    done
    return 0
}
getoptlong () { gol_redirect "$@" ; }
getoptlong_() { local gol_OPT ;
    local optstring="$(gol_string)"
    while getopts "$optstring" gol_OPT ; do
	gol_getopts "$gol_OPT" "$@"
    done
    shift $(( OPTIND - 1 ))
    gol_debug "ARGV=(${@@Q})"
    local array="$(gol_conf SAVETO)"
    [[ $array ]] && { declare -n argv=$array ; argv=("$@") ; }
    [[ $(gol_conf EXPORT) ]] && gol_export
    return 0
}
################################################################################
################################################################################
