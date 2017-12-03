#!/bin/bash
#
# git extension to access GitHub API from shell:
# Usage: git hub [option..] command [args..]
# Help:  git hub help
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

# I am sorry, but I think condensed shell code is more readable,
# so I try to do things nicely within a single line if possible.

# Some constants
SECTION=git-hub
SETTINGS=(user)

# Following oneliners are very helpful and expressive
# (and do not change the error code, BTW)
IF()      { local e=$?; $1 && "${@:2}"; return $e; }
STDOUT()  { local e=$?; printf '%q' "$1"; [ 1 = $# ] || printf ' %q' "${@:2}"; printf '\n'; return $e; }
STDERR()  { STDOUT "$@" >&2; }
OOPS()    { STDERR OOPS: "$@"; exit 23; }
DEBUG()   { IF $hub_debug STDERR debug: "$@"; }
NOTE()    { IF $hub_noquiet STDOUT note: "$@"; }
VERBOSE() { IF $hub_verbose STDOUT note: "$@"; }
WARN()    { STDERR warn: "$@"; }
ERR()     { STDERR err$?: "$@"; }

# implicite error checking
x() { DEBUG exec: "$@"; "$@"; DEBUG ret$?: "$@"; }	# "x command args.." allowed to fail
o() { x "$@" || OOPS fail $?: "$@"; }			# "o command args.." must not fail
O() { o "$@"; VERBOSE "$@"; }				# "O command args.." verbose o
N() { o "$@"; NOTE "$@"; }				# "N command args.." noted o
# v VAR cmd args..: set a variable to the output of the command, with error checking
V() { unset -v v; printf -v "$1" "%s" "$2"; }	# see http://wiki.bash-hackers.org/commands/builtin/unset#unset2
v() { local v; v="$(x "${@:2}")" || OOPS fail $?: "$@"; V "$1" "$v"; }

set-vars()
{
hub_debug=false
hub_verbose=false
hub_noquiet=true
hub_global=--local
hub_user=""
}
set-vars

# Check if we are running from git.
# Well, no, I do not think this is the right thing to do here.
# However I found no other way than to check PATH for what git adds there.
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

# Check if $1 is a known command
# A commands has a function Ccommand (with a captital letter C appended)
: good-command command
good-command()
{
case "$1" in
(*:[^a-z]*)	OOPS command "$1": contains illegal characters;;
esac
declare -f "C$1" >/dev/null || OOPS command "$1": unknown
}

# Check if arguments given to shell function are within bounds
: args min max "$@"
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

# Little formatter for Chelp.  Yes, this is a hack.
: indent
indent()
{
o awk -F':' '
/^[[:space:]]/	{ gsub(/^[[:space:]]*/,""); more[++mo]=$0; pos[nr]=mo; next; }
NF==1		{ print "Usage: " $0; next; }
		{ txt[++nr]=$1; if (length($1)>min) min=length($1); sub(/^[^:]*:/, "", $0); rest[nr]=$0; next; }
END		{ for (i=0; ++i<=nr; ) { printf("%d %-*s%s\n", i, min+1, txt[i] ":", rest[i]); while (j<pos[i]) printf("%d %*s  %s\n", i, min, "", more[++j]); } }'
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
(1:*)		good-command "$1"; sed -e "1,/^##$1[^a-z]/d" -e '/^[^#]/,$d' -e 's/^#//' -e 's/^ /git hub /' "$0" | indent;;
*)		OOPS internal error;;
esac
return 42
}

: config-set
config-set()
{
n=0
while read -d '' -u 6 value
do
	let n++ && NOTE was: git config $hub_global "$SECTION.$1" "$have"
	have="$value"
done 6< <(git config $hub_global -z --get-all "$SECTION.$1")

[ 1 = $n ] && [ ".$have" = ".$2" ] && return 6	# 6 is always right

[ 0 = $n ] || NOTE was: git config $hub_global "$SECTION.$1" "$have"

N git config $hub_global --replace-all "$SECTION.$1" "$2"
}

config-get-any()
{
x git config --get "$SECTION.$1"
}

# We cannot detect catastrophic failure,
# as this command fails on nonexistent sections, too.
# unknoen key returns 1 while failure returns 1, too.
config-get-regexp--z()
{
x git config $hub_global -z --get-regexp "$1"
}

##init [username]: initialize config
# init: copy global config to local/global config
# init username: set default GitHub username to use.
#	If username is empty (''), try to guess user.
#	See also: option --user=username
: Cinit
Cinit()
{
local a b
args 0 1 "$@"
[ 1 = $# ] && config-set user "$1"
for a in "${SETTINGS[@]}"
do
	v b config-get-any "$a"
	config-set "$a" "$b"
done
}

##deinit: remove config
# deinit: remove local config
# --global deinit: remove global config
: Cdeinit
Cdeinit()
{
local k v
while	IFS=$'\n' read -d '' -u6 k v
do
	NOTE was: git config $hub_global "$k" "$v"
done 6< <(config-get-regexp--z "$SECTION.")
O git config $hub_global --remove-section "$SECTION"
}

# Wrap all the main functionality
: run
run()
{
check-git
while	:
do
	case "$#:$1" in
	(*:--debug)	hub_debug=:;;			#-: use global .gitconfig instead of local .git/config
	(*:--global)	hub_global=--global;;		#-: use global .gitconfig instead of local .git/config
	(*:--quiet)	hub_noquiet=false;;		#-: be more quiet
	(*:--user=*)	hub_user="${1#--user=}":;;	#-username: override default GitHub username
	(*:--verbose)	hub_verbose=:;;			#-: verbose output
	(*:'')		STDERR try: git "${0##*git-}" help; return 23;;
	(*)		good-command "$1"; "C$1" "${@:2}"; return;;
	esac
	shift
done
}

# Run it.  The sourced-check only works for BASH
unset BASH_SOURCE 2>/dev/null
[ ".$0" != ".$BASH_SOURCE" ] || run "$@"

