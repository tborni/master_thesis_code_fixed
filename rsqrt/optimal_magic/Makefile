CC = gcc
CFLAGS = -O2
LDFLAGS = -lm

.PHONY: clean

all: optimal_magic_coarse_sweep determine_optimal_magic


clean:
	rm -rf optimal_magic_coarse_sweep determine_optimal_magic
	rm -rf *.csv

optimal_magic_coarse_sweep: optimal_magic_coarse_sweep.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

determine_optimal_magic: determine_optimal_magic.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

