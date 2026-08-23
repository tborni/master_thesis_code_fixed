.PHONY: clean generate

COMBINED_FILES := $(wildcard *_combined.csv)

all:
	python3 generate_combined.py
	python3 diagram.py
	python3 pareto.py
	python3 full_pareto.py

clean:
	rm -rf *.png
	find . -type f -name "*_combined.csv" ! -name "IP-Core_combined.csv" ! -name "Schraudolph_combined.csv" -delete

pareto.png: pareto.py $(COMBINED_FILES)
	python3 pareto.py

full_pareto.png: full_pareto.py $(COMBINED_FILES)
	python3 full_pareto.py

diagram.png: diagram.py $(COMBINED_FILES)
	python3 diagram.py

generate: generate_combined.py
	python3 generate_combined.py

