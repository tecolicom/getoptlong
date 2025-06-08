BATS=bats

test:
	$(BATS) 00_getoptlong.bats
	@for script in ../ex/repeat.sh ../ex/prefix.sh; do \
	    echo $(BATS) $$script; \
	    SCRIPT_UNDER_TEST=$$script bats 10_repeat.bats ; \
	done
