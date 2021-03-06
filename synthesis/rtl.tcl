#**************************************************/
#* Script for Cadence Genus Synthesis             */
#* Author: Sandilya Balemarthy                    */
#* Referenced from: Ivan Castellanos, OSU         */
#**************************************************/

#Setting osu pdk dir
set PDK_DIR /tools/designkits/NCSU/FreePDK45/

# All HDL files, separated by spaces
set hdl_files { allocator_top.sv allocator_wavefront.sv arbiter_round_robin.sv arbiter_top.sv index_2_one_hot.sv pipe_register_1D.sv \
allocator_separable.sv arbiter_matrix.sv fifo.sv one_hot_2_index.sv pipe_register_2D.sv priority_encoder.sv \
switch_allocator.sv elect_vc.sv route_compute.sv vc_allocator.sv crossbar.sv vc_availability.sv vc_req_2_port_req.sv \
router_top.sv }

# The Top-level Module, change example multiplyadd
set DESIGN router_top
# set current_design router_top

# Set clock pin name in design. If clk just leave untouched,
# otherwise change clk
set clkpin clk

# Clock period in ps
set delay 10000

#**************************************************/
# NO further changes past this point

set osucells ${PDK_DIR}/osu_soc

set_attribute hdl_search_path {/nethome/vbalemarthy3/ECE6115/project/ /nethome/vbalemarthy3/ECE6115/project/rtl/ /nethome/vbalemarthy3/ECE6115/project/rtl/router_modules /nethome/vbalemarthy3/ECE6115/project/rtl/libs} /
set_attribute lib_search_path {/tools/designkits/NCSU/FreePDK45/osu_soc/lib/source/signalstorm/files} /

set_attribute information_level 6 /

set_attribute library gscl45nm.lib
read_hdl -sv ${hdl_files}

elaborate $DESIGN

# Apply Constraints

set clock [define_clock -period ${delay} -name ${clkpin} [clock_ports]]	
external_delay -input   0 -clock clk [find / -port ports_in/*]
external_delay -output  0 -clock clk [find / -port ports_out/*]
# Sets transition to default values for Synopsys SDC format, fall/rise
# 400ps
dc::set_clock_transition .4 clk

check_design -unresolved

report timing -lint

# Synthesis
syn_gen
syn_map 

# Report generation
report timing > timing.rep
report gates  > cell.rep
report power  > power.rep

# Equivalent files being dumped
write_hdl -mapped >  ${DESIGN}.vh
write_sdc >  ${DESIGN}.sdc

puts \n 
puts "Synthesis Finished!         "
puts \n
puts "Check timing.rep, area.rep, gate.rep and power.rep for synthesis results"
puts \n
 
# Launch GUI
# gui_show
