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
    [[ $key =~ ^[$MARKS]$ ]] && key+="$2" && shift
    (($# == 2)) && _opts["$key"]="$2" && return 0
    [[ -v _opts[$key] ]] && echo "${_opts[$key]}" || return 1
}
_gol_alias() { _gol_opts "$MK_ALIAS" "$@" ; }
_gol_saila() { _gol_opts "$MK_SAILA" "$@" ; }
_gol_hook()  { _gol_opts "$MK_HOOK"  "$@" ; }
_gol_rule()  { _gol_opts "$MK_RULE"  "$@" ; }
_gol_help()  { _gol_opts "$MK_HELP"  "$@" ; }
_gol_type()  { echo "${_opts["$1"]:0:1}" ; }
_gol_debug() { [[ ${_opts["&DEBUG"]:-} ]] && _gol_warn DEBUG: "${@}" || : ; }
_gol_incr()  { [[ $1 =~ ^[0-9]+$ ]] && echo $(( $1 + 1 )) || echo 1 ; }
_gol_redirect() { local name ;
    declare -n _opts=$GOL_OPTHASH
    declare -n MATCH=BASH_REMATCH
    _gol_debug "${FUNCNAME[1]}(${@@Q})"
    local MARKS='><!&=#' MK_ALIAS='>' MK_SAILA='<' MK_HOOK='!' MK_CONF='&' MK_RULE='=' MK_HELP='#' \
	  IS_ANY='+:?@%' IS_REQ=":@%" IS_FLAG="+" IS_NEED=":" IS_MAYB="?" IS_LIST="@" IS_HASH="%" \
	  CONFIG=(EXIT_ON_ERROR SILENT PERMUTE REQUIRE DEBUG PREFIX DELIM USAGE HELP)
    for name in "${CONFIG[@]}" ; do declare $name="${_opts[&$name]=}" ; done
    "${FUNCNAME[1]}_" "$@"
}
gol_dump () { _gol_redirect "$@" ; }
gol_dump_() { local all= ;
    case "${1-}" in -a|--all) all=1 ;; esac
    for key in "${!_opts[@]}" ; do
	[[ $all ]] && printf '[%s]=%s\n' "${key}" "${_opts["$key"]@Q}"
	[[ $key =~ ^[[:alnum:]_] && ${_opts[$key]} =~ ([$IS_ANY])($PREFIX(.*)) && ${key//-/_} == ${MATCH[3]} ]] && {
	    local vname=${MATCH[2]}
	    [[ $(declare -p $vname 2> /dev/null) =~ declare( )(..)( )(.*) ]] && echo "${MATCH[4]}" || echo "$vname=unset"
	}
    done | sort
}
gol_init() { local key ;
    (( $# == 0 )) && { echo '(( ${#FUNCNAME[@]} > 0 )) && local GOL_OPTHASH OPTIND=1 || OPTIND=1' ; return ; }
    declare -n _opts=$1
    declare -A GOL_CONFIG=([PERMUTE]=GOL_ARGV [EXIT_ON_ERROR]=1 [DELIM]=$' \t,' [HELP]='help|h#show help')
    for key in "${!GOL_CONFIG[@]}" ; do : ${_opts["&$key"]="${GOL_CONFIG[$key]}"} ; done
    GOL_OPTHASH=$1
    (( $# > 1 )) && gol_configure "${@:2}"
    _gol_redirect
} ################################################################################
gol_init_() { local key _aliases _alias _help ;
    [[ $REQUIRE && $GOL_VERSION < $REQUIRE ]] && _gol_die "getoptlong version $GOL_VERSION < $REQUIRE"
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[$MARKS] ]] && continue
	_gol_init_entry "$key"
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
	[[ $key =~ ^[[:alnum:]]$ ]] && string+=$key || continue
	[[ ${_opts[$key]} =~ ^[$IS_REQ] ]] && string+=:
    done
    echo "${SILENT:+:}${string:- }-:"
}
gol_getopts () { _gol_redirect "$@" ; }
gol_getopts_() { local optname val vtype _vname name callback ;
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
    vtype=${MATCH[1]} _vname=${MATCH[2]}
    if [[ $param ]] ; then
	[[ $vtype =~ [${IS_REQ}${IS_MAYB}] ]] || _gol_die "does not take an argument -- $optname"
    else
	case $vtype in
	    [$IS_MAYB]) ;;
	    [$IS_REQ])
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
    vtype=${MATCH[1]} _vname=${MATCH[2]}
    [[ $vtype =~ [${IS_MAYB}${IS_REQ}] ]] && val="${OPTARG:-}"
    return 0
}
_gol_getopts_store() { local _vals ;
    local _check=$(_gol_rule $name)
    case $vtype in
	[$IS_LIST]|[$IS_HASH])
	    [[ $val =~ $'\n' ]] && readarray -t _vals <<< ${val%$'\n'} \
				|| IFS="${DELIM}" read -a _vals <<< ${val}
	    for val in "${_vals[@]}" ; do
		[[ $_check ]] && _gol_validate "$_check" "$val"
		case $vtype in
		[$IS_LIST]) _gol_set_array $_vname "$val" ;;
		[$IS_HASH])
		    [[ $val =~ = ]] && _gol_set_hash $_vname "${val%%=*}" "${val#*=}" \
				    || _gol_set_hash $_vname "$val" 1 ;;
		esac
	    done
	    ;;
	*) [[ $_check ]] && _gol_validate "$_check" "$val"
	   _gol_value $_vname "${val=$(_gol_incr "$(_gol_value $_vname)")}" ;;
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
    echo "${1:-${USAGE:-$(basename $0) [ options ] args}}"
    for key in "${!_opts[@]}" ; do
	aliases="$(_gol_saila "$key")" || continue
	msg="$(_gol_help $key)" || {
	    case "$(_gol_type $key)" in
		[$IS_FLAG]) msg="enable ${key^^}" ;;
		[$IS_NEED]) msg="set ${key^^}" ;;
		[$IS_LIST]) msg="add item(s) to ${key^^}" ;;
		[$IS_HASH]) msg="set KEY=VALUE(s) in ${key^^}" ;;
		[$IS_MAYB]) msg="enable/set ${key^^}" ;;
	    esac
	}
	printf '    %s\t%1s\t%s\n' "$(_gol_optize $key)" "$(_gol_optize $aliases)" "$msg"
    done | sort | column -s $'\t' -t
}
_gol_optize() { local name opt opts eq ;
    for name in "$@"; do
	(( ${#name} > 1 )) && opt=--$name eq='=' || opt=-$name eq=
	case "$(_gol_type $name)" in
	    [$IS_NEED]) opt+="$eq#" ;;
	    [$IS_LIST]) opt+="$eq#[,#]" ;;
	    [$IS_HASH]) opt+="$eq#=#" ;;
	    [$IS_MAYB]) (( ${#name} > 1 )) && opt+="[=#]" ;;
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
