# love make, make love
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

.PHONY: love all
love all:
	@echo
	@echo "run: make install"
	@echo

.PHONY: install
install:
	mkdir -p '$(HOME)/bin'
	[ ".`readlink -m '$(HOME)/bin/gh'`" = ".`readlink -e gh.sh`" ] || ln -s -v --relative --backup=t gh.sh '$(HOME)/bin/gh'
	@echo
	@echo 'Plese make sure $(HOME)/bin is in your $$PATH'
	@echo 'To fully setup run: gh init --global'
	@echo

