.PHONY: default synth control control_background attach clean clean_runs

TMUX_SESSION := control_$(shell date +%s%N)
TMUX_INFO := tmux.info

default: control_background
synth:
	vivado -mode batch -source synth_template.tcl > ../runs/run_1/synth.log 2>&1
control:
	python3 control.py
control_background:
	@echo "session=$(TMUX_SESSION)" > $(TMUX_INFO)
	tmux new-session -d -s $(TMUX_SESSION) "python3 -u control.py 2>&1 | tee run.log"

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


clean:
	rm -rf .Xil/ *.vivado/ logs/ *.log *.jou *.str *.info  .crashReporter/
clean_runs:
	rm -rf ../run_*/
