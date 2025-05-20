`timescale 1ns/1ps

module DP1M4_row_tb;

    parameter col = 4;
    parameter bw = 4;
    parameter psum_bw = 20;
    parameter nnz = 8;
    parameter ncol = 2;
    parameter total = 16;

    // Inputs
    reg clk, reset, load, execute, a_select;
    reg [nnz*bw-1:0] weights_flat;
    reg [total-1:0] weight_mask;
    reg [2*bw-1:0] activation_flat;
    reg [3:0] activation_index_flat;
    reg [col*psum_bw-1:0] psum_in_flat;

    // Outputs
    wire [col*psum_bw-1:0] psum_out_flat;
    wire load_out;

    integer i;

    // Instantiate DUT
    DP1M4_row #(
        .col(col),
        .bw(bw),
        .psum_bw(psum_bw),
        .nnz(nnz),
        .ncol(ncol),
        .total(total)
    ) dut (
        .clk(clk),
        .reset(reset),
        .weights_flat(weights_flat),
        .weight_mask(weight_mask),
        .activation_flat(activation_flat),
        .activation_index_flat(activation_index_flat),
        .load(load),
        .execute(execute),
        .a_select(a_select),
        .psum_in_flat(psum_in_flat),
        .load_out(load_out),
        .psum_out_flat(psum_out_flat)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        load = 0;
        execute = 0;
        a_select = 0;

        // Initialize weights_flat: each weight = index+1
        for (i = 0; i < nnz; i = i + 1)
            weights_flat[i*bw +: bw] = i + 1;

        // Alternating mask pattern
        weight_mask = 16'b1010101010101010;

        // Initial psums
        for (i = 0; i < col; i = i + 1)
            psum_in_flat[i*psum_bw +: psum_bw] = 20'd10;

        // Set initial activation and index
        activation_flat = {4'd5, 4'd3};             // [act1, act0]
        activation_index_flat = {2'd1, 2'd0};       // [idx1, idx0]

        #10;
        reset = 0;

        // Load phase
        $display("== Load Phase ==");
        load = 1;
        execute = 1;
        #10;

        // Execution phase, activations should update
        $display("== Execution Phase ==");
        load = 0;
        execute = 1;

        for (i = 0; i < 3; i = i + 1) begin
            #10;
            activation_flat = activation_flat + 8'd1;
            activation_index_flat = activation_index_flat + 4'd1;
        end

        // Load high again: activations must *not* update
        $display("== Blocking Activation Change During Load ==");
        load = 1;
        #10;
        activation_flat = 8'h00;
        activation_index_flat = 4'h0;

        #10;
        load = 0;
        execute = 0;

        // Observe final psum
        $display("== Final psum_out_flat ==");
        for (i = 0; i < col; i = i + 1) begin
            $display("psum_out_flat[%0d] = %0d", i, psum_out_flat[i*psum_bw +: psum_bw]);
        end

        $finish;
    end

endmodule