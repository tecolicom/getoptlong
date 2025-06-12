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
    local _key="$1"
    [[ $_key =~ ^[$MARKS]$ ]] && _key+="$2" && shift
    (($# == 2)) && _opts["$_key"]="$2" && return 0
    [[ -v _opts[$_key] ]] && echo "${_opts[$_key]}" || return 1
}
_gol_alias() { _gol_opts "$MK_ALIAS" "$@" ; }
_gol_saila() { _gol_opts "$MK_SAILA" "$@" ; }
_gol_hook()  { _gol_opts "$MK_HOOK"  "$@" ; }
_gol_rule()  { _gol_opts "$MK_RULE"  "$@" ; }
_gol_help()  { _gol_opts "$MK_HELP"  "$@" ; }
_gol_type()  { echo "${_opts["$1"]:0:1}" ; }
_gol_debug() { [[ ${_opts["&DEBUG"]:-} ]] && _gol_warn DEBUG: "${@}" || : ; }
_gol_incr()  { [[ $1 =~ ^[0-9]+$ ]] && echo $(( $1 + 1 )) || echo 1 ; }
_gol_redirect() { local _name ;
    declare -n _opts=$GOL_OPTHASH
    declare -n MATCH=BASH_REMATCH
    _gol_debug "${FUNCNAME[1]}(${@@Q})"
    local MARKS='><!&=#' MK_ALIAS='>' MK_SAILA='<' MK_HOOK='!' MK_CONF='&' MK_RULE='=' MK_HELP='#' \
	  IS_ANY='+:?@%' IS_REQ=":@%" IS_FLAG="+" IS_NEED=":" IS_MAYB="?" IS_LIST="@" IS_HASH="%" \
	  CONFIG=(EXIT_ON_ERROR SILENT PERMUTE REQUIRE DEBUG PREFIX DELIM USAGE HELP)
    for _name in "${CONFIG[@]}" ; do declare $_name="${_opts[&$_name]=}" ; done
    "${FUNCNAME[1]}_" "$@"
}
gol_dump () { _gol_redirect "$@" ; }
gol_dump_() { local _all= _key ;
    case "${1-}" in -a|--all) _all=1 ;; esac
    for _key in "${!_opts[@]}" ; do
	[[ $_all ]] && printf '[%s]=%s\n' "${_key}" "${_opts["$_key"]@Q}"
	[[ $_key =~ ^[[:alnum:]_] && ${_opts[$_key]} =~ ([$IS_ANY])($PREFIX(.*)) && ${_key//-/_} == ${MATCH[3]} ]] && {
	    local _vname=${MATCH[2]}
	    [[ $(declare -p $_vname 2> /dev/null) =~ declare( )(..)( )(.*) ]] && echo "${MATCH[4]}" || echo "$_vname=unset"
	}
    done | sort
}
gol_init() { local _key ;
    (( $# == 0 )) && { echo '(( ${#FUNCNAME[@]} > 0 )) && local GOL_OPTHASH OPTIND=1 || OPTIND=1' ; return ; }
    declare -n _opts=$1
    declare -A GOL_CONFIG=([PERMUTE]=GOL_ARGV [EXIT_ON_ERROR]=1 [DELIM]=$' \t,' [HELP]='help|h#show help')
    for _key in "${!GOL_CONFIG[@]}" ; do : ${_opts["&$_key"]="${GOL_CONFIG[$_key]}"} ; done
    GOL_OPTHASH=$1
    (( $# > 1 )) && gol_configure "${@:2}"
    _gol_redirect
} ################################################################################
gol_init_() { local _key _aliases _alias _help ;
    [[ $REQUIRE && $GOL_VERSION < $REQUIRE ]] && _gol_die "getoptlong version $GOL_VERSION < $REQUIRE"
    for _key in "${!_opts[@]}" ; do
	[[ $_key =~ ^[$MARKS] ]] && continue
	_gol_init_entry "$_key"
    done
    if [[ $HELP =~ ^( *)([[:alpha:]]+) ]] && _help=${MATCH[2]} && [[ ! -v _opts[$_help] ]] ; then
	_gol_init_entry "$HELP"
	_gol_hook $_help $_help
	declare -F $_help > /dev/null || eval "$_help() { getoptlong help ; exit ; }"
    fi
    return 0
}
_gol_init_entry() { local _entry="$1" ;
    [[ $_entry =~ ^([-_ \|[:alnum:]]+)([$IS_ANY]*)( *)(=([if]|\(.*\)))?( *)(# *(.*[^[:space:]]))? ]] \
	|| _gol_die "[$_entry] -- invalid"
    local _names=${MATCH[1]} _vtype=${MATCH[2]} _type=${MATCH[5]} _comment=${MATCH[8]}
    local _initial="${_opts[$_entry]-}"
    IFS=$' \t|' read -a _aliases <<< ${_names}
    local _name=${_aliases[0]}
    [[ $_name =~ ^[[:alpha:]] ]] || _gol_die "$_name: option name must start with alphabet"
    local _vname="${PREFIX}${_name//-/_}"
    unset _opts["$_entry"]
    case ${_vtype:=$IS_FLAG} in
	[$IS_MAYB])
	    [[ $_initial ]] && _gol_die "$_initial: optional parameter can't be initialized" ;;
	[$IS_LIST]|[$IS_HASH])
	    [[ $_vtype == $IS_LIST && ! -v $_vname ]] && declare -ga $_vname
	    [[ $_vtype == $IS_HASH && ! -v $_vname ]] && declare -gA $_vname
	    if [[ $_initial =~ ^\(.*\)$ ]] ; then
		eval "$_vname=$_initial"
	    else
		[[ $_vtype == $IS_LIST ]] && _gol_set_array $_vname ${_initial:+"$_initial"}
		[[ $_vtype == $IS_HASH ]] && [[ $_initial ]] && _gol_die "$_initial: invalid hash data"
	    fi
	    ;;
	[$IS_NEED]|[$IS_FLAG])
	    _gol_value $_vname "$_initial" ;;
    esac
    _opts[$_name]="${_vtype}${_vname}"
    [[ $_type ]] && _gol_rule $_name "$_type"
    for _alias in "${_aliases[@]:1}" ; do
	_opts[$_alias]="${_opts[$_name]}"
	_gol_alias $_alias $_name
    done
    _gol_saila $_name "${_aliases[*]:1}"
    [[ $_comment ]] && _gol_help "$_name" "$_comment"
    return 0
}
gol_configure () { _gol_redirect "$@" ; }
gol_configure_() { local _param _key _val ;
    for _param in "$@" ; do
	[[ $_param =~ ^[[:alnum:]] ]] || _gol_die "$_param -- invalid config parameter"
	_key="${MK_CONF}${_param%%=*}"
	[[ $_param =~ =(.*) ]] && _val="${MATCH[1]}" || _val=1
	[[ -v _opts[$_key] ]] || _gol_die "$_param -- invalid config parameter"
	_opts[$_key]="$_val"
    done
    return 0
}
gol_optstring_() { local _key _string ;
    for _key in "${!_opts[@]}" ; do
	[[ $_key =~ ^[[:alnum:]]$ ]] && _string+=$_key || continue
	[[ ${_opts[$_key]} =~ ^[$IS_REQ] ]] && _string+=:
    done
    echo "${SILENT:+:}${_string:- }-:"
}
gol_getopts () { _gol_redirect "$@" ; }
gol_getopts_() { local _optname _val _vtype _vname _name _callback ;
    local _opt="$1"; shift;
    case $_opt in
	[:?]) _callback=$(_gol_hook "$_opt") && [[ $_callback ]] && $_callback "$OPTARG"
	      [[ $EXIT_ON_ERROR ]] && exit 1 || return 1 ;;
	-) _gol_getopts_long "$@" || return $? ;;
	*) _gol_getopts_short || return $? ;;
    esac
    _name=$(_gol_alias ${_optname:-$_opt}) || _name=${_optname:=$_opt}
    _gol_getopts_store
    _callback="$(_gol_hook $_name)" && $_callback "$_val"
    return 0
}
_gol_getopts_long() { local _non _param ;
    [[ $OPTARG =~ ^(no-)?([-_[:alnum:]]+)(=(.*))? ]] || _gol_die "$OPTARG: unrecognized option"
    _non="${MATCH[1]}" _optname="${MATCH[2]}" _param="${MATCH[3]}" _val="${MATCH[4]}"
    [[ $(_gol_opts $_optname) =~ ^([$IS_ANY])([_[:alnum:]]+) ]] || {
	[[ $EXIT_ON_ERROR ]] && _gol_die "no such option -- --$_optname" || return 2
    }
    _vtype=${MATCH[1]} _vname=${MATCH[2]}
    if [[ $_param ]] ; then
	[[ $_vtype =~ [${IS_REQ}${IS_MAYB}] ]] || _gol_die "does not take an argument -- $_optname"
    else
	case $_vtype in
	    [$IS_MAYB]) ;;
	    [$IS_REQ])
		(( OPTIND > $# )) && _gol_die "option requires an argument -- $_optname"
		_val="${@:$((OPTIND++)):1}" ;;
	    *) [[ $_non ]] && _val= || unset _val ;;
	esac
    fi
    return 0
}
_gol_getopts_short() {
    [[ ${_opts[$_opt]-} =~ ^([$IS_ANY])([_[:alnum:]]+) ]] || {
	[[ $EXIT_ON_ERROR ]] && _gol_die "no such option -- -$_opt" || return 3
    }
    _vtype=${MATCH[1]} _vname=${MATCH[2]}
    [[ $_vtype =~ [${IS_MAYB}${IS_REQ}] ]] && _val="${OPTARG:-}"
    return 0
}
_gol_getopts_store() { local _vals ;
    local _check=$(_gol_rule $_name)
    case $_vtype in
	[$IS_LIST]|[$IS_HASH])
	    [[ $_val =~ $'\n' ]] && readarray -t _vals <<< ${_val%$'\n'} \
				|| IFS="${DELIM}" read -a _vals <<< ${_val}
	    for _val in "${_vals[@]}" ; do
		[[ $_check ]] && _gol_validate "$_check" "$_val"
		case $_vtype in
		[$IS_LIST]) _gol_set_array $_vname "$_val" ;;
		[$IS_HASH])
		    [[ $_val =~ = ]] && _gol_set_hash $_vname "${_val%%=*}" "${_val#*=}" \
				    || _gol_set_hash $_vname "$_val" 1 ;;
		esac
	    done
	    ;;
	*) [[ $_check ]] && _gol_validate "$_check" "$_val"
	   _gol_value $_vname "${_val=$(_gol_incr "$(_gol_value $_vname)")}" ;;
    esac
}
_gol_value() {
    declare -n __target__="$1"
    (( $# > 1 )) && __target__="$2" || echo "$__target__"
}
_gol_set_array() { declare -n __target__="$1" ; __target__+=("${@:2}") ; }
_gol_set_hash()  { declare -n __target__="$1" ; __target__["$2"]="$3" ; }
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
	local _name=$1 _callback=${2:-$1}
	[[ $_callback =~ ^[_[:alnum:]] ]] || _callback=$_name
	_gol_hook "$_name" "${_callback//-/_}"
	shift $(( $# >= 2 ? 2 : 1 ))
    done
    return 0
}
gol_help () { _gol_redirect "$@" ; }
gol_help_() {
    (( $# < 2 )) && { _gol_show_help "$@" ; return 0 ; }
    while (($# > 1)) ; do _gol_help "$1" "$2" ; shift 2 ; done
}
_gol_show_help() { local _key aliases ;
    echo "${1:-${USAGE:-$(basename $0) [ options ] args}}"
    for _key in "${!_opts[@]}" ; do
	aliases="$(_gol_saila "$_key")" || continue
	msg="$(_gol_help $_key)" || {
	    case "$(_gol_type $_key)" in
		[$IS_FLAG]) msg="enable ${_key^^}" ;;
		[$IS_NEED]) msg="set ${_key^^}" ;;
		[$IS_LIST]) msg="add item(s) to ${_key^^}" ;;
		[$IS_HASH]) msg="set KEY=VALUE(s) in ${_key^^}" ;;
		[$IS_MAYB]) msg="enable/set ${_key^^}" ;;
	    esac
	}
	printf '    %s\t%1s\t%s\n' "$(_gol_optize $_key)" "$(_gol_optize $aliases)" "$msg"
    done | sort | column -s $'\t' -t
}
_gol_optize() { local _name _opt _optlist _eq ;
    for _name in "$@"; do
	(( ${#_name} > 1 )) && _opt=--$_name _eq='=' || _opt=-$_name _eq=
	case "$(_gol_type $_name)" in
	    [$IS_NEED]) _opt+="$_eq#" ;;
	    [$IS_LIST]) _opt+="$_eq#[,#]" ;;
	    [$IS_HASH]) _opt+="$_eq#=#" ;;
	    [$IS_MAYB]) (( ${#_name} > 1 )) && _opt+="[=#]" ;;
	esac
	_optlist+=("$_opt")
    done
    printf '%s\n' "${_optlist[*]}"
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
	SAVEARG+=("${!OPTIND}")
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
