# synthesis_sweep_wrapper

This repository contains a synthesis sweep wrapper for the convolution unit that automates generating multiple synthesis cases with different parameter configurations. The wrapper leverages configuration files, Python scripting, and TCL templates to create the necessary synthesis scripts for each parameter set.

## Structure
```
.
├── synthesis_sweep/
│   ├── config/                 # Parameter configuration files for sweep
│   └── scripts/                # Scripts for automation
│       ├── Makefile            # Starting point for running the sweep
│       ├── control.py          # Controls TCL file generation and synthesis runs
│       └── synth_template.tcl  # Template TCL used to generate per-configuration TCL files
│   └── src/                    # All SystemVerilog & Verilog files for the top-level convolution design
```

## How it works
Configurations
All sweep parameters are defined in files inside synthesis_sweep/config/.
Each configuration file contains parameter values that should be swept as well as meta data like board, top_file and clk_name.

Script Automation
The Makefile in synthesis_sweep/script/ is the entry point. It invokes control.py, which:
- Reads the main_config configuration file
- Uses synth_template.tcl to generate a TCL file for each parameter combination
- Executes the synthesis tool on each generated TCL file

SystemVerilog & Verilog Requirements
All SystemVerilog & Verilog files required for synthesis must reside in the src directory (./src)

# Usage
1. Put the configuration in ./config/main_config.txt
2. Navigate to ./script/
3. Run the Makefile: make

# Details
The control.py script will execute the following steps:
1. Verify that vivado is sourced
2. The config file will be parsed and all the configurations will be determined
3. Create all the folders and create the tcl files based on all the parameter configurations, use a sequential number and a timestamp to create a new folder every time
4. Create csv files
5. Run all syntheses and implementations, create all resource and timing reports
6. Extract resource and timing information from reports
7. Store important information in the csv files

# Misc
- make starts a tmux session so that the sweep continues running after a logout
- information about the config file structure can be found in ./config/reference_config_comments.txt