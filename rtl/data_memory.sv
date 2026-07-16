module data_memory #(
    parameter int DEPTH = 1024
)(
    input  logic        clk,
    input  logic        mem_write,
    input  logic         mem_read,
    input  logic [31:0]  addr,
    input  logic [31:0]  write_data,
    input  logic [2:0]   funct3,
    output logic [31:0]  read_data
);

    localparam int BYTES = DEPTH * 4;

    logic [7:0] mem [0:BYTES-1];

    initial begin
        for (int i = 0; i < BYTES; i++) begin
            mem[i] = 8'h00;
        end
    end

    logic in_bounds_b0, in_bounds_b1, in_bounds_b2, in_bounds_b3;

    assign in_bounds_b0 = (addr     < BYTES);
    assign in_bounds_b1 = (addr + 1 < BYTES);
    assign in_bounds_b2 = (addr + 2 < BYTES);
    assign in_bounds_b3 = (addr + 3 < BYTES);

    always_ff @(posedge clk) begin
        if (mem_write) begin
            unique case (funct3)
                3'b000: begin
                    if (in_bounds_b0) mem[addr] <= write_data[7:0];
                end
                3'b001: begin
                    if (in_bounds_b0) mem[addr]     <= write_data[7:0];
                    if (in_bounds_b1) mem[addr + 1] <= write_data[15:8];
                end
                3'b010: begin
                    if (in_bounds_b0) mem[addr]     <= write_data[7:0];
                    if (in_bounds_b1) mem[addr + 1] <= write_data[15:8];
                    if (in_bounds_b2) mem[addr + 2] <= write_data[23:16];
                    if (in_bounds_b3) mem[addr + 3] <= write_data[31:24];
                end
                default: ;
            endcase
        end
    end

    logic [7:0] byte0, byte1, byte2, byte3;

    assign byte0 = in_bounds_b0 ? mem[addr]     : 8'b0;
    assign byte1 = in_bounds_b1 ? mem[addr + 1] : 8'b0;
    assign byte2 = in_bounds_b2 ? mem[addr + 2] : 8'b0;
    assign byte3 = in_bounds_b3 ? mem[addr + 3] : 8'b0;

    always_comb begin
        read_data = '0;
        if (mem_read) begin
            unique case (funct3)
                3'b000:  read_data = {{24{byte0[7]}}, byte0};
                3'b001:  read_data = {{16{byte1[7]}}, byte1, byte0};
                3'b010:  read_data = {byte3, byte2, byte1, byte0};
                3'b100:  read_data = {24'b0, byte0};
                3'b101:  read_data = {16'b0, byte1, byte0};
                default: read_data = '0;
            endcase
        end
    end

endmodule
