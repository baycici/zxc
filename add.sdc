set clock_cycle 0.58 
set io_delay 0.2 

set clock_port clk

create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {x[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {x[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {x[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {x[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {y[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {y[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {y[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {y[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {z[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {z[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {z[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {z[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {out[5]}] 
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {out[4]}] 
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {out[3]}] 
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {out[2]}] 
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {out[1]}] 
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {out[0]}] 




