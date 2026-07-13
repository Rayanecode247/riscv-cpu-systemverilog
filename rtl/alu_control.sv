module alu_control (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic       funct7_5,

    output logic [3:0] alu_control
);

    localparam logic [3:0] ALU_AND  = 4'b0000;
    localparam logic [3:0] ALU_OR   = 4'b0001;
    localparam logic [3:0] ALU_ADD  = 4'b0010;
    localparam logic [3:0] ALU_SUB  = 4'b0110;
    localparam logic [3:0] ALU_SLT  = 4'b0111;
    localparam logic [3:0] ALU_SLTU = 4'b1000;
    localparam logic [3:0] ALU_SLL  = 4'b1001;
    localparam logic [3:0] ALU_SRL  = 4'b1010;
    localparam logic [3:0] ALU_SRA  = 4'b1011;
    localparam logic [3:0] ALU_XOR  = 4'b1100;
    localparam logic [3:0] ALU_NOR  = 4'b1101;

    always_comb begin
        unique case (alu_op)
            2'b00: alu_control = ALU_ADD;

            2'b01: alu_control = ALU_SUB;

            2'b10: begin
                unique case (funct3)
                    3'b000:  alu_control = funct7_5 ? ALU_SUB : ALU_ADD;
                    3'b111:  alu_control = ALU_AND;
                    3'b110:  alu_control = ALU_OR;
                    3'b100:  alu_control = ALU_XOR;
                    3'b010:  alu_control = ALU_SLT;
                    3'b011:  alu_control = ALU_SLTU;
                    3'b001:  alu_control = ALU_SLL;
                    3'b101:  alu_control = funct7_5 ? ALU_SRA : ALU_SRL;
                    default: alu_control = ALU_ADD;
                endcase
            end

            2'b11: begin
                unique case (funct3)
                    3'b000:  alu_control = ALU_ADD;
                    3'b111:  alu_control = ALU_AND;
                    3'b110:  alu_control = ALU_OR;
                    3'b100:  alu_control = ALU_XOR;
                    3'b010:  alu_control = ALU_SLT;
                    3'b011:  alu_control = ALU_SLTU;
                    3'b001:  alu_control = ALU_SLL;
                    3'b101:  alu_control = funct7_5 ? ALU_SRA : ALU_SRL;
                    default: alu_control = ALU_ADD;
                endcase
            end

            default: alu_control = ALU_ADD;
        endcase
    end

endmodule
