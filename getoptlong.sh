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
tgl_debug() { [[ ${_opts["&DEBUG"]} ]] || return 0; tgl_warn DEBUG: "${@}" ; }
tgl_dump() {
    local declare="$(declare -p TGL_OPTS)"
    if [[ "$declare" =~ \"(.+)\" ]] ; then
	declare -p ${BASH_REMATCH[1]} | grep -o -E '\[[^]]*\]="[^"]*"' | sort
    fi
}
tgl_setup() {
    declare -A TGL_CONFIG=(
	[EXIT_ON_ERROR]=yes [SILENT]= [SAVETO]=
	[TRUE]=yes [FALSE]= [DEBUG]=
	[MARKS]=':=!&' [MK_TYPE]=':' [MK_ALIAS]='=' [MK_HOOK]='!' [MK_CONF]='&'
	[TYPES]=':@+?' [TP_NEED]=':' [TP_ARRAY]='@' [TP_INCR]='+' [TP_MAY]='?'
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
    local key marks="$(tgl_conf MARKS)" tp_array=$(tgl_conf TP_ARRAY)
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
		$tp_array)
		    declare -n array=$name
		    [[ ${_opts[$key]} ]] && array=("${_opts[$key]}") || array=()
		    _opts[$name]=$name
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
    tgl_debug "${FUNCNAME[1]}(${@@Q})"
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
    local key string mark=$(tgl_conf MK_TYPE)
    local tp_args="$(tgl_conf TP_NEED)$(tgl_conf TP_ARRAY)"
    for key in ${!_opts[@]} ; do
	[[ $key =~ ^${mark}.$ ]] || continue
	[[ ${_opts[$key]} =~ [$tp_args] ]] && string+="${key#:}:" || string+=${key#:}
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
    local tp_need="$(tgl_conf TP_NEED)" tp_may="$(tgl_conf TP_MAY)" tp_array="$(tgl_conf TP_ARRAY)" tp_incr="$(tgl_conf TP_INCR)"
    local tp_args="${tp_need}${tp_array}"
    case $opt in
	[:?])
	    local hook=$(tgl_hook "$opt")
	    [[ $hook ]] && $hook "$OPTARG"
	    [[ $(tgl_conf EXIT_ON_ERROR) ]] && exit 1
	    return 0
	    ;;
	-)
	    [[ $OPTARG =~ ^(no-?)?([-_[:alnum:]]+)(=(.*))? ]] || die "$OPTARG: unrecognized option"
	    local no="${BASH_REMATCH[1]}" nm="${BASH_REMATCH[2]}" param="${BASH_REMATCH[3]}"; val="${BASH_REMATCH[4]}"
	    name=$(tgl_alias $nm) || name=$nm
	    type=$(tgl_type $name)
	    [[ -v _opts[$name] ]] || tgl_die "--$name: no such option"
	    if [[ $param ]] ; then
		[[ $type =~ [${tp_args}${tp_may}] ]] || die "does not take an argument -- $name"
	    else
		case $type in
		    [$tp_may]) ;;
		    [$tp_incr]) val=$(( _opts[$name] + 1 )) ;;
		    [$tp_args])
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
		[$tp_incr]) val=$(( _opts[$name] + 1 )) ;;
		[$tp_args]) val="${OPTARG}" ;;
		*)            val=$(tgl_conf TRUE) ;;
	    esac
	    ;;
    esac
    case $type in
	[$tp_array])
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
getoptlong     () { tgl_getoptlong "$@" ; }
tgl_getoptlong () { tgl_redirect "$@" ; }
tgl_getoptlong_() {
    declare -n _opts=$1; shift
    local tgl_OPT optstring="$(tgl_string)"
    while getopts "$optstring" tgl_OPT ; do
	tgl_getopts "$tgl_OPT" "$@"
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
