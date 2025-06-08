BATS=bats

test:
	$(BATS) 00_getoptlong.bats
	@for script in ../ex/{repeat,prefix}.sh; do \
	    echo $(BATS) $$script; \
	    SCRIPT_UNDER_TEST=$$script bats 10_repeat.bats ; \
	done
