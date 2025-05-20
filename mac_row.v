module mac_row (
    clk, reset, execute, load, a_select,
    nzero_weights_flat, w_indexes_flat,
    in_activation_flat, in_psum_flat, act_index_flat,
    final_psum_flat, load_out
);

    parameter nz = 8;
    parameter bw = 4;
    parameter psum_bw = 20;
    parameter ncol = 2;
    parameter col = 4;

    input clk, reset, execute, load, a_select;

    input [nz*bw-1:0] nzero_weights_flat;   // Flattened: [nz][bw]
    input [nz*2-1:0] w_indexes_flat;        // Flattened: [nz][2]
    input [2*bw-1:0] in_activation_flat;    // Flattened: [2][bw]
    input [col*psum_bw-1:0] in_psum_flat;   // Flattened: [col][psum_bw]
    input [2*2-1:0] act_index_flat;         // Flattened: [2][2]

    output [col*psum_bw-1:0] final_psum_flat;
    output load_out;

    reg [psum_bw-1:0] int_psum [0:col-1];
    reg [psum_bw-1:0] final_psum [0:col-1];
    reg [psum_bw-1:0] temp_psum [0:col-1];

    wire [psum_bw-1:0] in_psum [0:col-1];

    // Intermediate wires for module output
    wire [psum_bw-1:0] out_psum_wire [0:ncol-1];
    wire [1:0]         w_index_out_wire [0:ncol-1];

    reg load_q, execute_q;
    assign load_out = load_q;

    integer i;
    // Unpack input psum and pack final output psum
    generate
        genvar idx;
        for (idx = 0; idx < col; idx = idx + 1) begin : UNPACK_PSUM
            assign in_psum[idx] = in_psum_flat[psum_bw*idx +: psum_bw];
            assign final_psum_flat[psum_bw*idx +: psum_bw] = final_psum[idx];
        end
    endgenerate

    // Update temp_psum from int_psum + mac_tile outputs
    always @(*) begin
        for (i = 0; i < col; i = i + 1)
            temp_psum[i] = int_psum[i];

        for (i = 0; i < ncol; i = i + 1)
            temp_psum[w_index_out_wire[i]] = temp_psum[w_index_out_wire[i]] + out_psum_wire[i];
    end       
    
    
  always @(*) begin
    for (i = 0; i < col; i = i + 1)
        final_psum[i] = int_psum[i];
    end

    // Sequential block for int_psum and final_psum
    always @(posedge clk) begin
        execute_q <= execute;
        load_q <= load;

        if (reset) begin
            for (i = 0; i < col; i = i + 1) begin
                int_psum[i] <= 0;
                final_psum[i] <= 0;
            end
        end else if (execute_q) begin
            if (load_q) begin
                for (i = 0; i < col; i = i + 1)
                    int_psum[i] <= in_psum[i];
            end else begin
                for (i = 0; i < col; i = i + 1)
                    int_psum[i] <= temp_psum[i];
            end
        end
    end                 
    
    
    

    // Connect mac_tile_wrapper instances
    generate
        genvar tile;
        for (tile = 0; tile < ncol; tile = tile + 1) begin : col_num
            localparam integer slice_start = tile * col;

            wire [bw*col-1:0] in_weight_slice;
            wire [2*col-1:0]  w_index_slice;

            // Slice weights and indices for each tile
            assign in_weight_slice = nzero_weights_flat[(slice_start*bw) +: (col*bw)];
            assign w_index_slice   = w_indexes_flat[(slice_start*2) +: (col*2)];

            mac_tile_wrapper #(
                .bw(bw),
                .psum_bw(psum_bw),
                .depth(col)
            ) mac_tile_instance (
                .clk(clk),
                .reset(reset),
                .execute(execute_q),
                .a_select(a_select),
                .in_activation_flat(in_activation_flat),
                .in_weight_flat(in_weight_slice),
                .a_index_flat(act_index_flat),
                .w_index_flat(w_index_slice),
                .out_psum(out_psum_wire[tile]),        // fixed
                .w_index_out(w_index_out_wire[tile])   // fixed
            );
        end
    endgenerate

endmodule