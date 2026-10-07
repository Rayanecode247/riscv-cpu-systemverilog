`timescale 1ns/1ps

module user_program_tb;
    logic clk = 0;
    logic reset = 1;
    logic [31:0] debug_pc, debug_instruction, debug_wb_data;
    logic debug_load_stall, debug_wb_reg_write, debug_mem_write;
    logic [1:0] debug_forward_a, debug_forward_b;
    logic [4:0] debug_wb_rd;
    logic [31:0] debug_mem_address, debug_mem_write_data;
    integer max_cycles;
    integer cycles = 0;
    integer halt_count = 0;
    integer index;
    logic halted = 0;

    cpu_top dut (
        .clk(clk), .reset(reset),
        .debug_pc(debug_pc), .debug_instruction(debug_instruction),
        .debug_load_stall(debug_load_stall),
        .debug_forward_a(debug_forward_a), .debug_forward_b(debug_forward_b),
        .debug_wb_reg_write(debug_wb_reg_write), .debug_wb_rd(debug_wb_rd),
        .debug_wb_data(debug_wb_data), .debug_mem_write(debug_mem_write),
        .debug_mem_address(debug_mem_address), .debug_mem_write_data(debug_mem_write_data)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset) begin
            cycles <= 0;
            halt_count <= 0;
            halted <= 0;
        end else begin
            cycles <= cycles + 1;
            if (dut.d_instruction == 32'h0000006f) begin
                if (halt_count < 8) halt_count <= halt_count + 1;
                if (halt_count >= 7) halted <= 1;
            end
        end
    end

    initial begin
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 10000;
        $dumpfile("build/user_program.vcd");
        $dumpvars(0, user_program_tb);
        repeat (2) @(posedge clk);
        reset = 0;
        fork
            begin
                wait (halted);
            end
            begin
                repeat (max_cycles) @(posedge clk);
                if (!halted) $fatal(1, "program did not reach jal x0,0 within %0d cycles", max_cycles);
            end
        join_any
        disable fork;
        repeat (5) @(posedge clk);
        $display("Program reached jal x0,0 after approximately %0d cycles", cycles);
        $display("Architectural register state:");
        for (index = 0; index < 32; index++)
            $display("x%0d = %08x", index, dut.u_register_file.regs[index]);
        $display("Nonzero data RAM words (byte addresses):");
        for (index = 0; index < 1024; index++) begin
            if ({dut.u_data_memory.mem[index*4+3], dut.u_data_memory.mem[index*4+2],
                 dut.u_data_memory.mem[index*4+1], dut.u_data_memory.mem[index*4]} != 0)
                $display("mem[%0d] = %08x", index*4,
                         {dut.u_data_memory.mem[index*4+3], dut.u_data_memory.mem[index*4+2],
                          dut.u_data_memory.mem[index*4+1], dut.u_data_memory.mem[index*4]});
        end
        $display("RESULT: PROGRAM RUN COMPLETE");
        $finish;
    end
endmodule
