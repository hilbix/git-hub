#!/bin/bash

STDOUT() { local e=$?; printf '%q' "$1"; printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR() { STDOUT "$@" >&2; }
OOPS()   { STDERR OOPS: "$@"; exit 23; }
WARN()   { STDERR warn: "$@"; }
ERR()    { STDERR err$?: "$@"; }

x() { "$@"; }
o() { x "$@" || OOPS fail $?: "$@"; }

: check-git
check-git()
{
case "$PATH" in
(*/git-core:*)	;;
(*)		WARN --------------------------------------------------
		WARN : Expect some irregular output if called directly.
		WARN : Please call this command via git like:
		WARN : git hub "$@"
		WARN --------------------------------------------------
		;;
esac
}

: good-command
good-command()
{
case "$1" in
(*:[^a-z]*)	OOPS command "$1": contains illegal characters;;
esac
declare -f "C$1" >/dev/null || OOPS command "$1": unknown
}

: args
args()
{
local min="$1" max="$2"
shift 2
[ $# -ge "$min" ] && [ $# -le "${max:=$#}" ] && return
c="$(caller 0)"
c="${c#* C}"
c="${c%% *}"
help "$c"
OOPS git hub "$c": wrong number of arguments
}

: indent
indent()
{
o awk -F':' '
/^[[:space:]]/	{ gsub(/^[[:space:]]*/,""); more[++mo]=$0; pos[nr]=mo; next; }
NF==1	{ print "Usage: " $0; next; }
	{ txt[++nr]=$1; if (length($1)>min) min=length($1); sub(/^[^:]*:/, "", $0); rest[nr]=$0; next; }
END	{
	for (i=0; ++i<=nr; )
		{
		printf("%d %-*s%s\n", i, min+1, txt[i] ":", rest[i]);
		while (j<pos[i])
			printf("%d %*s  %s\n", i, min, "", more[++j]);
		}
	}'
}


: help
help()
{
good-command "$1"
sed -e "1,/^##$1[^a-z]/d" -e '/^[^#]/,$d' -e 's/^#//' -e 's/^ /git hub /' "$0"
}

##[--options] command [args..]
##help [command]: show help
# help: list all known commands
# help options: show help for possible options
# help command: give help for the given command
: Chelp
Chelp()
{
args 0 1 "$@"
case "$#:$1" in
(0:)		sed -n "s/^##\([^#]\)/git hub \1/p" "$0" | indent;;
(1:options)	sed -n 's/^[^-]*\(--[a-z=]*\)\?.*#''-/option \1/p' "$0" | indent;;
(1:*)		help "$1" | indent;;
*)		OOPS internal error;;
esac
return 42
}

##init [username]: initialize config
# init: copy global config to local/global config
# init username: set default GitHub username to use.
#	If username is empty (''), try to guess user.
#	See also: option --user=username
: Cinit
Cinit()
{
:
}

##deinit: remove config
# deinit: remove local config
# --global deinit: remove global config
Cdeinit()
{
:
}

: run
run()
{
check-git
verbose=false
quiet=false
glbl=false
user=""
while	:
do
	case "$#:$1" in
	(*:--global)	glbl=:;;		#-: use global .gitconfig instead of local .git/config
	(*:--quiet)	quiet==:;;		#-: be more quiet
	(*:--user=*)	user="${1#--user=}":;;	#-username: override default GitHub username
	(*:--verbose)	verbose=:;;		#-: verbose output
	(*:'')		STDERR try: git "${0##*git-}" help; return 23;;
	(*)		good-command "$1"; "C$1" "${@:2}"; return;;
	esac
	shift
done
}

run "$@"

