CC = gcc
CFLAGS = -O2
LDFLAGS = -lm

BINS = schraudolph_exp_large_sweep schraudolph_exp_one optimal_magic_coarse_sweep_schraudolph determine_optimal_magic_schraudolph

SWEEP_CSV = optimal_magic_coarse_sweep_schraudolph_results.csv
SWEEP_PNG = optimal_magic_coarse_sweep_schraudolph_results.png

PYTHON = ../../.venv/bin/python3

.PHONY: clean all plot

all: $(BINS)

$(SWEEP_CSV): optimal_magic_coarse_sweep_schraudolph
	./optimal_magic_coarse_sweep_schraudolph

$(SWEEP_PNG): $(SWEEP_CSV) visualize_value_pairs.py
	$(PYTHON) visualize_value_pairs.py

plot: $(SWEEP_PNG)

clean:
	rm -rf $(BINS) $(SWEEP_CSV) $(SWEEP_PNG)

%: %.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)
