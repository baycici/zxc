

module latch_clock_gating(
    input clk,
    input enable,
    output gated_clk
);

    reg latch_q;

    always @(clk) begin
        if (!clk)
            latch_q <= enable;
    end

    assign gated_clk = clk & latch_q;

endmodule

















module DP1M4 (
    clk, reset, weights_flat, a_select, w_index, activation_flat, activation_index_flat,
    psum_in, load, execute, psum_out
);
    parameter bw = 4;
    parameter psum_bw = 20;
    parameter nnz = 2;
    parameter n = 4;

    input clk, reset, load, execute, a_select;
    input [nnz*bw-1:0] weights_flat;
    input [n-1:0] w_index;
    input [2*bw-1:0] activation_flat;
    input [3:0] activation_index_flat;
    input [psum_bw-1:0] psum_in;

    output [psum_bw-1:0] psum_out;

    // Internal registers
    reg [1:0] w_indexes [0:nnz-1];
    reg [psum_bw-1:0] psum_q;

    wire [bw-1:0] activation [0:1];
    wire [1:0] activation_index [0:1];

    assign activation[0] = activation_flat[bw-1:0];
    assign activation[1] = activation_flat[2*bw-1:bw];

    assign activation_index[0] = activation_index_flat[1:0];
    assign activation_index[1] = activation_index_flat[3:2];

    wire [bw-1:0] act_sel;
    wire [1:0] act_i_sel;

    assign act_sel    = (a_select == 1'b1) ? activation[1]      : activation[0];
    assign act_i_sel  = (a_select == 1'b1) ? activation_index[1]: activation_index[0];

    assign psum_out = psum_q;

    // Wire signal detection and weight selection
    wire signal;
    wire [bw-1:0] weight_0, weight_1, weight_sel;

    assign weight_0 = weights_flat[bw-1:0];
    assign weight_1 = weights_flat[2*bw-1:bw];

    assign signal = (act_i_sel == w_indexes[0] || act_i_sel == w_indexes[1]) ? 1'b1 : 1'b0;
    assign weight_sel = signal ? ((act_i_sel == w_indexes[0]) ? weight_0 : weight_1) : {bw{1'b0}};

    // Clock gating
    wire gating_cond;
    wire gated_clk;

    assign gating_cond = signal && !load && execute;

    latch_clock_gating clk_gate (
        .clk(clk),
        .enable(gating_cond),
        .gated_clk(gated_clk)
    );

    // Index extraction logic (combinational)
    reg [1:0] i, j;
    always @(*) begin
        j = 0;
        for (i = 0; i < n; i = i + 1) begin
            if (w_index[i]) begin
                w_indexes[j] = i[1:0];
                j = j + 1;
            end
        end
    end

    // Accumulation on gated clock
    always @(posedge gated_clk) begin
        if (reset)
            psum_q <= 0;
        else
            psum_q <= psum_q + weight_sel * act_sel;
    end

    // Load phase accumulation
    always @(posedge clk) begin
        if (reset)
            psum_q <= 0;
        else if (execute && load)
            psum_q <= psum_in;
    end

endmodule