#######################################
# DC Compiler Options
#######################################
set_host_options -max_cores 16
define_design_lib WORK -path ./WORK

#Example: dc_shell-xg-t -f run_dc.tcl

#######################################
# Libraries
#######################################
set search_path "/usr/synopsys/syn/Q-2019.12-SP1/libraries/syn ./Lib"
set symbol_library "generic.sdb"
set target_library "NanGate_15nm_OCL.db"
set link_library "* dw_foundation.sldb NanGate_15nm_OCL.db"
set synthetic_library "dw_foundation.sldb"


# set the clock period (1GHz)
set CLK_PERIOD 30

# setting the port of clock, this is the input clock from your design
set CLOCK_INPUT clk


read_file -format verilog [getenv "INFILE"]
current_design fsm

create_clock -period  $CLK_PERIOD $CLOCK_INPUT
set_max_delay 0 -to [get_clocks clk]
set_cost_priority -delay
#set_cost_priority {max_delay area}
#set_switching_activity -static_probability 0.5 [get_net *]
#set_switching_activity -static_probability 0.02 [get_net dtselect]

# check internal DC representation for design consistency
check_design

# verifies timing setup is complete
check_timing

# enable DC ultra optimizations 
compile

# reports
report_area -hierarchy > ./Reports/[getenv "REPORT"]_area.rpt
report_power -hierarchy > ./Reports/[getenv "REPORT"]_power.rpt
report_timing -max_paths 30 > ./Reports/[getenv "REPORT"]_timing.rpt

# For testing purposes
#set test_default_scan_style multiplexed_flip_flop
#create_test_protocol -infer_asynch -infer_clock
#dft_drc

#write_test_protocol -output k-all.spf

# save design
#set filename [format "%s%s"  $my_toplevel ".ddc"]
# write -format ddc -hierarchy -output "cl_wrapper.ddc"

#start_gui

exit
