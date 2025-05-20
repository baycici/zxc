module mac_tile_wrapper (
    clk,
    reset,
    execute,
    a_select,
    in_activation_flat,
    in_weight_flat,
    a_index_flat,
    w_index_flat,
    out_psum,
    w_index_out
);

    parameter bw = 4;
    parameter psum_bw = 16;
    parameter depth = 4;

    input clk;
    input reset;
    input execute;
    input a_select;

    // Flattened inputs (since classic Verilog does not support unpacked ports)
    input [2*bw-1:0] in_activation_flat;   // 2 activations * bw bits each
    input [depth*bw-1:0] in_weight_flat;   // depth weights * bw bits each
    input [2*2-1:0] a_index_flat;           // 2 activations * 2 bits each
    input [depth*2-1:0] w_index_flat;       // depth weights * 2 bits each

    output reg [psum_bw-1:0] out_psum;
    output [1:0] w_index_out;

    // Internal registers/wires to hold unpacked data
    reg [bw-1:0] in_activation [0:1];
    reg [bw-1:0] in_weight [0:depth-1];
    reg [1:0] a_index [0:1];
    reg [1:0] w_index [0:depth-1];

    reg [bw-1:0] act_select, act_select_q;
    reg [1:0] act_select_index, act_select_index_q;
    reg [bw-1:0] select_w, select_w_q;
    reg [1:0] select_w_index, select_w_index_q;

    wire [psum_bw-1:0] product;

    integer i;

    // Unpack flattened inputs to arrays
    always @(*) begin
        for (i = 0; i < 2; i = i + 1) begin
            in_activation[i] = in_activation_flat[bw*i +: bw];
            a_index[i] = a_index_flat[2*i +: 2];
        end
        for (i = 0; i < depth; i = i + 1) begin
            in_weight[i] = in_weight_flat[bw*i +: bw];
            w_index[i] = w_index_flat[2*i +: 2];
        end
    end

    // Select activation and weight according to a_select and index
    always @(*) begin
        if (a_select) begin
            act_select = in_activation[1];
            act_select_index = a_index[1];
        end else begin
            act_select = in_activation[0];
            act_select_index = a_index[0];
        end

        select_w = in_weight[act_select_index];
        select_w_index = w_index[act_select_index];
    end

    // Multiply act_select_q * select_w_q (Verilog supports *)
    assign product = act_select_q * select_w_q;
    assign w_index_out = select_w_index_q;

    always @(posedge clk) begin
        if (reset) begin
            out_psum <= 0;
            act_select_q <= 0;
            act_select_index_q <= 0;
            select_w_q <= 0;
            select_w_index_q <= 0;
        end else begin
            act_select_q <= act_select;
            act_select_index_q <= act_select_index;
            select_w_q <= select_w;
            select_w_index_q <= select_w_index;

            if (execute) begin
                out_psum <= product;
            end
        end
    end

endmodule
