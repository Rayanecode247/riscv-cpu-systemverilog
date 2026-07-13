module alu #(
    parameter int WIDTH = 32
)(
    input  logic [WIDTH-1:0] operand_a,
    input  logic [WIDTH-1:0] operand_b,
    input  logic [3:0]       alu_control,
    output logic [WIDTH-1:0] alu_result,
    output logic              zero
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

    logic [WIDTH-1:0] result_comb;
    logic [4:0]       shamt;

    assign shamt = operand_b[4:0];

    always_comb begin
        unique case (alu_control)
            ALU_AND:  result_comb = operand_a & operand_b;
            ALU_OR:   result_comb = operand_a | operand_b;
            ALU_ADD:  result_comb = operand_a + operand_b;
            ALU_SUB:  result_comb = operand_a - operand_b;
            ALU_SLT:  result_comb = { {(WIDTH-1){1'b0}},
                                       ($signed(operand_a) < $signed(operand_b)) };
            ALU_SLTU: result_comb = { {(WIDTH-1){1'b0}},
                                       (operand_a < operand_b) };
            ALU_SLL:  result_comb = operand_a << shamt;
            ALU_SRL:  result_comb = operand_a >> shamt;
            ALU_SRA:  result_comb = $signed(operand_a) >>> shamt;
            ALU_XOR:  result_comb = operand_a ^ operand_b;
            ALU_NOR:  result_comb = ~(operand_a | operand_b);
            default:  result_comb = '0;
        endcase
    end

    assign alu_result = result_comb;
    assign zero       = (result_comb == '0);

endmodule
