# love make, make love
#
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

BINS=json2sh

.PHONY:	love all
love all:	$(BINS)
	@echo
	@echo "run: make install"
	@echo

CFLAGS=-Wall -O3

.PHONY:	install
install:
	mkdir -p '$(HOME)/bin'
	[ ".`readlink -m '$(HOME)/bin/git-hub'`" = ".`readlink -e git-hub.sh`" ] || ln -s -v --relative --backup=t git-hub.sh '$(HOME)/bin/git-hub'
	@echo
	@echo 'Plese make sure $(HOME)/bin is in your $$PATH such that git sees it'
	@echo 'To fully setup run: git hub init --global your-github-username'
	@echo

.PHONY:	clean

clean:
	rm -f $(BINS)

