BATS=bats
TESTS_REGULAR = 00_getoptlong.bats 30_silent.bats

test:
	$(BATS) $(TESTS_REGULAR)
	@echo "Running parameterized tests for 10_repeat.bats"
	@for script in ../ex/repeat.sh ../ex/prefix.sh; do \
	    echo "$(BATS) SCRIPT_UNDER_TEST=$$script 10_repeat.bats"; \
	    SCRIPT_UNDER_TEST=$$script $(BATS) 10_repeat.bats ; \
	done
