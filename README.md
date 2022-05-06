# Virtual_Channel_Router
ECE 6115: Project of configurable virtual channel router

Team:   <br />
Member 1:   <br />
Name: Varun Saxena   <br />
Member 2:  <br />
Name: Venkata Hanuma Sandilya Balemarthy <br />

* <b>Source code:</b> <br />
  * Github repository: https://github.com/varunsax12/Virtual_Channel_Router  <br />
  * Tar Ball: virtual_channel_router_files.tar.gz  <br />

* <b>Run Environment:</b>  <br />
  * Server: ece-linlabsrv01.ece.gatech.edu  <br />

* <b>Tool Setup: (specific to server)</b>  <br />
  Run the following commands:  <br />
  * Synopsys VCS  <br />
      * export VCS_HOME=/tools/software/synopsys/vcs/R-2020.12-SP2/  <br />
      * export PATH=/tools/software/synopsys/vcs/R-2020.12-SP2/:/tools/software/synopsys/vcs/R-2020.12-SP2//bin:$PATH  <br />

* <b>Directory Structure:</b>  <br />
  Top folder: Virtual_Channel_Router  <br />
  * ./rtl: Contains all the RTL source code  <br />
      * ./libs: Contains all generic library modules created to support router  <br />
      * ./router_modules: Contains all router stages and custom router modules  <br />
      * router_top.sv: Top router module  <br />
  * ./synthesis: Folder for running synthesis  <br />
      * rtl.tcl: TCL file to run the synthesis  <br />
  * ./testbench: Contains all the testbenches created to test RTL  <br />
      * ./libs: Testbenches for a libs modules  <br />
      * ./router_modules: Testbenches for all router specific modules  <br />
      * tb_router_top.sv: Testbench for top router module  <br />
  * ./reports: Contains the reports generated from the synthesis run  <br />
      * ./alloc_sep_arbit_mat: Contains the results for separable allocator + matrix arbiter  <br />
  	  * ./alloc_sep_arbit_roundrob: Contains the results for the separable allocator + round robin arbiter  <br />
  	  * ./alloc_wave_arbit_mat: Contains the results for the wavefront allocator + matrix arbiter  <br />
  	  * ./alloc_wave_arbit_roundrob: Contains the results for the wavefront allocator + round robin arbiter  <br />
  * Makefile  <br />
  * VR_define.vh: Top level define file for changing the router configurations  <br />
  * README.md: Github readme file  <br />
  * sample_router_results.log: Sample output from the testbench run of router top module  <br />
  * sample_topology_results.log: Sample output from the testbench run of the topology module  <br />
  * area_rep.png: Pie charts representing the area distribution for each of the synthesis results in ./reports  <br />
  * power_rep.png: Pie charts representing the power distribution for each of the synthesis results in ./reports  <br />
  * report_area.py: Python script to generate the area pie charts and create the area_rep.png from the ./reports  <br />
  * report_power.py: Python script to generate the power pie charts and create the power_rep.png from the ./reports  <br />

* <b>Steps to run functional verification:</b>  <br />
  Running router top testbench:  <br />
  * Run the tool setup commands mentioned in the “Tool Setup” section  <br />
  * Run the following commands:  <br />
  * make clean  <br />
  * make  <br />

* <b>Expected Output:</b>  <br />
  * Command line report generated  <br />
  * test.vcd: VCD file for visual debug which can be opened using “gtkwave -f test.vcd”  <br />

* <b>The report contains the status of each router stage at each time stamp. Different stages displayed (demarcated by ********* identifiers):</b>  <br />
  * INPUT SIGNALS: Inputs and outputs to and from the router top connections.  <br />
  * VC BUFFER STATUS: Shows current status of each buffer (shows only the top/head of the buffer)  <br />
  * BUFFER WRITE: The buffer the flit will be written to for each port  <br />
  * VC AVALABILITY: Shows the available output VCs during the VC allocation stage along with the mask generated.  <br />
  * VC ALLOCATION: Shows output VC allocated for each input VC  <br />
  * SA ALLOCATION: Shows output port allocated for each input port  <br />
  * BUFFER READ: Shows the buffer which will be read  <br />
  * SWITCH TRAVERSAL: Shows outputs signals post switch traversal  <br />

* <b>The data propagation can be tracked starting “Time = 80” when the inputs are applied.</b>  <br />
  Running topology testbench:  <br /> 
  * Updated the Makefile. In line 24, edit the line to state: TESTBENCH = testbench/tb_topology.sv  <br />
  * Run the following commands:  <br />
  * make clean  <br />
  * make  <br />
  
* <b>Expected Output:</b>  <br />
  * Command line report generated  <br />
  * test.vcd: VCD file for visual debug which can be opened using “gtkwave -f test.vcd”  <br />

* <b>The report contains the flits injected into the network. Flit format (for 5x5 torus configured into the testbench), 7 MSB bits represent the vc id and destination (2 bits + 5 bits). The LSB 11 bits are randomly added to created tracking IDs for tracking the flit across the report. The report shows:</b>  <br />
  * Input flits injected into each router  <br />
  * Output flits ejected from each router  <br />

* <b> Steps to run synthesis:</b>  <br />
  * Run: cd ./synthesis  <br />
  * Run: /tools/software/cadence/genus/latest/bin/genus -legacy_ui  <br />
  * Run: source ./rtl.tcl in the genus prompt  <br />

* <b>The generated logs and rep can be viewed in the same folder.</b>  <br />

