# Virtual_Channel_Router
ECE 6115: Project of configurable virtual channel router

Team:
Member 1:
Name: Varun Saxena
Member 2:
Name: Venkata Hanuma Sandilya Balemarthy

Source code:
  -> Github repository: https://github.com/varunsax12/Virtual_Channel_Router
  -> Tar Ball: virtual_channel_router_files.tar.gz

Run Environment:
  -> Server: ece-linlabsrv01.ece.gatech.edu

Tool Setup: (specific to server)
Run the following commands:
  -> Synopsys VCS
      -> export VCS_HOME=/tools/software/synopsys/vcs/R-2020.12-SP2/
      -> export PATH=/tools/software/synopsys/vcs/R-2020.12-SP2/:/tools/software/synopsys/vcs/R-2020.12-SP2//bin:$PATH

Directory Structure:
Top folder: Virtual_Channel_Router
  -> ./rtl: Contains all the RTL source code
      -> ./libs: Contains all generic library modules created to support router
      -> ./router_modules: Contains all router stages and custom router modules
      -> router_top.sv: Top router module
  -> ./synthesis: Folder for running synthesis
      -> rtl.tcl: TCL file to run the synthesis
  -> ./testbench: Contains all the testbenches created to test RTL
      -> ./libs: Testbenches for a libs modules
      -> ./router_modules: Testbenches for all router specific modules
      -> tb_router_top.sv: Testbench for top router module
  -> ./reports: Contains the reports generated from the synthesis run
      -> ./alloc_sep_arbit_mat: Contains the results for separable allocator + matrix arbiter
  	  -> ./alloc_sep_arbit_roundrob: Contains the results for the separable allocator + round robin arbiter
  	  -> ./alloc_wave_arbit_mat: Contains the results for the wavefront allocator + matrix arbiter
  	  -> ./alloc_wave_arbit_roundrob: Contains the results for the wavefront allocator + round robin arbiter
  -> Makefile
  -> VR_define.vh: Top level define file for changing the router configurations
  -> README.md: Github readme file
  -> sample_router_results.log: Sample output from the testbench run of router top module
  -> sample_topology_results.log: Sample output from the testbench run of the
  -> area_rep.png: Pie charts representing the area distribution for each of the synthesis results in ./reports
  -> power_rep.png: Pie charts representing the power distribution for each of the synthesis results in ./reports
  -> report_area.py: Python script to generate the area pie charts and create the area_rep.png from the ./reports
  -> report_power.py: Python script to generate the power pie charts and create the power_rep.png from the ./reports

Steps to run functional verification:
Running router top testbench:
  -> Run the tool setup commands mentioned in the “Tool Setup” section
  -> Run the following commands:
  -> make clean
  -> make

Expected Output:
  -> Command line report generated
  -> test.vcd: VCD file for visual debug which can be opened using “gtkwave -f test.vcd”

The report contains the status of each router stage at each time stamp. Different stages displayed (demarcated by ********* identifiers):
  -> INPUT SIGNALS: Inputs and outputs to and from the router top connections.
  -> VC BUFFER STATUS: Shows current status of each buffer (shows only the top/head of the buffer)
  -> BUFFER WRITE: The buffer the flit will be written to for each port
  -> VC AVALABILITY: Shows the available output VCs during the VC allocation stage along with the mask generated.
  -> VC ALLOCATION: Shows output VC allocated for each input VC
  -> SA ALLOCATION: Shows output port allocated for each input port
  -> BUFFER READ: Shows the buffer which will be read
  -> SWITCH TRAVERSAL: Shows outputs signals post switch traversal

The data propagation can be tracked starting “Time = 80” when the inputs are applied.
Running topology testbench:
  -> Updated the Makefile. In line 24, edit the line to state: TESTBENCH = testbench/tb_topology.sv
  -> Run the following commands:
  -> make clean
  -> make
  
Expected Output:
  -> Command line report generated
  -> test.vcd: VCD file for visual debug which can be opened using “gtkwave -f test.vcd”

The report contains the flits injected into the network. Flit format (for 5x5 torus configured into the testbench), 7 MSB bits represent the vc id and destination (2 bits + 5 bits). The LSB 11 bits are randomly added to created tracking IDs for tracking the flit across the report. The report shows:
  -> Input flits injected into each router
  -> Output flits ejected from each router

Steps to run synthesis:
  -> Run: cd ./synthesis
  -> Run: /tools/software/cadence/genus/latest/bin/genus -legacy_ui
  -> Run: source ./rtl.tcl in the genus prompt

The generated logs and rep can be viewed in the same folder.

