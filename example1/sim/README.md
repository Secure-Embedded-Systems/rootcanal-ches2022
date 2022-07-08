## Simulation
We used Cadence Xcelium to generate vcd files. 

test_skivav.v is the testbench used for generating the power traces. 

The C code used for the experiment is in software/ folder. 

tvla_1k_key0_keyf.csv contains the test vectors given to the simulation. Each line has the group index (for TVLA), the key, the input, and the output of the algorithm. 

The testbench does the following:
1. loads the binary file (.vmh in software/) to the program memory
2. resets and provides the clock to the design
3. copies the key and plaintext to the predefined memory locations
4. checks the correctness of the ciphertext 
