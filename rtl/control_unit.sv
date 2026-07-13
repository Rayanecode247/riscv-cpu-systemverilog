module control_unit (
    input  logic [6:0] opcode,

    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       branch,
    output logic       jump,
    output logic       alu_src,
    output logic [1:0] alu_src_a,
    output logic [1:0] alu_op,
    output logic [1:0] result_src
);

    localparam logic [6:0] OP_RTYPE  = 7'b0110011;
    localparam logic [6:0] OP_ITYPE  = 7'b0010011;
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;

    localparam logic [1:0] SRC_A_REG  = 2'b00;
    localparam logic [1:0] SRC_A_PC   = 2'b01;
    localparam logic [1:0] SRC_A_ZERO = 2'b10;

    localparam logic [1:0] RESULT_ALU  = 2'b00;
    localparam logic [1:0] RESULT_MEM  = 2'b01;
    localparam logic [1:0] RESULT_PC4  = 2'b10;

    always_comb begin
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_src    = 1'b0;
        alu_src_a  = SRC_A_REG;
        alu_op     = 2'b00;
        result_src = RESULT_ALU;

        unique case (opcode)
            OP_RTYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_src_a = SRC_A_REG;
                alu_op    = 2'b10;
            end

            OP_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_src_a = SRC_A_REG;
                alu_op    = 2'b11;
            end

            OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                alu_src_a  = SRC_A_REG;
                mem_read   = 1'b1;
                result_src = RESULT_MEM;
                alu_op     = 2'b00;
            end

            OP_STORE: begin
                alu_src   = 1'b1;
                alu_src_a = SRC_A_REG;
                mem_write = 1'b1;
                alu_op    = 2'b00;
            end

            OP_BRANCH: begin
                branch    = 1'b1;
                alu_src   = 1'b0;
                alu_src_a = SRC_A_REG;
                alu_op    = 2'b01;
            end

            OP_JAL: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                alu_src    = 1'b1;
                alu_src_a  = SRC_A_PC;
                result_src = RESULT_PC4;
                alu_op     = 2'b00;
            end

            OP_JALR: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                alu_src    = 1'b1;
                alu_src_a  = SRC_A_REG;
                result_src = RESULT_PC4;
                alu_op     = 2'b00;
            end

            OP_LUI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_src_a = SRC_A_ZERO;
                alu_op    = 2'b00;
            end

            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_src_a = SRC_A_PC;
                alu_op    = 2'b00;
            end

            default: ;
        endcase
    end

endmodule
