import re
from itertools import product
import subprocess
import datetime
import os
import time
import math
from collections import OrderedDict

def params_satisfy_condition(params,current_conditions):
	SAFE_BUILTINS = {"int": int,"float": float,"str": str,"min": min,"max": max,"sum": sum,}
	for cond in current_conditions:
		result = eval(cond.strip(), {"__builtins__": SAFE_BUILTINS, "math": math}, params)
		if not isinstance(result, bool):
			raise TypeError(f"Condition '{cond}' evaluated to {type(result).__name__}, "f"but a boolean expression is required.")
		if not result:
			return 0
	return 1

def compute_derived_outputs(params, derived_outputs):
	SAFE_BUILTINS = {"int": int,"float": float,"str": str,"min": min,"max": max,"sum": sum,}
	result = dict()
	for key, value in derived_outputs.items():
		result[key] = eval(value.strip(), {"__builtins__": SAFE_BUILTINS, "math": math}, params)
	return result

def store_sweep_values(results, current_default_values, current_name, current_active, current_mode, 
					   current_cartesian_values, current_explicit_values, current_conditions, derived_outputs):
	if(current_name is None):
		#first line of sweeps section
		return
	
	# store actual new sweep
	all_sweeps = []
	all_sweeps_derived = []
	if current_mode == "cartesian":
		keys = list(current_cartesian_values.keys())
		values = current_cartesian_values.values()
		for combination in product(*values):
			combo_dict = dict(zip(keys, combination))
			params = dict(current_default_values)
			for k, v in combo_dict.items():
				params[k] = v
			if params_satisfy_condition(params,current_conditions):
				all_sweeps.append(params)
				all_sweeps_derived.append(compute_derived_outputs(params, derived_outputs))
	elif current_mode == "explicit":
		for expl_value in current_explicit_values:
			params = dict(current_default_values)
			for key, value in expl_value.items():
				params[key] = value
			if params_satisfy_condition(params,current_conditions):
				all_sweeps.append(params)
				all_sweeps_derived.append(compute_derived_outputs(params, derived_outputs))

	if(current_active):
		results[0].append(current_name)
		results[1].append(all_sweeps)
		results[2].append(all_sweeps_derived)

def parse_config(filename):
	# Read in config file and ignore empty lines as well as comment
	lines = []
	with open(filename, "r") as f:
		for line in f:
			l = line.split("//")[0].strip()
			if l:
				lines.append(l)

	# 0th entry: list with all sweep names
	# 1st entry: list of all parameter configurations (represented as dicts) for each sweep
	# 2rd entry: derived_outputs
	# 3nd entry: list of all parameter keys
	# 4th entry: list of derived outputs keys
	# 5th entry: tcl paramters
	results = [[], [], [], [], [], []]

	parameter_pattern = re.compile(r"^#\s([\w_]+)\s=\s(.+)$")
	default_values = OrderedDict()
	expected_keys = set()
	derived_outputs = OrderedDict()
	tcl_parameters = {}

	current_default_values = {}	# Dict that maps each parameter to a specific value
	current_name = None	# String
	current_active = True # Boolean
	current_mode = None	# String, either "cartesian" or "explicit"
	current_cartesian_values = {}	# Dict that maps parameter name to list of values
	current_explicit_values = []	# List of Dicts that map parameter name to specific value
	current_conditions = []	# List of all conditions -> list of strings representing the condition

	current_section = None
	current_subsection = None
	for line in lines:
		if line.startswith("tcl_parameters:"):
			current_section = "tcl_parameters"
			continue
		elif line.startswith("defaults:"):
			current_section = "defaults"
			continue
		elif line.startswith("derived_outputs"):
			current_section = "derived_outputs"
			continue
		elif line.startswith("sweeps:"):
			current_section = "sweeps"
			expected_keys = set(default_values.keys())
			continue

		if current_section == "tcl_parameters":
			match = parameter_pattern.match(line)
			if(match):
				key, value = match.groups()
				tcl_parameters[key] = value
			else:
				raise ValueError("Error: Wrong Format in defaults section.")
		elif current_section == "defaults":
			match = parameter_pattern.match(line)
			if(match):
				key, value = match.groups()
				default_values[key] = value
			else:
				raise ValueError("Error: Wrong Format in defaults section.")
		elif current_section == "derived_outputs":
			match = parameter_pattern.match(line)
			if(match):
				key, value = match.groups()
				derived_outputs[key.strip()] = value
			else:
				raise ValueError("Error: Wrong Format in derived_outputs section.")
		elif current_section == "sweeps":
			if line.startswith("***"):
				# new sweep line
				store_sweep_values(results,current_default_values,current_name,current_active,current_mode,current_cartesian_values,
					   current_explicit_values,current_conditions, derived_outputs)

				current_default_values = dict(default_values)
				current_name = None
				current_mode = None
				current_cartesian_values = {}
				current_explicit_values = []
				current_conditions = []
			elif line.startswith("~"):
				# metadata line
				key, value = line[2:].split(":", 1)
				if key == "name":
					current_name = value.strip()
				if key == "active":
					current_active = True if (value.strip() == "1") else False
				if key == "fixed":
					current_subsection = "fixed"
				if key == "mode":
					current_mode = value.strip()
					current_subsection = current_mode
					if (current_mode != "cartesian" and current_mode != "explicit"):
						raise ValueError("Error: Only cartesian and explicit mode allowed.")
				if key == "conditions":
					current_subsection = "conditions"
			elif line.startswith("#"):
				# parameter line
				if current_subsection == "fixed":
					match = parameter_pattern.match(line)
					if(match):
						key, value = match.groups()
						current_default_values[key] = value
					else:
						raise ValueError("Error: Wrong Format in fixed section.")
				elif current_subsection == "explicit":
					expl_str = line.strip("()# ")
					new_sweep = dict(current_default_values)
					for assign in expl_str.split(","):
						key, value = assign.split("=")
						new_sweep[key.strip()] = value.strip()
					current_explicit_values.append(new_sweep)
				elif current_subsection == "cartesian":
					cart_str = line.strip("# ")
					key, value = cart_str.split("=")
					sweep_list = []
					for w in value.strip("{} ").split(","):
						sweep_list.append(w.strip())
					current_cartesian_values[key.strip()] = sweep_list
				elif current_subsection == "conditions":
					current_conditions.append(line.strip("# "))
			else:
				raise ValueError("Error: Line starts with not allowed character in the sweeps section.")
		else:
			raise ValueError("Error: Line starts with not allowed character.")

	# Check correct keys
	for i, sweep in enumerate(results[1]):
		for j, params in enumerate(sweep):
			param_keys = set(params.keys())
			missing = expected_keys - param_keys
			extra = param_keys - expected_keys

			if missing or extra:
				raise ValueError(
					f"[Config Error] Sweep {i}, run {j} has invalid parameter keys\n"
					f"Missing keys: {missing}\n"
					f"Extra keys: {extra}\n"
					f"Expected: {expected_keys}\n"
					f"Got: {list(params.keys())}"
				)
	# Check correct tcl parameters
	expected = {"top", "part", "clk_name"}
	if set(tcl_parameters) != expected:
		raise ValueError(
			f"tcl_parameters must contain exactly the keys {expected}, "
			f"but got {set(tcl_parameters)}"
		)

	results[3] = list(default_values.keys())
	results[3].remove("clock_period")
	results[4] = list(derived_outputs.keys())
	results[5] = [tcl_parameters]

	return results

def ex_command(command):
	subprocess.run(command, shell=True, stdout=None, stderr=None, universal_newlines=True)


def verify_vivado_sourced():
	try:
		subprocess.run(['which', 'vivado'], check=True)
	except subprocess.CalledProcessError:
		raise RuntimeError("Vivado not found.")

def create_folders_and_tcl(sweeps_path, config):
	os.makedirs(sweeps_path)
	for i in range(len(config[0])):
		name_path = sweeps_path + "/" + str(i) + "_" + config[0][i]
		os.makedirs(name_path)
		for j in range(len(config[1][i])):
			run_path = name_path + "/run_" + str(j)
			os.makedirs(run_path)
			with open("synth_template.tcl", "r", encoding='utf-8') as file:
				tcl_content = file.read()
			tcl_parameters = config[5][0]
			for k,v in tcl_parameters.items():
				tcl_content = tcl_content.replace("{{ " + k + " }}", str(v))
			generics = ""
			params = config[1][i][j]
			first = True
			for k, v in params.items():
				if k == "clock_period":
					continue
				if not first:
					generics += "\n\t"
				else:
					first = False
				generics += (k + "=" + v)
			tcl_content = tcl_content.replace("{{ params }}", generics)
			tcl_content = tcl_content.replace("{{ clock_period }}", params["clock_period"])
			with open(run_path + "/synth.tcl", "w") as file:
				file.write(tcl_content)

def set_csv_headers(sweeps_path, parameter_keys, derived_outputs_keys, result_keys):
	with open(sweeps_path + "/summary.csv", "w") as file:
		file.write(",".join(parameter_keys + derived_outputs_keys + result_keys) + "\n")
	for i in range(len(config[0])):
		name_path = sweeps_path + "/" + str(i) + "_" + config[0][i]
		with open(name_path + "/summary.csv", "w") as file:
			file.write(",".join(parameter_keys + derived_outputs_keys + result_keys) + "\n")


def run_synth_and_extraction(sweeps_path, parameter_keys, derived_outputs_keys, result_keys):
	for i in range(len(config[0])):
		for j in range(len(config[1][i])):
			name_path = sweeps_path + "/" + str(i) + "_" + config[0][i]
			run_path = name_path + "/run_" + str(j)
			params = config[1][i][j]
			derived_outputs = config[2][i][j]

			values = [params[k] for k in parameter_keys] + [str(derived_outputs[k]) for k in derived_outputs_keys]
			values.append(params["clock_period"])

			if(1):
				ex_command("vivado -mode batch -source " + run_path + "/synth.tcl > " + run_path + "/synth.log 2>&1")
			else:
				with open(name_path + "/summary.csv", "a") as file:
					file.write(",".join(values) + "\n")
				with open(sweeps_path + "/summary.csv", "a") as file:
					file.write(",".join(values) + "\n")

			

			try:
				# extract information from timing_report
				with open(run_path + "/timing_report.rpt", "r", encoding='utf-8') as file:
					timing_content = file.read()
				pattern_WNS = re.compile(r"Setup :\s+\d+  Failing Endpoints,  Worst Slack\s+(-?\d+\.\d+)ns")
				match = pattern_WNS.search(timing_content)
				if(match):
					wns = match.group(1)
					values.append(wns)
					critical_path_timing = float(params["clock_period"]) - float(wns)	# unit: ns
					values.append(str(round(critical_path_timing,3)))
					max_frequency = 1000 / critical_path_timing	# unit: MHz
					values.append(str(round(max_frequency)))
				else:
					print("Warning: No WNS found in " + run_path + "/timing_report.rpt")
					for i in range(3):
						values.append("-1")

				# extract information from util_report
				with open(run_path + "/util_report.rpt", "r", encoding='utf-8') as file:
					util_content = file.read()
				pattern_REG = re.compile(r"CLB Registers\s*\|\s*(\d+(?:\.\d+)?)\s+")
				pattern_LUT = re.compile(r"CLB LUTs\s*\|\s*(\d+(?:\.\d+)?)\s+")
				pattern_DSP_1 = re.compile(r"DSPs\s*\|\s*(\d+(?:\.\d+)?)\s+")
				pattern_DSP_2 = re.compile(r"DSP Slices\s*\|\s*(\d+(?:\.\d+)?)\s+")
				pattern_BRAM = re.compile(r"Block RAM Tile\s*\|\s*(\d+(?:\.\d+)?)\s+")
				pattern_URAM = re.compile(r"URAM\s*\|\s*(\d+(?:\.\d+)?)\s+")
				# REG
				match = pattern_REG.search(util_content)
				if(match):
					reg = match.group(1)
					values.append(reg)
				else:
					values.append(-1)
					print("Warning: No REG count found in " + run_path + "/util_report.rpt")
				# LUT
				match = pattern_LUT.search(util_content)
				if(match):
					lut = match.group(1)
					values.append(lut)
				else:
					values.append(-1)
					print("Warning: No LUT count found in " + run_path + "/util_report.rpt")
				# DSP
				match_1 = pattern_DSP_1.search(util_content)
				match_2 = pattern_DSP_2.search(util_content)
				if(match_1):
					dsp = match_1.group(1)
					values.append(dsp)
				elif(match_2):
					dsp = match_2.group(1)
					values.append(dsp)
				else:
					values.append(-1)
					print("Warning: No DSP count found in " + run_path + "/util_report.rpt")
				# BRAM
				match = pattern_BRAM.search(util_content)
				if(match):
					bram = match.group(1)
					values.append(bram)
				else:
					values.append(-1)
					print("Warning: No BRAM count found in " + run_path + "/util_report.rpt")
				# URAM
				match = pattern_URAM.search(util_content)
				if(match):
					uram = match.group(1)
					values.append(uram)
				else:
					values.append(-1)
					print("Warning: No URAM count found in " + run_path + "/util_report.rpt")

				with open(name_path + "/summary.csv", "a") as file:
					file.write(",".join(values) + "\n")
				with open(sweeps_path + "/summary.csv", "a") as file:
					file.write(",".join(values) + "\n")
			except Exception as e:
				print(f"Problem with timing or util report for {parameter_keys}: {e}")

def print_message(message):
	print(f"[STEP] {message}")

if __name__ == "__main__":
	verify_vivado_sourced()
	print_message("Vivado sourced validation passed")

	config = parse_config("../config/main_config.txt")

	num_runs = sum(1 for f in os.listdir("..") if f.startswith("run_") and os.path.isdir("../" + f))
	timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
	run_path = "../run_" + str(num_runs) + "_" + timestamp
	create_folders_and_tcl(run_path, config)

	time.sleep(1)	# wait 1s to make sure that every operation has finished

	parameter_keys = config[3]
	derived_outputs_keys = config[4]
	result_keys = ["clock_period","WNS","Critical path timing","Max frequency","REG","LUT","DSP","BRAM","URAM"]

	set_csv_headers(run_path, parameter_keys, derived_outputs_keys, result_keys)
	print_message("Folder and file creation successfully - Start synthesis...")

	run_synth_and_extraction(run_path, parameter_keys, derived_outputs_keys, result_keys)
	print_message("All synthesis completed")
