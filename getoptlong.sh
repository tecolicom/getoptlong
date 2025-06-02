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
_gol_incr()  { [[ $1 =~ ^[0-9]+$ ]] && echo $(( $1 + 1 )) || echo 1 ; }
_gol_redirect() { local name ;
    declare -n _opts=$GOL_OPTHASH
    declare -n MATCH=BASH_REMATCH
    _gol_debug "${FUNCNAME[1]}(${@@Q})"
    local MARKS=':~!&' MK_DEST=':' MK_ALIAS='~' MK_HOOK='!' MK_CONF='&' \
	  KINDS=':@%+?' IS_NEED=":@%" IS_MUST=":" IS_MAY="?" IS_ARRAY="@" IS_HASH="%" IS_INCR="+"
    local CONFIG=(EXIT_ON_ERROR SILENT PERMUTE DEBUG PREFIX)
    for name in "${CONFIG[@]}" ; do declare $name="${_opts[&$name]}" ; done
    "${FUNCNAME[1]}_" "$@"
}
gol_dump() {
    declare -p $GOL_OPTHASH | grep -oE '\[[^]]*\]="[^"]*"' | sort
}
gol_init() { local key ;
    (( $# == 0 )) && { echo 'local GOL_OPTHASH OPTIND=1' ; return ; }
    declare -A GOL_CONFIG=(
	[PERMUTE]=GOL_ARGV [EXIT_ON_ERROR]=1 [PREFIX]= [SILENT]= [DEBUG]=
    )
    declare -n _opts=$1
    for key in "${!GOL_CONFIG[@]}" ; do _opts[&$key]="${GOL_CONFIG[$key]}" ; done
    GOL_OPTHASH=$1
    (( $# > 1 )) && gol_configure "${@:2}"
    _gol_redirect
}
################################################################################
gol_init_() { local key ;
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^[$MARKS] ]] && continue
	[[ $key =~ ^([-_ \|[:alnum:]]+)([$KINDS]*)( *)$ ]] || _gol_die "[$key] -- invalid"
	local names=${MATCH[1]} dest=${MATCH[2]} aliases alias
	local initial="${_opts[$key]}"
	IFS=' |' read -a aliases <<<$names
	local name=${aliases[0]}
	local targetname="${PREFIX}${name}"
	declare -n target=$targetname
	unset _opts["$key"]
	_opts[$name]=$targetname
	_gol_dest "$name" "$dest"
	for alias in "${aliases[@]:1}" ; do
	    _gol_alias "$alias" "$name"
	    _gol_dest  "$alias" "$dest"
	    _opts[$alias]=$targetname
	done
	case $dest in
	    [$IS_MAY]) ;;
	    [$IS_ARRAY]|[$IS_HASH])
		[[ $dest == $IS_ARRAY && ! -v $targetname ]] && declare -ga $targetname
		[[ $dest == $IS_HASH  && ! -v $targetname ]] && declare -gA $targetname
		if [[ $initial =~ ^\(.*\)$ ]] ; then
		    eval "$targetname=$initial"
		else
		    [[ $dest == $IS_ARRAY ]] && target=(${initial:+"$initial"})
		    [[ $dest == $IS_HASH  ]] && [[ $initial ]] && _gol_die "$initial: invalid hash data"
		fi
		;;
	    *)
		target=$initial ;;
	esac
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
gol_optstring () { _gol_redirect "$@" ; }
gol_optstring_() { local key string ;
    for key in "${!_opts[@]}" ; do
	[[ $key =~ ^${MK_DEST}(.)$ ]] || continue
	string+=${MATCH[1]}
	[[ ${_opts[$key]} =~ [$IS_NEED] ]] && string+=:
    done
    echo "${SILENT:+:}${string}-:"
}
gol_getopts () { _gol_redirect "$@" ; }
gol_getopts_() { local name val dest callback hook ;
    local opt="$1"; shift;
    case $opt in
	[:?])
	    hook=$(_gol_hook "$opt") && [[ $hook ]] && $hook "$OPTARG"
	    [[ $EXIT_ON_ERROR ]] && exit 1 || return 0
	    ;;
	-)
	    [[ $OPTARG =~ ^(no-)?([-_[:alnum:]]+)(=(.*))? ]] || die "$OPTARG: unrecognized option"
	    local no="${MATCH[1]}" name="${MATCH[2]}" param="${MATCH[3]}"; val="${MATCH[4]}"
	    [[ ${_opts[$name]+_} ]] || _gol_die "no such option -- $name"
	    declare -n target="${_opts[$name]}"
	    dest=$(_gol_dest $name)
	    if [[ $param ]] ; then
		[[ $dest =~ [${IS_NEED}${IS_MAY}] ]] || die "does not take an argument -- $name"
	    else
		case $dest in
		    [$IS_MAY]) ;;
		    [$IS_NEED])
			(( OPTIND > $# )) && _gol_die "option requires an argument -- $name"
			val=${@:$OPTIND:1}
			(( OPTIND++ ))
			;;
		    *) [[ $no ]] && val= || unset val ;;
		esac
	    fi
	    ;;
	*)
	    name=$opt
	    declare -n target="${_opts[$name]}"
	    case ${dest:=$(_gol_dest "$name")} in
		[$IS_MAY])  val="${OPTARG:-}" ;;
		[$IS_NEED]) val="${OPTARG}" ;;
	    esac
	    ;;
    esac
    case $dest in
	[$IS_ARRAY]) target+=($val) ;;
	[$IS_HASH])  [[ $val =~ = ]] && target["${val%%=*}"]="${val#*=}" || target[$val]=1 ;;
	*)           target=${val-$(_gol_incr "$target")} ;;
    esac
    hook=$(_gol_alias $name) || hook=$name
    callback="$(_gol_hook $hook)" && $callback "$target"
    return 0
}
gol_callback () { _gol_redirect "$@" ; }
gol_callback_() {
    declare -a config=("$@")
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
