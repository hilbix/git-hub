# love make, make love
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

.PHONY:	love all
love all:	sub
	@echo
	@echo "run: make install"
	@echo

.PHONY:	sub
sub:
	[ -e json2sh/.git ] || git submodule update --init
	make -C json2sh all

.PHONY:	install
install:
	mkdir -p '$(HOME)/bin'
	[ ".`readlink -m '$(HOME)/bin/git-hub'`" = ".`readlink -e git-hub.sh`" ] || ln -s -v --relative --backup=t git-hub.sh '$(HOME)/bin/git-hub'
	@echo
	@a="`which git-hub`" && cmp -s git-hub.sh "$$a" || echo 'Plese make sure $(HOME)/bin is in your $$PATH such that git sees it'
	@echo 'To fully setup run: git hub --global init your-github-username'
	@echo

