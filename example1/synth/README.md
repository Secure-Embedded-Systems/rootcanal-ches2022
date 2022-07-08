## Gate-level synthesis
We used Cadence Genus for synthesis. skivav_sky130_50.v is the resulting gate-level netlist. 

By setting the option `set_db hdl_track_filename_row_col true` during synthesis, the gates in the gate-level netlist are tracked to their RTL design file. skivav_sky130_50.g is the resulting mapping file.  
