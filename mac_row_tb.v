`timescale 1ns/1ps

module tb_mac_row;

  parameter nz = 8;
  parameter bw = 4;
  parameter psum_bw = 20;
  parameter ncol = 2;
  parameter col = 4;

  reg clk;
  reg reset;
  reg execute;
  reg load;
  reg a_select;

  reg [nz*bw-1:0] nzero_weights_flat;
  reg [nz*2-1:0] w_indexes_flat;
  reg [2*bw-1:0] in_activation_flat;
  reg [col*psum_bw-1:0] in_psum_flat;
  reg [2*2-1:0] act_index_flat;

  wire [col*psum_bw-1:0] final_psum_flat;
  wire load_out;

  mac_row #(
    .nz(nz),
    .bw(bw),
    .psum_bw(psum_bw),
    .ncol(ncol),
    .col(col)
  ) dut (
    .clk(clk),
    .reset(reset),
    .execute(execute),
    .load(load),
    .a_select(a_select),
    .nzero_weights_flat(nzero_weights_flat),
    .w_indexes_flat(w_indexes_flat),
    .in_activation_flat(in_activation_flat),
    .in_psum_flat(in_psum_flat),
    .act_index_flat(act_index_flat),
    .final_psum_flat(final_psum_flat),
    .load_out(load_out)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    reset = 1;
    execute = 0;
    load = 0;
    a_select = 0;

    nzero_weights_flat = 0;
    w_indexes_flat = 0;
    in_activation_flat = 0;
    in_psum_flat = 0;
    act_index_flat = 0;

    #15 reset = 0;   // release reset
    execute = 1;    // keep execute high from now on

    // Initial stable inputs before load pulse
    nzero_weights_flat = {
      4'd1,4'd2,4'd3,4'd4,
      4'd5,4'd6,4'd7,4'd8
    };

    w_indexes_flat = {
      2'd0,2'd1,2'd2,2'd3,
      2'd0,2'd1,2'd2,2'd3
    };

    in_psum_flat = {
      20'd1000, 20'd2000, 20'd3000, 20'd4000
    };

    act_index_flat = {2'd1, 2'd0};

    // Activations can change anytime load=0, so start them here:
    in_activation_flat = {4'd9, 4'd10};

    #10;

    // Pulse load high for 1 cycle to load weights etc.
    @(posedge clk);
    load = 1;
    a_select = 1;

    // During load, activations remain stable (no new activations)
    in_activation_flat = in_activation_flat;

    @(posedge clk);
    load = 0;
    a_select = 0;

    // Now that load=0, new activations can come in every cycle
    // Change activations on each clock cycle to simulate streaming activations
    repeat (10) begin
      @(posedge clk);
      in_activation_flat = in_activation_flat + 1;  // simple increment example
    end

    #50;

    $finish;
  end

  initial begin
    $display("Time\treset\texecute\tload\tload_out\tfinal_psum_flat\tin_activation_flat");
    $monitor("%0t\t%b\t%b\t%b\t%b\t%h\t%h", $time, reset, execute, load, load_out, final_psum_flat, in_activation_flat);
  end

endmodule