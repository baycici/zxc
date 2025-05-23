module DP1M4_row #(
  parameter bw      = 4,
  parameter psum_bw = 20,
  parameter nnz     = 2,
  parameter n       = 4,
  parameter M       = 4
) (
  // shared control + activation
  input  wire                   clk,
  input  wire                   reset,
  input  wire                   load,
  input  wire                   execute,
  input  wire [2*bw-1:0]        activation_flat,

  // per-lane control + data (packed into wide vectors)
  input  wire [M-1:0]           a_select,                   // one bit per lane
  input  wire [M*nnz*bw-1:0]    weights_flat,               // concatenated NNZ×BW per lane
  input  wire [M*n-1:0]         w_index,                    // concatenated n-bit one-hot per lane
  input  wire [M*4-1:0]         activation_index_flat,      // concatenated 4-bit per lane
  input  wire [M*psum_bw-1:0]   psum_in,                    // concatenated PSUM_BW per lane

  // outputs per lane
  output wire [M*psum_bw-1:0]   psum_out                    // concatenated PSUM_BW per lane
);

  localparam int W_STRIDE = nnz*bw;
  genvar i;
  generate
    for (i = 0; i < M; i = i + 1) begin : GEN_DP
      DP1M4 #(
        .bw      (bw),
        .psum_bw (psum_bw),
        .nnz     (nnz),
        .n       (n)
      ) dp_inst (
        .clk             (clk),
        .reset           (reset),
        .load            (load),
        .execute         (execute),
        .activation_flat (activation_flat),

        .a_select         (a_select[i]),
        .weights_flat     (weights_flat[(i+1)*W_STRIDE-1 : i*W_STRIDE]),
        .w_index          (w_index   [(i+1)*n-1      : i*n]),
        .activation_index_flat(activation_index_flat[(i+1)*4-1 : i*4]),
        .psum_in          (psum_in   [(i+1)*psum_bw-1 : i*psum_bw]),
        .psum_out         (psum_out  [(i+1)*psum_bw-1 : i*psum_bw])
      );
    end
  endgenerate

endmodule
