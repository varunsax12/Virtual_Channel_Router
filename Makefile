#
# make          <- runs simv (after compiling simv if needed)
# make all      <- runs simv (after compiling simv if needed)
# make simv     <- compile simv if needed (but do not run)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
#
#t

VCS = /tools/software/synopsys/vcs/latest/bin/vcs -sverilog +vc -Mupdate -line -full64

# For visual debugger
VISFLAGS = -lncurses

all:    simv
	./simv | tee program.out



#TESTBENCH = 	testbench/libs/tb_allocator_wavefront.sv
TESTBENCH = 	testbench/tb_router_top.sv
SIMFILES =	rtl/libs/*.sv	rtl/*.sv rtl/router_modules/*.sv\
	VR_define.vh
SYNFILES = synth/pipeline.vg


simv:	$(SIMFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SIMFILES)	-o simv

# For visual debugger
vis_simv:	$(SIMFILES) $(VISTESTBENCH)
	$(VCS) $(VISFLAGS) $(VISTESTBENCH) $(SIMFILES) -o vis_simv 
	./vis_simv

syn_simv:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) -o syn_simv 

syn:	syn_simv
	./syn_simv | tee syn_program.out

clean:
	rm -rf simv simv.daidir csrc vcs.key program.out
	rm -rf vis_simv vis_simv.daidir
	rm -rf dve*
	rm -rf syn_simv syn_simv.daidir syn_program.out
	rm -rf synsimv synsimv.daidir csrc vcdplus.vpd vcs.key synprog.out pipeline.out writeback.out vc_hdrs.h

nuke:	clean
	rm -f synth/*.vg synth/*.rep synth/*.ddc synth/*.chk synth/command.log
	rm -f synth/*.out command.log synth/*.db synth/*.svf