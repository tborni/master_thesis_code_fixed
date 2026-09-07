.PHONY: default synth synth-only run run-synth-only attach kill clean

TMUX_SESSION := synth_$(shell date +%s%N)
TMUX_INFO    := tmux.info
TCL          := build_synth.tcl
LOG          := synth.log

# Launch in a detached tmux session (survives SSH disconnects)
default: run
run:
	@echo "session=$(TMUX_SESSION)" > $(TMUX_INFO)
	tmux new-session -d -s $(TMUX_SESSION) "vivado -mode batch -source $(TCL) 2>&1 | tee $(LOG)"
	@echo "Started Vivado in tmux session $(TMUX_SESSION)"
	@echo "Attach with: make attach"

# Same as run, but stop after synthesis (skips the long place & route)
run-synth-only:
	@echo "session=$(TMUX_SESSION)" > $(TMUX_INFO)
	tmux new-session -d -s $(TMUX_SESSION) "vivado -mode batch -source $(TCL) -tclargs synth_only 2>&1 | tee $(LOG)"
	@echo "Started Vivado (synthesis only) in tmux session $(TMUX_SESSION)"
	@echo "Attach with: make attach"

# Run synchronously in the foreground (no tmux)
synth:
	vivado -mode batch -source $(TCL) 2>&1 | tee $(LOG)

# Foreground, synthesis only (skips place & route)
synth-only:
	vivado -mode batch -source $(TCL) -tclargs synth_only 2>&1 | tee $(LOG)

attach:
	@if [ ! -f $(TMUX_INFO) ]; then \
		echo "No $(TMUX_INFO) found — no run started yet"; exit 1; \
	fi; \
	session=$$(sed -n 's/^session=//p' $(TMUX_INFO)); \
	if [ -z "$$session" ]; then echo "Invalid $(TMUX_INFO)"; exit 1; fi; \
	tmux attach -t $$session

kill:
	@if [ ! -f $(TMUX_INFO) ]; then \
		echo "No $(TMUX_INFO) found — nothing to kill"; exit 0; \
	fi; \
	session=$$(sed -n 's/^session=//p' $(TMUX_INFO)); \
	if [ -z "$$session" ]; then echo "Invalid $(TMUX_INFO)"; exit 1; fi; \
	if tmux has-session -t $$session 2>/dev/null; then \
		tmux kill-session -t $$session; echo "Killed session $$session"; \
	else \
		echo "Session $$session not running"; \
	fi

clean:
	rm -rf .Xil/ *.jou *.log *.str vivado*.backup.jou vivado*.backup.log $(TMUX_INFO) .crashReporter/
