module if_id (
    input  logic        clk,
    input  logic        reset,
    input  logic         stall,
    input  logic         flush,

    input  logic [31:0] pc_in,
    input  logic [31:0] pc_plus4_in,
    input  logic [31:0] instruction_in,

    output logic [31:0] pc_out,
    output logic [31:0] pc_plus4_out,
    output logic [31:0] instruction_out
);

    always_ff @(posedge clk) begin
        if (reset || flush) begin
            pc_out          <= '0;
            pc_plus4_out    <= '0;
            instruction_out <= 32'h00000013;
        end
        else if (!stall) begin
            pc_out          <= pc_in;
            pc_plus4_out    <= pc_plus4_in;
            instruction_out <= instruction_in;
        end
    end

endmodule
