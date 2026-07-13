module register_file #(
    parameter int WIDTH = 32,
    parameter int ADDR_WIDTH = 5
)(
    input  logic                   clk,
    input  logic                   reg_write,
    input  logic [ADDR_WIDTH-1:0]  read_reg1,
    input  logic [ADDR_WIDTH-1:0]  read_reg2,
    input  logic [ADDR_WIDTH-1:0]  write_reg,
    input  logic [WIDTH-1:0]       write_data,
    output logic [WIDTH-1:0]       read_data1,
    output logic [WIDTH-1:0]       read_data2
);

    logic [WIDTH-1:0] regs [0:(1<<ADDR_WIDTH)-1];

    assign read_data1 = (read_reg1 == '0) ? '0 : regs[read_reg1];
    assign read_data2 = (read_reg2 == '0) ? '0 : regs[read_reg2];

    always_ff @(posedge clk) begin
        if (reg_write && (write_reg != '0)) begin
            regs[write_reg] <= write_data;
        end
    end

endmodule
