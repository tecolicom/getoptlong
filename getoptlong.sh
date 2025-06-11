#!/usr/bin/env bash
# vim: filetype=bash :  -*- mode: sh; sh-shell: bash; -*-
###############################################################################
# GetOptLong: Getopt Library for Bash Script
# Copyright 2025 Office TECOLI, LLC <https://github.com/tecolicom/getoptlong>
# MIT License: See <https://opensource.org/licenses/MIT>
: ${GOL_VERSION:=0.01}
###############################################################################
declare -n > /dev/null 2>&1 || { echo "Does not support ${BASH_VERSION}" >&2 ; exit 1 ; }
[[ $0 =~ getoptlong(\.sh)?$ ]] && { cat $0 ; exit 0 ; }
_gol_warn() { echo "$@" >&2 ; }
_gol_die()  { _gol_warn "$@" ; exit 1 ; }
_gol_opts() {
    local key="$1"
    [[ $key =~ ^[$MARKS]$ ]] && { key+="$2" ; shift ; }
    (($# == 2)) && { _opts["$key"]="$2" ; return 0 ; }
    [[ -v _opts[$key] ]] && echo "${_opts[$key]}" || return 1
}
_gol_alias() { _gol_opts "$MK_ALIAS" "$@" ; }
_gol_saila() { _gol_opts "$MK_SAILA" "$@" ; }
_gol_hook()  { _gol_opts "$MK_HOOK"  "$@" ; }
_gol_check() { _gol_opts "$MK_TYPE"  "$@" ; }
_gol_help()  { _gol_opts "$MK_HELP"  "$@" ; }
_gol_debug() { [[ ${_opts["&DEBUG"]:-} ]] && _gol_warn DEBUG: "${@}" || : ; }
_gol_incr()  { [[ $1 =~ ^[0-9]+$ ]] && echo $(( $1 + 1 )) || echo 1 ; }
_gol_redirect() { local name ;
    declare -n _opts=$GOL_OPTHASH
    declare -n MATCH=BASH_REMATCH
    _gol_debug "${FUNCNAME[1]}(${@@Q})"
    local MARKS='><!&=#' MK_ALIAS='>' MK_SAILA='<' MK_HOOK='!' MK_CONF='&' MK_TYPE='=' MK_HELP='#' \
	  IS_ANY=':@%+?' IS_NEED=":@%" IS_WANT=":" IS_FREE="?" IS_ARRAY="@" IS_HASH="%" IS_INCR="+"
    local CONFIG=(EXIT_ON_ERROR SILENT PERMUTE REQUIRE DEBUG PREFIX DELIM USAGE)
    for name in "${CONFIG[@]}" ; do declare $name="${_opts[&$name]=}" ; done
    "${FUNCNAME[1]}_" "$@"
}
gol_dump () { _gol_redirect "$@" ; }
gol_dump_() {
    for key in "${!_opts[@]}" ; do
	printf '[%s]=%s\n' "${key}" "${_opts["$key"]@Q}"
	[[ $key =~ ^[[:alnum:]_] && ${_opts[$key]} =~ ([$IS_ANY])($PREFIX(.*)) && ${key//-/_} == ${MATCH[3]} ]] && {
	    local vname=${MATCH[2]}
	    [[ $(declare -p $vname 2> /dev/null) =~ declare( )(..)( )(.*) ]] && echo "${MATCH[4]}" || echo "$vname=unset"
	}
    done | sort
}
gol_init() { local key ;
    (( $# == 0 )) && { echo '(( ${#FUNCNAME[@]} > 0 )) && local GOL_OPTHASH OPTIND=1 || OPTIND=1' ; return ; }
    declare -n _opts=$1
    declare -A GOL_CONFIG=([PERMUTE]=GOL_ARGV [EXIT_ON_ERROR]=1 [DELIM]=$' \t,')
    for key in "${!GOL_CONFIG[@]}" ; do : ${_opts["&$key"]="${GOL_CONFIG[$key]}"} ; done
    GOL_OPTHASH=$1
    (( $# > 1 )) && gol_configure "${@:2}"
    _gol_redirect
} ################################################################################
gol_init_() { local key aliases alias ;
    [[ $REQUIRE && $GOL_VERSION < $REQUIRE ]] && _gol_die "getoptlong version $GOL_VERSION < $REQUIRE"
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[$MARKS] ]] && continue
	[[ $key =~ ^([-_ \|[:alnum:]]+)([$IS_ANY]*)( *)(=([if]|\(.*\)))?( *)(# *(.*[^[:space:]]))? ]] \
	    || _gol_die "[$key] -- invalid"
	local names=${MATCH[1]} vtype=${MATCH[2]} type=${MATCH[5]} comment=${MATCH[8]}
	local initial="${_opts[$key]}"
	IFS=$' \t|' read -a aliases <<< ${names}
	local name=${aliases[0]}
	local vname="${PREFIX}${name//-/_}"
	declare -n target=$vname
	unset _opts["$key"]
	case ${vtype:=$IS_INCR} in
	    [$IS_FREE])
		[[ $initial ]] && _gol_die "$initial: optional parameter can't be initialized" ;;
	    [$IS_ARRAY]|[$IS_HASH])
		[[ $vtype == $IS_ARRAY && ! -v $vname ]] && declare -ga $vname
		[[ $vtype == $IS_HASH  && ! -v $vname ]] && declare -gA $vname
		if [[ $initial =~ ^\(.*\)$ ]] ; then
		    eval "$vname=$initial"
		else
		    [[ $vtype == $IS_ARRAY ]] && target=(${initial:+"$initial"})
		    [[ $vtype == $IS_HASH  ]] && [[ $initial ]] && _gol_die "$initial: invalid hash data"
		fi
		;;
	    [$IS_WANT]|[$IS_INCR])
		target=$initial ;;
	esac
	_opts[$name]="${vtype}${vname}"
	[[ $type ]] && _gol_check $name "$type"
	for alias in "${aliases[@]:1}" ; do
	    _opts[$alias]="${_opts[$name]}"
	    _gol_alias $alias $name
	done
	_gol_saila $name "${aliases[*]:1}"
	[[ $comment ]] && _gol_help "$name" "$comment"
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
    echo "${SILENT:+:}${string:- }-:"
}
gol_getopts () { _gol_redirect "$@" ; }
gol_getopts_() { local optname val vtype vname name callback ;
    local opt="$1"; shift;
    case $opt in
	[:?]) callback=$(_gol_hook "$opt") && [[ $callback ]] && $callback "$OPTARG"
	      [[ $EXIT_ON_ERROR ]] && exit 1 || return 1 ;;
	-) _gol_getopts_long "$@" || return $? ;;
	*) _gol_getopts_short || return $? ;;
    esac
    name=$(_gol_alias ${optname:-$opt}) || name=${optname:=$opt}
    _gol_getopts_store
    callback="$(_gol_hook $name)" && $callback "$val"
    return 0
}
_gol_getopts_long() { local no param ;
    [[ $OPTARG =~ ^(no-)?([-_[:alnum:]]+)(=(.*))? ]] || _gol_die "$OPTARG: unrecognized option"
    no="${MATCH[1]}" optname="${MATCH[2]}" param="${MATCH[3]}" val="${MATCH[4]}"
    [[ $(_gol_opts $optname) =~ ^([$IS_ANY])([_[:alnum:]]+) ]] || {
	[[ $EXIT_ON_ERROR ]] && _gol_die "no such option -- --$optname" || return 2
    }
    vtype=${MATCH[1]} vname=${MATCH[2]}
    if [[ $param ]] ; then
	[[ $vtype =~ [${IS_NEED}${IS_FREE}] ]] || _gol_die "does not take an argument -- $optname"
    else
	case $vtype in
	    [$IS_FREE]) ;;
	    [$IS_NEED])
		(( OPTIND > $# )) && _gol_die "option requires an argument -- $optname"
		val="${@:$((OPTIND++)):1}" ;;
	    *) [[ $no ]] && val= || unset val ;;
	esac
    fi
    return 0
}
_gol_getopts_short() {
    [[ ${_opts[$opt]-} =~ ^([$IS_ANY])([_[:alnum:]]+) ]] || {
	[[ $EXIT_ON_ERROR ]] && _gol_die "no such option -- -$opt" || return 3
    }
    vtype=${MATCH[1]} vname=${MATCH[2]}
    [[ $vtype =~ [${IS_FREE}${IS_NEED}] ]] && val="${OPTARG:-}"
    return 0
}
_gol_getopts_store() { local vals ;
    declare -n target=$vname
    local check=$(_gol_check $name)
    case $vtype in
	[$IS_ARRAY]|[$IS_HASH])
	    [[ $val =~ $'\n' ]] && readarray -t vals <<< ${val%$'\n'} \
				|| IFS="${DELIM}" read -a vals <<< ${val}
	    for val in "${vals[@]}" ; do
		[[ $check ]] && _gol_validate "$check" "$val"
		case $vtype in
		[$IS_ARRAY]) target+=("$val") ;;
		[$IS_HASH])  [[ $val =~ = ]] && target["${val%%=*}"]="${val#*=}" || target[$val]=1 ;;
		esac
	    done
	    ;;
	[$IS_ARRAY]) target+=($val) ;;
	[$IS_HASH])  [[ "$val" =~ = ]] && target["${val%%=*}"]="${val#*=}" || target[$val]=1 ;;
	*) [[ $check ]] && _gol_validate "$check" "$val"
	   target=${val=$(_gol_incr "$target")} ;;
    esac
}
_gol_validate() {
    case $1 in
	i)   [[ "$2" =~ ^[-+]?[0-9]+$ ]]            || _gol_die "$2: not an integer" ;;
	f)   [[ "$2" =~ ^[-+]?[0-9]*(\.[0-9]+)?$ ]] || _gol_die "$2: not a number" ;;
	\(*) declare -a error=([1]="$2: invalid argument" [2]="$1: something wrong")
	     eval "[[ \"$2\" =~ $1 ]]" || _gol_die "${error[$?]}" ;;
	*)   _gol_die "$1: unkown validation pattern" ;;
    esac
}
gol_callback () { _gol_redirect "$@" ; }
gol_callback_() {
    while (($# > 0)) ; do
	local name=$1 callback=${2:-$1}
	[[ $callback =~ ^[_[:alnum:]] ]] || callback=$name
	_gol_hook "$name" "${callback//-/_}"
	shift $(( $# >= 2 ? 2 : 1 ))
    done
    return 0
}
gol_help () { _gol_redirect "$@" ; }
gol_help_() {
    (( $# < 2 )) && { _gol_show_help "$@" ; return 0 ; }
    while (($# > 1)) ; do _gol_help "$1" "$2" ; shift 2 ; done
}
_gol_show_help() { local key aliases ;
    (( $# > 0 )) && echo "$1" || { [[ ${USAGE-} ]] && echo "$USAGE" ; }
    for key in "${!_opts[@]}" ; do
	aliases="$(_gol_saila "$key")" || continue
	printf '    %s\t%1s\t%s\n' "$(_gol_optize $key)" "$(_gol_optize $aliases)" "$(_gol_help $key)"
    done | sort | column -s $'\t' -t
}
_gol_optize() { local name opt opts eq ;
    for name in "$@"; do
	(( ${#name} > 1 )) && opt=--$name eq='=' || opt=-$name eq=
	case "${_opts[$name]:0:1}" in
	    [$IS_WANT])  opt+="$eq#" ;;
	    [$IS_ARRAY]) opt+="$eq#[,#]" ;;
	    [$IS_HASH])  opt+="$eq#=#" ;;
	    [$IS_FREE])  (( ${#name} > 1 )) && opt+="[=#]" ;;
	esac
	opts+=("$opt")
    done
    printf '%s\n' "${opts[*]}"
}
gol_parse () { _gol_redirect "$@" ; }
gol_parse_() { local gol_OPT SAVEARG=() SAVEIND= ;
    local optstring="$(gol_optstring_)" ; _gol_debug "OPTSTRING=$optstring" ;
    for (( OPTIND=1 ; OPTIND <= $# ; OPTIND++ )) ; do
	while getopts "$optstring" gol_OPT ; do
	    gol_getopts_ "$gol_OPT" "$@" || {
		_gol_debug "SAVE ERROR: ${@:$((OPTIND-1)):1}"
		SAVEARG+=("${@:$((OPTIND-1)):1}")
	    }
	done
	: ${SAVEIND:=$OPTIND}
	[[ ! $PERMUTE || $OPTIND > $# || ${@:$(($OPTIND-1)):1} == -- ]] && break
	_gol_debug "SAVE PARAM: ${!OPTIND}"
	SAVEARG+=(${!OPTIND})
    done
    [[ $PERMUTE ]] && set -- "${SAVEARG[@]}" "${@:$OPTIND}" || shift $(( OPTIND - 1 ))
    OPTIND=${SAVEIND:-$OPTIND}
    _gol_debug "ARGV=(${@@Q})"
    [[ $PERMUTE ]] && { declare -n _gol_argv=$PERMUTE ; _gol_argv=("$@") ; }
    return 0
}
gol_set () { _gol_redirect "$@" ; }
gol_set_() {
    [[ $PERMUTE ]] && printf 'set -- "${%s[@]}"\n' "$PERMUTE" \
		   || echo 'shift $(( OPTIND-1 ))'
}
getoptlong () {
    case $1 in
	init|parse|set|configure|getopts|callback|dump|help) gol_$1 "${@:2}" ;;
	version) echo ${GOL_VERSION} ;;
	*)       _gol_die "unknown subcommand -- $1" ;;
    esac
}
