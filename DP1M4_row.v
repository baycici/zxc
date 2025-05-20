module DP1M4_row #(
    parameter col     = 4,
    parameter bw      = 4,
    parameter psum_bw = 20,
    parameter nnz     = 8,   // total number of weights in the big row
    parameter ncol    = 2,   // number of non-zeros per DP cell
    parameter n       = 4    // number of activation positions per DP cell
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   load,
    input  wire                   execute,
    input  wire                   a_select,
    input  wire [nnz*bw-1:0]      weights_flat,
    // now size the mask to col*n bits (= 4*4 = 16)
    input  wire [col*n-1:0]       weight_mask,
    input  wire [2*bw-1:0]        activation_flat,
    input  wire [2*2-1:0]         activation_index_flat,
    input  wire [col*psum_bw-1:0] psum_in_flat,

    output wire                   load_out,
    output wire [col*psum_bw-1:0] psum_out_flat
);

    // simple two-stage flop of load/execute for timing
    reg load_q, execute_q, load_2q;
    always @(posedge clk) begin
        load_q    <= load;
        execute_q <= execute;
        load_2q   <= load_q;
    end
    assign load_out = load_2q;

    genvar gi;
    generate
      for (gi = 0; gi < col; gi = gi + 1) begin : COL
        // local flattening of the incoming partial sums
        wire [psum_bw-1:0] psum_in_local  = psum_in_flat [gi*psum_bw +: psum_bw];
        wire [psum_bw-1:0] psum_out_local;

        // pick out exactly two weights for this column
        wire [bw-1:0] w0 = weights_flat[(gi*ncol + 0)*bw +: bw];
        wire [bw-1:0] w1 = weights_flat[(gi*ncol + 1)*bw +: bw];

        // extract a full 4-bit one-hot mask for DP1M4.n==4
        wire [n-1:0] w_index_bits = weight_mask[gi*n +: n];

        // instantiate the small 2-wide DP cell
        DP1M4 #(
          .bw(bw),
          .psum_bw(psum_bw),
          .nnz(ncol),  // override default=2
          .n(n)        // override default=4
        ) dp_inst (
          .clk                 (clk),
          .reset               (reset),
          .load                (load_q),
          .execute             (execute_q),
          .a_select            (a_select),
          .weights_flat        ({w1, w0}),
          .w_index             (w_index_bits),
          .activation_flat     (activation_flat),
          .activation_index_flat(activation_index_flat),
          .psum_in             (psum_in_local),
          .psum_out            (psum_out_local)
        );

        // re-flatten the result
        assign psum_out_flat[gi*psum_bw +: psum_bw] = psum_out_local;
      end
    endgenerate

endmodule
