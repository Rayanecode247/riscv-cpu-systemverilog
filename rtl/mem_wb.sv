module mem_wb (
    input  logic        clk,
    input  logic        reset,

    input  logic         reg_write_in,
    input  logic [1:0]   result_src_in,

    input  logic [31:0] alu_result_in,
    input  logic [31:0] read_data_in,
    input  logic [31:0] pc_plus4_in,
    input  logic [4:0]  rd_in,

    output logic         reg_write_out,
    output logic [1:0]   result_src_out,

    output logic [31:0] alu_result_out,
    output logic [31:0] read_data_out,
    output logic [31:0] pc_plus4_out,
    output logic [4:0]  rd_out
);

    always_ff @(posedge clk) begin
        if (reset) begin
            reg_write_out  <= 1'b0;
            result_src_out <= 2'b00;

            alu_result_out <= '0;
            read_data_out  <= '0;
            pc_plus4_out   <= '0;
            rd_out         <= '0;
        end
        else begin
            reg_write_out  <= reg_write_in;
            result_src_out <= result_src_in;

            alu_result_out <= alu_result_in;
            read_data_out  <= read_data_in;
            pc_plus4_out   <= pc_plus4_in;
            rd_out         <= rd_in;
        end
    end

endmodule
