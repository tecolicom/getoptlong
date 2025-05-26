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
tgl_valid() { [[ -v _opts[:$1] ]] }
tgl_debug() { [[ ${_opts["&DEBUG"]:-} ]] || return 0; tgl_warn DEBUG: "${@}" ; }
tgl_dump() {
    local declare="$(declare -p TGL_OPTS)"
    if [[ "$declare" =~ \"(.+)\" ]] ; then
	declare -p ${BASH_REMATCH[1]} | grep -oE '\[[^]]*\]="[^"]*"' | sort
    fi
}
tgl_setup() {
    (( $# == 0 )) && { echo 'local TGL_OPTS OPTIND=1' ; return ; }
    declare -A TGL_CONFIG=(
	[EXIT_ON_ERROR]=yes [SILENT]= [SAVETO]= [TRUE]=yes [FALSE]= [DEBUG]=
    )
    declare -n _opts=$1
    for key in "${!TGL_CONFIG[@]}" ; do _opts[&$key]="${TGL_CONFIG[$key]}" ; done
    TGL_OPTS=$1
    tgl_redirect "${@:2}"
}
tgl_redirect() {
    declare -n _opts=$TGL_OPTS
    tgl_debug "${FUNCNAME[1]}(${@@Q})"
    local MARKS=':=!&' MK_TYPE=':' MK_ALIAS='=' MK_HOOK='!' MK_CONF='&' \
	  TYPES=':@+?' TP_ARGS=":@" TP_NEED=":" TP_MAY="?" TP_ARRAY="@" TP_INCR="+"
    local TRUE=${_opts[${MK_CONF}TRUE]} FALSE=${_opts[${MK_CONF}FALSE]}
    declare -n MATCH=BASH_REMATCH
    "${FUNCNAME[1]}_" $TGL_OPTS "$@"
}
tgl_setup_() {
    declare -n _opts=$1; shift
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[$MARKS] ]] && continue
	if [[ $key =~ ^([-_ \|[:alnum:]]+)([$TYPES]*)( *)$ ]] ; then
	    local names=${MATCH[1]} type=${MATCH[2]} aliases alias
	    IFS=' |' read -a aliases <<<$names
	    local name=${aliases[0]}
	    tgl_type "$name" "$type"
	    for alias in "${aliases[@]:1}" ; do
		tgl_alias "$alias" "$name"
		tgl_type  "$alias" "$type"
	    done
	    case $type in
		[$TP_ARRAY])
		    declare -n array=$name
		    [[ ${_opts[$key]} ]] && array=("${_opts[$key]}") || array=()
		    _opts[$name]=$name
		    ;;
		[$TP_MAY]) ;;
		*) [[ $name != $key ]] && _opts[$name]=${_opts[$key]} ;;
	    esac
	else
	    tgl_warn "[$key] -- option description error"
	    exit 1
	fi
    done
    (( $# > 0 )) && tgl_configure "$@"
    return 0
}
tgl_configure () { tgl_redirect "$@" ; }
tgl_configure_() {
    declare -n _opts=$1; shift
    for param in "$@" ; do
	[[ $param =~ ^[[:alnum:]] ]] || tgl_die "$param -- invalid config parameter"
	local key val
	if [[ $param =~ = ]] ; then
	    key="${MK_CONF}${param%%=*}"
	    val="${param#*=}"
	else
	    key="${MK_CONF}${param}"
	    val="$TRUE"
	fi
	[[ -v _opts[$key] ]] || tgl_die "$param -- invalid config parameter"
	_opts[$key]="$val"
    done
    return 0
}
tgl_string () { tgl_redirect "$@" ; }
tgl_string_() {
    declare -n _opts=$1; shift
    local key string
    for key in ${!_opts[@]} ; do
	[[ $key =~ ^${MK_TYPE}(.)$ ]] || continue
	string+=${MATCH[1]}
	[[ ${_opts[$key]} =~ [$TP_ARGS] ]] && string+=:
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
    case $opt in
	[:?])
	    local hook=$(tgl_hook "$opt")
	    [[ $hook ]] && $hook "$OPTARG"
	    [[ $(tgl_conf EXIT_ON_ERROR) ]] && exit 1
	    return 0
	    ;;
	-)
	    [[ $OPTARG =~ ^(no-?)?([-_[:alnum:]]+)(=(.*))? ]] || die "$OPTARG: unrecognized option"
	    local no="${MATCH[1]}" nm="${MATCH[2]}" param="${MATCH[3]}"; val="${MATCH[4]}"
	    name=$(tgl_alias $nm) || name=$nm
	    type=$(tgl_type $name)
	    tgl_valid $name || tgl_die "no such option -- $name"
	    if [[ $param ]] ; then
		[[ $type =~ [${TP_ARGS}${TP_MAY}] ]] || die "does not take an argument -- $name"
	    else
		case $type in
		    [$TP_MAY]) ;;
		    [$TP_INCR]) val=$(( _opts[$name] + 1 )) ;;
		    [$TP_ARGS])
			(( OPTIND > $# )) && tgl_die "option requires an argument -- $name"
			val=${@:$((OPTIND)):1}
			(( OPTIND++ ))
			;;
		    *) [[ $no ]] && val="$FALSE" || val="$TRUE" ;;
		esac
	    fi
	    ;;
	*)
	    name=$(tgl_alias $opt) || name=$opt
	    case ${type:=$(tgl_type "$name")} in
		[$TP_MAY])  val="${OPTARG:-}" ;;
		[$TP_INCR]) val=$(( _opts[$name] + 1 )) ;;
		[$TP_ARGS]) val="${OPTARG}" ;;
		*)          val="$TRUE" ;;
	    esac
	    ;;
    esac
    case $type in
	[$TP_ARRAY])
	    declare -n array=${_opts[@$name]:-$name}; array+=($val) ;;
	*)
	    _opts[$name]="$val" ;;
    esac
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
getoptlong     () { tgl_getoptlong "$@" ; }
tgl_getoptlong () { tgl_redirect "$@" ; }
tgl_getoptlong_() {
    declare -n _opts=$1; shift
    local tgl_OPT optstring="$(tgl_string)"
    while getopts "$optstring" tgl_OPT ; do
	tgl_getopts "$tgl_OPT" "$@"
    done
    shift $(( OPTIND - 1 ))
    tgl_debug "ARGV=(${@@Q})"
    local array="$(tgl_conf SAVETO)"
    [[ $array ]] && { declare -n argv=$array ; argv=("$@") ; }
    return 0
}
################################################################################
################################################################################
