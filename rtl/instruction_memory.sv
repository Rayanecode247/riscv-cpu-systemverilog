module instruction_memory #(
    parameter int WIDTH     = 32,
    parameter int DEPTH     = 1024,
    parameter int ADDR_BITS = 32
)(
    input  logic [ADDR_BITS-1:0] addr,
    output logic [WIDTH-1:0]     instruction
);

    localparam logic [31:0] NOP = 32'h00000013;

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH)-1:0] word_addr;

    initial begin
        $readmemh("instructions.hex", mem);
    end

    assign word_addr   = addr[$clog2(DEPTH)+1:2];
    assign instruction = (addr[$clog2(DEPTH)+1:2] < DEPTH) ? mem[word_addr] : NOP;

endmodule
