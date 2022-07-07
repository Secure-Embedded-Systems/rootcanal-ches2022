# RootCanal

This repository contains the files and results of the experiments in RootCanal paper at CHES 2022.

## Organization

Each example folder has the following structure:
- rtl/ folder contains the hardware design files
- synth/ folder contains the post-synthesis gate-level netlist and the gate to RTL mapping files
- sim/ folder contains the software source code, assembly file, binary file, testbench, test vectors, and the log of the program counter for each pipeline stage
- power/ folder has the mean power trace for the experiment
- aca/ folder contains the output result of the non-specific ACA for the experiment
- nga/ folder contains the scripts and outputs of netlist graph analysis
