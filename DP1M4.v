module DP1M4 #(
  parameter bw       = 4,
  parameter psum_bw  = 20,
  parameter nnz      = 2,
  parameter n        = 4
) (
  input  wire                   clk,
  input  wire                   reset,
  input  wire                   load,
  input  wire                   execute,
  input  wire                   a_select,
  input  wire [nnz*bw-1:0]      weights_flat,
  input  wire [n-1:0]           w_index,
  input  wire [2*bw-1:0]        activation_flat,
  input  wire [3:0]             activation_index_flat,
  input  wire [psum_bw-1:0]     psum_in,
  output reg  [psum_bw-1:0]     psum_out
);

  // unpack activations
  wire [bw-1:0]   activation    [0:1];
  wire [1:0]      activation_i  [0:1];
  assign activation   [0] = activation_flat[bw-1:0];
  assign activation   [1] = activation_flat[2*bw-1:bw];
  assign activation_i [0] = activation_index_flat[1:0];
  assign activation_i [1] = activation_index_flat[3:2];

  // select based on a_select
  wire [bw-1:0] act_val   = a_select ? activation[1]    : activation[0];
  wire [1:0]    act_index = a_select ? activation_i[1]  : activation_i[0];

  // combinationally extract up to nnz indices from one‐hot w_index[n-1:0]
  reg  [1:0]    w_indexes [0:nnz-1];
  integer       p;
  reg  [1:0]    j;
  always @(*) begin
    // default all slots to zero
    for (p = 0; p < nnz; p = p + 1)
      w_indexes[p] = 2'b00;

    j = 0;
    for (p = 0; p < n; p = p + 1) begin
      if (w_index[p]) begin
        if (j < nnz) begin
          w_indexes[j] = p[1:0];
          j = j + 1;
        end
      end
    end
  end

  // pick the right weight
  wire        hit      = (act_index == w_indexes[0]) || (act_index == w_indexes[1]);
  wire [bw-1:0] w0      = weights_flat[bw-1:0];
  wire [bw-1:0] w1      = weights_flat[2*bw-1:bw];
  wire [bw-1:0] weight_sel = hit
                             ? (act_index == w_indexes[0] ? w0 : w1)
                             : {bw{1'b0}};

  // single clocked process with enable‐style gating
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      psum_out <= {psum_bw{1'b0}};
    end else if (execute && load) begin
      psum_out <= psum_in;
    end else if (execute && !load && hit) begin
      psum_out <= psum_out + weight_sel * act_val;
    end
  end

endmodule
