# Build Instructions

* Create a new Vivado Project.

* Select the Basys3 board.

* Import all source files from the folders Shell, autoclave and rc4

* For running testbenches, import simulation files from Shell, autoclave and RC4.

* Import constraints file from Shell

* If you chose to copy the source files into your project, copy the file menurom.txt under Shell/ into the top level folder of your project.


There is also a pre-generated bitstream file, that can be written to FPGA directy


# Running TestBenches

* Start a testbench in the normal way

* Set a very high number of milliseconds, and press the 'Run-For' button. 

* The testbenches for Autoclave and RC4 will finish quickly, while the testbench for the complete system (Shell) will run for approximately 5 minutes.

* The console window will print 'Test: OK' if the test finished without any errors.

