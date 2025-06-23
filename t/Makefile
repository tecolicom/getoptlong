.DELETE_ON_ERROR:
.ONESHELL:
SHELL := bash
.SHELLFLAGS := -euo pipefail -O extglob -c

BATS=bats

test:
	$(BATS) !(10_repeat).bats
	@for script in ../ex/repeat.sh ../ex/prefix.sh; do
	    echo $(BATS) $$script
	    SCRIPT_UNDER_TEST=$$script bats 10_repeat.bats
	done
