module ex_mem (
    input  logic        clk,
    input  logic        reset,

    input  logic         reg_write_in,
    input  logic         mem_read_in,
    input  logic         mem_write_in,
    input  logic         branch_in,
    input  logic         jump_in,
    input  logic [1:0]   result_src_in,
    input  logic [2:0]   funct3_in,

    input  logic [31:0] alu_result_in,
    input  logic         zero_in,
    input  logic [31:0] write_data_in,
    input  logic [31:0] pc_plus4_in,
    input  logic [31:0] branch_target_in,
    input  logic [4:0]  rd_in,

    output logic         reg_write_out,
    output logic         mem_read_out,
    output logic         mem_write_out,
    output logic         branch_out,
    output logic         jump_out,
    output logic [1:0]   result_src_out,
    output logic [2:0]   funct3_out,

    output logic [31:0] alu_result_out,
    output logic         zero_out,
    output logic [31:0] write_data_out,
    output logic [31:0] pc_plus4_out,
    output logic [31:0] branch_target_out,
    output logic [4:0]  rd_out
);

    always_ff @(posedge clk) begin
        if (reset) begin
            reg_write_out     <= 1'b0;
            mem_read_out      <= 1'b0;
            mem_write_out     <= 1'b0;
            branch_out        <= 1'b0;
            jump_out          <= 1'b0;
            result_src_out    <= 2'b00;
            funct3_out        <= 3'b000;

            alu_result_out    <= '0;
            zero_out          <= 1'b0;
            write_data_out    <= '0;
            pc_plus4_out      <= '0;
            branch_target_out <= '0;
            rd_out            <= '0;
        end
        else begin
            reg_write_out     <= reg_write_in;
            mem_read_out      <= mem_read_in;
            mem_write_out     <= mem_write_in;
            branch_out        <= branch_in;
            jump_out          <= jump_in;
            result_src_out    <= result_src_in;
            funct3_out        <= funct3_in;

            alu_result_out    <= alu_result_in;
            zero_out          <= zero_in;
            write_data_out    <= write_data_in;
            pc_plus4_out      <= pc_plus4_in;
            branch_target_out <= branch_target_in;
            rd_out            <= rd_in;
        end
    end

endmodule
