`timescale 1ns/1ps

module demo_tb;
    logic clk = 1'b0;
    logic reset = 1'b1;
    logic [31:0] debug_pc;
    logic [31:0] debug_instruction;
    logic debug_load_stall;
    logic [1:0] debug_forward_a;
    logic [1:0] debug_forward_b;
    logic debug_wb_reg_write;
    logic [4:0] debug_wb_rd;
    logic [31:0] debug_wb_data;
    logic debug_mem_write;
    logic [31:0] debug_mem_address;
    logic [31:0] debug_mem_write_data;

    integer cycles = 0;
    integer halt_count = 0;
    integer index;
    logic halted = 1'b0;

    // Match the RTL's 1024-word ROM default so its initial root-image read
    // does not truncate before this testbench loads the separate demo image.
    cpu_top #(.IMEM_DEPTH(1024), .DMEM_DEPTH(64)) dut (
        .clk(clk),
        .reset(reset),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_load_stall(debug_load_stall),
        .debug_forward_a(debug_forward_a),
        .debug_forward_b(debug_forward_b),
        .debug_wb_reg_write(debug_wb_reg_write),
        .debug_wb_rd(debug_wb_rd),
        .debug_wb_data(debug_wb_data),
        .debug_mem_write(debug_mem_write),
        .debug_mem_address(debug_mem_address),
        .debug_mem_write_data(debug_mem_write_data)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset) begin
            cycles <= 0;
            halt_count <= 0;
            halted <= 1'b0;
        end else begin
            cycles <= cycles + 1;
            if (dut.d_instruction == 32'h0000006f) begin
                if (halt_count < 8)
                    halt_count <= halt_count + 1;
                if (halt_count >= 7)
                    halted <= 1'b1;
            end
        end
    end

    function automatic logic [31:0] ram_word(input integer byte_address);
        ram_word = {
            dut.u_data_memory.mem[byte_address + 3],
            dut.u_data_memory.mem[byte_address + 2],
            dut.u_data_memory.mem[byte_address + 1],
            dut.u_data_memory.mem[byte_address]
        };
    endfunction

    initial begin
        $dumpfile("build/demo_sort.vcd");
        $dumpvars(0, demo_tb);

        // The CPU's own initialization reads the repository-root image.
        // This demo-only load overrides it without touching that file.
        #1;
        $readmemh("demo/instructions.hex", dut.u_instruction_memory.mem);
        $readmemh("demo/data.hex", dut.u_data_memory.mem);

        if (ram_word(0) !== 32'd8 || ram_word(4) !== 32'd3 ||
            ram_word(8) !== 32'd10 || ram_word(12) !== 32'd1 ||
            ram_word(16) !== 32'd6)
            $fatal(1, "demo/data.hex did not initialize the five input words as expected");

        $display("Initial array at byte addresses 0..16: 8, 3, 10, 1, 6");
        repeat (2) @(posedge clk);
        reset = 1'b0;

        wait (halted);
        repeat (5) @(posedge clk);

        $display("Program reached jal x0,0 after %0d cycles", cycles);
        $display("Final array at byte addresses 0..16:");
        for (index = 0; index < 5; index = index + 1)
            $display("RAM byte address %0d = %0d", index * 4, ram_word(index * 4));

        if (ram_word(0) !== 32'd1 || ram_word(4) !== 32'd3 ||
            ram_word(8) !== 32'd6 || ram_word(12) !== 32'd8 ||
            ram_word(16) !== 32'd10)
            $fatal(1, "sort demo finished with unexpected RAM contents");

        $display("RESULT: SORT DEMO PASS");
        $finish;
    end

    initial begin
        repeat (2000) @(posedge clk);
        if (!halted)
            $fatal(1, "demo did not reach jal x0,0 within 2000 cycles");
    end
endmodule
