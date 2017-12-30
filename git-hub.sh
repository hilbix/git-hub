#!/bin/bash
#
# DEV_TOKEN 44c03c1a9009154c4aa4ef22df09beefa05ea10f
#
# git extension to access GitHub API from shell:
# Usage: git hub [option..] command [args..]
# Help:  git hub help
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

# I am sorry, but I think condensed shell code is more readable,
# so I try to do things nicely within a single line if possible.

###
### Some constants
###

HUB_SECTION=git-hub
HUB_SETTINGS=(user cache token)
HUB_CACHEDIR=('/var/tmp/git-hub//', '~/.cache/git-hub/')



###
### one-liners
###

# Following oneliners are very helpful and expressive
# (and do not change the error code, BTW)
UNLESS()  { local e=$?; [ ".$1" = ".$2" ] || "${@:3}"; return $e; }	# "UNLESS "$cmp" "$val" CMD args..", witout affecting $?
STDOUT()  { local e=$? a; printf '#%q' "$1"; for a in "${@:2}"; do case "$hub_insecure:$a" in ([^12]:hidden-*:*) printf ' [HIDDEN]';; (*) printf ' %q' "$a";; esac; done; printf '\n'; return $e; }
STDERR()  { STDOUT "$@" >&2; }
DEBUG()   { UNLESS 0 $hub_debug   STDERR DEBUG\# "$@"; }
NOTE()    { UNLESS 0 $hub_noquiet STDOUT NOTE\# "$@"; }
VERBOSE() { UNLESS 0 $hub_verbose STDOUT NOTE\# "$@"; }
WARN()    { STDERR WARN\# "$@"; }
ERR()     { STDERR ERR\#$? "$@"; }
HINTS()   { UNLESS 0 $hub_noquiet printf '#hint: %s\n' "$@"; }

# Fatals
CALLER()  { local e="$(caller $((1+$1)))"; line="${e%% *}"; e="${e#* }"; file="${e#* }"; fn="${e%% *}"; }
OOPS()    { STDERR OOPS\# "$@"; [ 0 = "$hub_debug" ] || { n=0; while caller $n >&2; do let n++; done; }; exit 23; }
INTERNAL() { CALLER "${1:-0}"; OOPS "$file" line "$line" INTERNAL ERROR in function "$fn" "${@:2}"; }
INTERNAL1() { CALLER 0; INTERNAL 2 calling function "$fn"; }
NOTYET() { CALLER "${1:-0}"; OOPS "$file" line "$line" not-yet-implemeted function "$fn" "${@:2}"; }

# Things to support error checking
x() { while [ x = "$1" ]; do shift; done; DEBUG exec: "$@"; "$@"; DEBUG ret$?: "$@"; }	# "x command args.." allowed to fail
o() { x "$@" || UNLESS x "$1" OOPS fail $?: "$@"; }			# "o command args.." must not fail
O() { o "$@"; VERBOSE "$@"; }				# "O command args.." verbose o
N() { o "$@"; NOTE "$@"; }				# "N command args.." noted o
# v VAR cmd args..: set a variable to the output of the command (with error checking if "cmd" is not "x")
# V VAR VAL LOCAL..: set VAR to VAL, taking back "local LOCAL..", not affecting $?
U() { unset -v "$@"; }
V() { set -- $? "$@"; U "${@:4}"; printf -v "$2" "%s" "$3"; return $1; }	# see http://wiki.bash-hackers.org/commands/builtin/unset#unset2
v() { local v; v="$(U v; "${@:2}")" || UNLESS x "$2" OOPS fail $?: "${@:2}"; V "$1" "$v" v; }

# Simple tests
isAlpha() { case "$1" in '') return 1;; (*[^a-zA-Z]*) return 1;; esac; return 0; }
isalpha() { case "$1" in '') return 1;; (*[^a-z]*) return 1;; esac; return 0; }
isAlnum() { case "$1" in '') return 1;; (*[^a-zA-Z0-9]*) return 1;; esac; return 0; }
isalnum() { case "$1" in '') return 1;; (*[^a-z0-9]*) return 1;; esac; return 0; }
validname() { case "$1" in (*[^a-z0-9]*);; ([a-z]*) return 0;; esac; return 1; }



###
### RUNTIME SETTINGS
###

set-vars()
{
for a in ${!hub_@}; do U "$a"; done
hub_debug=0
hub_verbose=0
hub_insecure=0
hub_noquiet=1
hub_global=--local
hub_user=""
}
set-vars



###
### HELPER FUNCTIONS
###

# Check if we are running from git.
# Well, no, I do not think this is the right thing to do here.
# However I found no other way than to check PATH for what git adds there.
: check-git
check-git()
{
case "$PATH" in
(*/git-core:*)	;;
(*)		WARN --------------------------------------------------
		WARN : Expect some irregular output 'if' called directly.
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
[ 1 = $# ] || INTERNAL1
isalnum "$1" || OOPS command does not contain valid characters: "$1"
declare -f "C$1" >/dev/null || OOPS unknown command: "$1"
}



# Check if arguments given to shell function are within bounds
# options.. is a space separated list of --options (without --).
# Variables opt_option are set either 0 (not present) or 1 (present).
#
# sets ARGS to the given arguments
: args 'options..' min max "$@"
args()
{
local opt="$1" min="$2" max="$3"
shift 3 || INTERNAL1

# Preset opt_ variables
for o in $opt
do
	validname "$o" || INTERNAL1
	case "$o" in
	(*=)	printf -v "opt_${o%=}" '';;	# opt= -> content option
	(*)	printf -v "opt_$o" 0;;		# opt -> 0/1 option
	esac
done

# Parse options
while	[ 0 -lt $# ]
do
	t="${1#--}"
	[ ".$t" = ".$1" ] || [ -z "$t" ] && break

	v="${t%%=}"
	o="$v"
	[ ".$v" = ".$t" ] || o="$o="

	validname "$v" || OOPS invalid option "--$o"
	case " $opt " in (*" $o "*) ;; (*) OOPS unknown option "--$o";; esac

	case "$o" in
	(*=)	printf -v "opt_${o%=}" "%s" "${t#*=}";;
	(*)	printf -v "opt_$o" 1;;
	esac
	shift
done

# Check argument count
[ $# -ge "$min" ] && [ $# -le "${max:=$#}" ] && ARGS=("$@") && return

# Bail out, something's wrong
CALLER 0
( helper "${fn#C}" )
OOPS wrong number of arguments: git hub "${fn#C}"
}



# Ask user for something if it is missing
: query variable [prompt]
query()
{
local ans p
local -n notes="QUERY_$1"

#tty >/dev/null || OOPS cannot read "$1" from non-terminal
tty >/dev/null && HINTS "${notes[@]}"

p="${*:2}"
read -rp "${p:-"$1"}? " ans || OOPS cannot read "$1" from terminal/stdin
V "$1" "$ans" ans p
}



###
### Obfuscation
###

# Scramble the argument for "unscramble"
: scramble VAR value
scramble()
{
local rnd enc

v rnd openssl rand -base64 21
v enc openssl enc -aes-128-ctr -e -base64 -A -pass "pass:hidden-$rnd" <<<"$2"
V "$1" "hidden-$rnd:$enc" rnd enc
}



# Unscramble the argument
: unscramble VAR value
unscramble()
{
v "$1" openssl enc -aes-128-ctr -d -base64 -A -pass "pass:${2%%:*}" <<<"${2#*:}"
}



# Decode encoded values on the fly (double --insecure)
: decode-on-the-fly
decode-on-the-fly()
{
local line v

while read -r line
do
	case "$line" in
	(hidden-*:*)	unscramble line "$line";;
	esac
	echo "$line"
done
}



# Check if value needs to be secured
: secured string
secured()
{
case "$hub_insecure:$1" in
(1:*)		echo "$*";;
(2:hidden-*)	decode-on-the-fly <<<"$*";;
(?:hidden-*)	echo "HIDDEN";;
(*)		echo "$1";;
esac
}



###
### git config
###

: config-getall--z key [--local/global/system]
config-getall--z()
{
git config ${2:-$hub_global} -z --get-all "$HUB_SECTION.$1"
}



config-was()
{
NOTE was: git config $hub_global "$HUB_SECTION.$1" "$2"
}



config-dump()
{
while read -d '' -u 6 value
do
	config-was "$1" "$value"
done 6< <(config-getall--z "$@")
}



# unset some configuration
# if all is set (nonempty and not 0), all variants are removed
: config-unset config [all]
config-unset()
{
local ret token

config-dump "$1"

[ 0 = "${2:-0}" ] && N git config $hub_global --unset "$HUB_SECTION.$1" && return

N x git config $hub_global --unset-all "$HUB_SECTION.$1"
ret=$?

#config-get-any token &&

config-dump "$1" --local
N x git config --local --unset-all "$HUB_SECTION.$1"

config-dump "$1" --global
N x git config --global --unset-all "$HUB_SECTION.$1"

config-dump "$1" --system
N x git config --system --unset-all "$HUB_SECTION.$1"

return $ret
}



: config-set key value
config-set()
{
n=0
while read -d '' -u 6 value
do
	let n++ && config-was "$1" "$have"
	have="$value"
done 6< <(config-getall--z "$1")

[ 1 = $n ] && [ ".$have" = ".$2" ] && return 6	# 6 is always right

[ 0 = $n ] || config-was "$1" "$have"

N git config $hub_global --replace-all "$HUB_SECTION.$1" "$2"
}



: config-set-unchanged
config-set-unchanged()
{
config-set "$@"
local ret=$?
[ 6 = $ret ] && VERBOSE unchanged: git config $hub_global "$HUB_SECTION.$1" "$2" && return
return $ret
}



# Fetch from git
# fails if missing
: config-get VAR key
config-get()
{
v "$1" x git config $hub_global --get "$HUB_SECTION.${2:-$1}"
}



# Fetch from git config, following hierarchy
: config-get-any VAR key
config-get-any()
{
v "$1" x git config --get "$HUB_SECTION.${2:-$1}"
}



# We cannot detect catastrophic failure,
# as this command fails on nonexistent sections, too.
# unknoen key returns 1 while failure returns 1, too.
: config-get-regexp--z REGEX
config-get-regexp--z()
{
x git config $hub_global -z --get-regexp "$1"
}



# Fetch some 
: git-config-all key
git-config-all()
{
local s g l c

c=''
printf '('
v s x git config --system --get -- "$1" && { printf '%sglobal=%q' "$c" "$(secured "$s")"; c=' '; }
v g x git config --global --get -- "$1" && [ ".$s" != ".$g" ] && { printf '%sglobal=%q' "$c" "$(secured "$g")"; c=' '; }
v l x git config --local  --get -- "$1" && [ ".$l" != ".$g" ] && { printf '%slocal=%q' "$c" "$(secured "$l")"; c=' '; }
printf ')'
[ -n "$c" ]
}



# Fetch from all git configs
: config-get-all VAR key
config-get-all()
{
v "$1" x git-config-all "$HUB_SECTION.$2"
}



###
### Commands section
###

# Little formatter for Chelp.  Yes, this is a hack.
# The leading #number has multiple purpose:
# - prevent accidental execution of a copy+paste contents
# - make multi-line help better visible
# - and group things together
: indent
indent()
{
o awk -F':' '
/^[[:space:]]/	{ gsub(/^[[:space:]]*/,""); more[++mo]=$0; pos[nr]=mo; next; }
NF==1		{ print "# Usage: " $0; next; }
		{ txt[++nr]=$1; if (length($1)>min) min=length($1); sub(/^[^:]*:/, "", $0); rest[nr]=$0; next; }
END		{ for (i=0; ++i<=nr; ) { printf("#%03d %-*s%s\n", i, min+1, txt[i] ":", rest[i]); while (j<pos[i]) printf("#%3d %*s  %s\n", i, min, "", more[++j]); } }'
}



helper()
{
good-command "$1"
sed -e "1,/^##$1[^a-z]/d" -e '/^[^#]/,$d' -e 's/^#//' -e 's/^ /git hub /' "$0" | indent
}



##options: alias for: help options
Coptions() { Chelp options "$@"; }

##[--options] command [args..]
##help [command]: show help
# help: list all known commands
# help options: show help for possible options
# help "command": give help for the given command
: Chelp
Chelp()
{
args '' 0 1 "$@"
set -- "${ARGS[@]}"
case "$#:$1" in
(0:)		sed -n "s/^##\([^#]\)/git hub \1/p" "$0" | indent;;
(1:options)	sed -n 's/^[^-#]*\(--[a-z=]*\).*#''-/option \1/p' "$0" | indent;;
(1:*)		helper "$1";;
*)		OOPS internal error;;
esac
quick-checks
return 42
}



##st: alias for: status
Cst() { Cstatus "$@"; }

##status: print current settings
# status: This always looks into all possible variants
# --insecure status: Also display protected values
# --insecure --insecure status: Also decode protected values
Cstatus()
{
args insecure 0 0 "$@"
set -- "${ARGS[@]}"
local conf
for conf in ${!hub_@}
do
	printf '%24q=%q\n' "$conf" "${!conf}"
done

for conf in "${HUB_SETTINGS[@]}"
do
	x config-get-all v "$conf"
	printf '%d: %21q %s\n' "$?" "$conf" "$v"
done
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
args '' 0 1 "$@"
set -- "${ARGS[@]}"

[ 1 = $# ] && o config-set-unchanged user "$1"
for a in "${HUB_SETTINGS[@]}"
do
	x config-get-any b "$a" &&
	o config-set-unchanged "$a" "$b"
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
	config-was "${k#"$HUB_SECTION."}" "$v"
done 6< <(config-get-regexp--z "^$HUB_SECTION.")
O git config $hub_global --remove-section "$HUB_SECTION"
}



##token: alias for: login token
Ctoken() { Clogin token "$@"; }

QUERY_token=(
	'Open https://github.com/settings/tokens'
	'Click "Generate new token" (right, nearly at top)'
	'Give it a good name (like "git-hub $(hostname)")'
	'Do not enable any of the scopes!'
	'(You can go back to GitHub and change scopes later.)'
	'Click "Generate token" (at the bottom)'
	'The token will only be shown on the page that follows.'
	'Click the "Copy Token"-Icon, paste it here (Ctrl+Shift+V).'
	'Or do: "git hub --global login token TOKEN"'
)

##login [opt] type [args..]: authenticate against GitHub
# login [opt] type [args..]
# login --force ...: rewrite token even if unchanged
# login token TOKEN: set personal access token
#	If TOKEN is missing, it is read from terminal.
: Clogin
Clogin()
{
local token orig opt_force

args force 1 2 "$@"
set -- "${ARGS[@]}"

case "$#:$1" in
1:token)	[ .--global = ".$hub_global" ] || WARN perhaps option --global is missing
		{ config-get     token && WARN This token will refresh/replace the old one; } ||
		{ config-get-any token && WARN This new token will be used instead of the global token; }
		o query token
		;;
2:token)	token="$2";;
*)		OOPS currently the only known login method is: token;;
esac

# Never output token in unscrambled form!
[ -n "$token" ] || OOPS invalid token: cannot be empty or multiline
isalnum "$token" || OOPS invalid token: does not contain expected characters

if	config-get orig token
then
	o unscramble orig "$orig"
	[ ".$orig" = ".$token" ] && VERBOSE git hub login token: unchanged && [ -z "$opt_force" ] && return
fi
o scramble token "$token"
o config-set-unchanged token "$token"
}



##logout: deauthenticate
# [--global] logout [--all] token: remove (all) token(s)
# [--global] logout token abc: only remove given token
Clogout()
{
local opt_all

args all 1 1 "$@"
set -- "${ARGS[@]}"

case "$#:$1" in
1:token)	config-unset token "$opt_all";;
2:token)	[ 0 = $opt_all ] || OOPS option --all cannot be used here
		o config-get token
		[ ".$token" = ".$2" ] || OOPS token mismatch
		config-unset token
		;;
*)		OOPS currently the only known login method is: token;;
esac

config-get-any token && WARN a token is still around: "$token"
}



# ##list: fetch various lists from GitHub
# # list [options] listname [args]
# # (notyet) list --grace: Try to keep 40 queries left
# # (notyet) list --force: Go below 20 queries left
# # (notyet) list --update: Refresh cache by querying GitHub
# # (notyet) list --cached: Show only already cached data
# # list forks [user/repo]: show all known forks
# # (notyet) list repos [user]: show all (public) repos of a user
# # (notyet) list euser [user]: list events of user
# # (notyet) list erepo [user/repo]: list events of repo
# # (notyet) list events: list all public events
# # (notyet) list issues [user/repo]: list issues of a repo
# : Clist
# Clist()
# {
# local OWNER REPO
# 
# args '' 1 3 "$@"
# set -- "${ARGS[@]}"
# 
# case "$1" in
# forks)	;;
# *)	OOPS unknown list.  Available lists: git hub help list;;
# esac
# 
# NOTYET
# 
# getrepo OWNER REPO "${@:2}"
# 
# url="/repos/$OWNER/$REPO/forks"
# }


###
### MAIN
###

quick-checks()
{
local -n me="${1:-ME}"

me="${0##*git-}"

config-get-any user  || WARN please set an user with: git "$me" --global init '$YOUR_GITHUB_USERNAME'
config-get-any token || WARN please set a token with: git "$me" --global login token
}

missing-command()
{
quick-checks ME

STDERR try: git "$ME" help
}

# Wrap all the main functionality
: main
main()
{
check-git
while	:
do
	case "$#:$1" in
	(*:--debug)	hub_debug=1;;			#-: use global .gitconfig instead of local .git/config
	(*:--global)	hub_global=--global;;		#-: use global .gitconfig instead of local .git/config
	(*:--quiet)	hub_noquiet=0;;			#-: be more quiet
	(*:--user=*)	hub_user="${1#--user=}":;;	#-username: override default GitHub username
	(*:--verbose)	hub_verbose=1;;			#-: verbose output
	(*:--secure)	hub_insecure=3;;		#-: disallow --insecure and --insecure --insecure
	(*:--insecure)	let hub_insecure++;;		#-: display insecure values in output (double to decode)
	(0:)		missing-command; return 23;;
	(*)		good-command "$1"; "C$1" "${@:2}"; return;;
	esac
	shift
	[ 3 -ge "$hub_insecure" ] || hub_insecure=3
done
}



# Run it if not sourced.
# This sourced-check only works for BASH
unset BASH_SOURCE 2>/dev/null
[ ".$0" != ".$BASH_SOURCE" ] || main "$@"

