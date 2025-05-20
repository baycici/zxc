module DP1M4_row (
    clk, 
    reset,
    weights_flat,          // [nnz*bw-1:0]
    weight_mask,           // [total-1:0]
    activation_flat,       // [2*bw-1:0]
    activation_index_flat, // [3:0]
    load,
    execute,
    psum_in_flat,          // [col*psum_bw-1:0]
    a_select,
    load_out,
    psum_out_flat          // [col*psum_bw-1:0]
);

    parameter col = 4;
    parameter bw = 4;
    parameter psum_bw = 20;
    parameter nnz = 8;
    parameter ncol = 2;
    parameter total = 16;

    input clk, reset, load, execute, a_select;
    input [nnz*bw-1:0] weights_flat;
    input [total-1:0] weight_mask;
    input [2*bw-1:0] activation_flat;
    input [3:0] activation_index_flat;
    input [col*psum_bw-1:0] psum_in_flat;

    output load_out;
    output [col*psum_bw-1:0] psum_out_flat;

    reg load_q, execute_q, load_2q;
    assign load_out = load_2q;

    always @(posedge clk) begin
        load_q <= load;
        execute_q <= execute;
        load_2q <= load_q;
    end

    // Instantiate col DP1M4 blocks
    wire [psum_bw-1:0] psum_out_flat_wires [0:col-1];

    genvar gi;
    generate
        for (gi = 0; gi < col; gi = gi + 1) begin : col_gen
            wire [bw-1:0] weight_subset_0;
            wire [bw-1:0] weight_subset_1;
            wire [1:0] w_index_bits;
            wire [psum_bw-1:0] psum_in_local;
            wire [psum_bw-1:0] psum_out_local;

            assign weight_subset_0 = weights_flat[(gi*ncol + 0)*bw +: bw];
            assign weight_subset_1 = weights_flat[(gi*ncol + 1)*bw +: bw];
            assign w_index_bits = weight_mask[gi*4 +: ncol];
            assign psum_in_local = psum_in_flat[gi*psum_bw +: psum_bw];

            DP1M4 #(
                .bw(bw),
                .psum_bw(psum_bw)
            ) dp1m4_inst (
                .clk(clk),
                .reset(reset),
                .load(load_q),
                .execute(execute_q),
                .a_select(a_select),
                .weights_flat({weight_subset_1, weight_subset_0}),
                .w_index(w_index_bits),
                .activation_flat(activation_flat),
                .activation_index_flat(activation_index_flat),
                .psum_in(psum_in_local),
                .psum_out(psum_out_local)
            );

            assign psum_out_flat[gi*psum_bw +: psum_bw] = psum_out_local;
        end
    endgenerate

endmodule
