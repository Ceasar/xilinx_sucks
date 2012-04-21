xilinx_sucks
============

A collection of tools designed to make Xilinx suck less.

Info
====

xilinx_sucks is a sort of arbritrary collection of utility files and scripts designed to make certain parts of using Xilinx suck less.

Namely, you run the following scripts:

* python scripts.py debug <myfile.v>
    * Runs a parser on the text file and generates a series of $display commands to display the value of every wire in each cycle.
* python scripts.py trace <trace.txt>
    * Runs a parser on a trace file (generated from the output of debug) to print the time, pc, and instruction at each cycle.
* ruby decode.rb <trace.txt>
    * Runs a parser on a trace file (generated from the output of debug) and translates machine codes to assembly and pc values to hex.

Additionally, you may find useful the following files:

* opcodes.txt
    * Contains a list of opcodes of the various lc4 instructions.
