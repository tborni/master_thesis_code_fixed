################################################################################
# Behavioral simulation of the HLS SoftMax core (N=64, SIMD=1).
#
#   make            # launch the sim in a detached tmux session (Vivado batch)
#   make attach     # attach to the running session to watch output
#   make kill       # kill the session
#   make sim_fg     # run the sim in the foreground (no tmux)
#   make result     # print the RMSRE line from the last run's log
#   make clean      # remove the Vivado project and generated sim artifacts
#
# Layout: HDL + IP live in ../src, this scripts/ dir holds the Makefile +
# run_sim.tcl. The Vivado project, run_sim.log and other sim artifacts are
# created here in scripts/.
#
# A tmux session keeps Vivado running after logout; the session name is recorded
# in tmux.info and the batch output is echoed to run_sim.log via tee.
################################################################################
.PHONY: default sim sim_fg attach kill result clean

TMUX_SESSION := simsm_$(shell date +%s%N)
TMUX_INFO    := tmux.info
LOG          := run_sim.log
TCL          := run_sim.tcl

default: sim

# Detached run: Vivado batch inside tmux, output tee'd to the log.
sim:
	@echo "session=$(TMUX_SESSION)" > $(TMUX_INFO)
	tmux new-session -d -s $(TMUX_SESSION) "vivado -mode batch -source $(TCL) 2>&1 | tee $(LOG)"
	@echo "Started sim in tmux session $(TMUX_SESSION). Attach with: make attach"

# Foreground run (handy for a quick interactive invocation).
sim_fg:
	vivado -mode batch -source $(TCL) 2>&1 | tee $(LOG)

attach:
	@if [ ! -f $(TMUX_INFO) ]; then \
		echo "No tmux.info found — no run started yet"; exit 1; \
	fi
	@session=$$(sed -n 's/^session=//p' $(TMUX_INFO)); \
	if [ -z "$$session" ]; then \
		echo "Invalid tmux.info"; exit 1; \
	fi; \
	tmux attach -t $$session

kill:
	@if [ ! -f $(TMUX_INFO) ]; then \
		echo "No tmux.info found — nothing to kill"; exit 0; \
	fi; \
	session=$$(sed -n 's/^session=//p' $(TMUX_INFO)); \
	if [ -z "$$session" ]; then \
		echo "Invalid tmux.info"; exit 1; \
	fi; \
	if tmux has-session -t $$session 2>/dev/null; then \
		tmux kill-session -t $$session; \
		echo "Killed session $$session"; \
	else \
		echo "Session $$session not running"; \
	fi

# Show the accuracy result once the run has produced it.
result:
	@if [ ! -f $(LOG) ]; then \
		echo "No $(LOG) yet — run 'make' first"; exit 1; \
	fi; \
	grep -E "RMSRE" $(LOG) || echo "No RMSRE line found in $(LOG) (run may be incomplete — check the log)."

clean:
	rm -rf *.vivado/ .Xil/ xsim.dir/ *.jou *.log *.pb *.wdb *.str webtalk* \
	       vivado_*.backup.* $(TMUX_INFO) *.info
