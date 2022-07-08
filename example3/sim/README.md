## Simulation
We used Cadence Xcelium to generate vcd files. 

test_skivav.v is the testbench used for generating the power traces. 

The C code used for the experiment is in software/ folder. 

The PC log for each pipeline stage is at pc_log/ folder.

*.csv files contain the test vectors given to the simulation.

The testbench does the following:
1. loads the binary file (.vmh in software/) to the program memory
2. resets and provides the clock to the design
3. copies the key and plaintext to the predefined memory locations
4. checks the correctness of the ciphertext
5. for RTL simulation (non-gate-level), PC is logged for each pipeline stage
