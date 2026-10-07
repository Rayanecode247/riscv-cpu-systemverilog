`timescale 1ns/1ps

module cpu_top_tb;
    logic clk = 0;
    logic reset = 1;
    int checks = 0;
    int failures = 0;
    int cycles = 0;
    bit saw_load_stall = 0;
    bit saw_ex_forward = 0;
    bit saw_wb_forward = 0;
    bit saw_odd_jalr_target = 0;
    bit saw_aligned_jalr_redirect = 0;
    bit jalr_alignment_failed = 0;
    logic [31:0] jalr_target_expected;

    cpu_top #(.IMEM_DEPTH(64), .DMEM_DEPTH(64)) dut (.clk(clk), .reset(reset));
    always #5 clk = ~clk;

    task automatic check_reg(input int index, input logic [31:0] expected);
        begin
            checks++;
            if (dut.u_register_file.regs[index] !== expected) begin
                failures++;
                $display("FAIL x%0d expected=%08x actual=%08x", index, expected, dut.u_register_file.regs[index]);
            end else $display("PASS x%0d = %08x", index, expected);
        end
    endtask

    always @(posedge clk) begin
        if (!reset) begin
            cycles <= cycles + 1;
            if (dut.hazard_stall) saw_load_stall <= 1;
            if (dut.e_forward_a == 2'b10 || dut.e_forward_b == 2'b10) saw_ex_forward <= 1;
            if (dut.e_forward_a == 2'b01 || dut.e_forward_b == 2'b01) saw_wb_forward <= 1;
        end
    end

    always @(posedge clk) begin
        if (!reset && dut.e_redirect_valid && dut.e_jump &&
            (dut.e_alu_src_a == 2'b00) && !saw_aligned_jalr_redirect) begin
            jalr_target_expected = {dut.e_alu_result[31:1], 1'b0};
            if (dut.e_alu_result[0]) saw_odd_jalr_target <= 1;
            #1;
            if ((dut.f_pc === jalr_target_expected) && (dut.f_pc[0] === 1'b0))
                saw_aligned_jalr_redirect <= 1;
            else
                jalr_alignment_failed <= 1;
        end
    end

    initial begin
        $dumpfile("build/cpu_top_tb.vcd");
        $dumpvars(0, cpu_top_tb);
        #1;
        // Hand-coded RV32I regression image. This is a test program, not the
        // user's later demonstration program.
        dut.u_instruction_memory.mem[0]  = 32'h00500093; // addi x1,x0,5
        dut.u_instruction_memory.mem[1]  = 32'h00700113; // addi x2,x0,7
        dut.u_instruction_memory.mem[2]  = 32'h002081b3; // add x3,x1,x2
        dut.u_instruction_memory.mem[3]  = 32'h40118233; // sub x4,x3,x1
        dut.u_instruction_memory.mem[4]  = 32'h0021f2b3; // and x5,x3,x2
        dut.u_instruction_memory.mem[5]  = 32'h00402023; // sw x4,0(x0)
        dut.u_instruction_memory.mem[6]  = 32'h00002303; // lw x6,0(x0)
        dut.u_instruction_memory.mem[7]  = 32'h00130393; // addi x7,x6,1 (load-use)
        dut.u_instruction_memory.mem[8]  = 32'h00800413; // addi x8,x0,8
        dut.u_instruction_memory.mem[9]  = 32'h00838463; // beq x7,x8,+8
        dut.u_instruction_memory.mem[10] = 32'h06300493; // skipped poison
        dut.u_instruction_memory.mem[11] = 32'h00900493; // addi x9,x0,9
        dut.u_instruction_memory.mem[12] = 32'h0080056f; // jal x10,+8
        dut.u_instruction_memory.mem[13] = 32'h05800593; // skipped poison
        dut.u_instruction_memory.mem[14] = 32'h00150593; // addi x11,x10,1
        dut.u_instruction_memory.mem[15] = 32'h04900693; // addi x13,x0,73
        dut.u_instruction_memory.mem[16] = 32'h00068767; // jalr x14,0(x13)
        dut.u_instruction_memory.mem[17] = 32'h06300613; // skipped poison
        dut.u_instruction_memory.mem[18] = 32'h00070793; // addi x15,x14,0
        dut.u_instruction_memory.mem[19] = 32'h0000006f; // jal x0,0

        repeat (2) @(posedge clk);
        reset = 0;
        wait (dut.f_pc == 32'd76);
        repeat (10) @(posedge clk);
        check_reg(0, 0);
        check_reg(1, 5);
        check_reg(2, 7);
        check_reg(3, 12);
        check_reg(4, 7);
        check_reg(5, 4);
        check_reg(6, 7);
        check_reg(7, 8);
        check_reg(8, 8);
        check_reg(9, 9);
        check_reg(10, 52);
        check_reg(11, 53);
        check_reg(13, 73);
        check_reg(14, 68);
        check_reg(15, 68);
        checks++;
        if ({dut.u_data_memory.mem[3],dut.u_data_memory.mem[2],dut.u_data_memory.mem[1],dut.u_data_memory.mem[0]} !== 32'd7) begin
            failures++;
            $display("FAIL RAM[0] expected=00000007 actual=%08x", {dut.u_data_memory.mem[3],dut.u_data_memory.mem[2],dut.u_data_memory.mem[1],dut.u_data_memory.mem[0]});
        end else $display("PASS RAM[0] = 00000007");
        checks++;
        if (!saw_load_stall) begin failures++; $display("FAIL load-use stall was not observed"); end
        else $display("PASS load-use stall observed");
        checks++;
        if (!saw_ex_forward) begin failures++; $display("FAIL EX/MEM forwarding was not observed"); end
        else $display("PASS EX/MEM forwarding observed");
        checks++;
        if (!saw_wb_forward) begin failures++; $display("FAIL MEM/WB forwarding was not observed"); end
        else $display("PASS MEM/WB forwarding observed");
        checks++;
        if (!saw_odd_jalr_target || jalr_alignment_failed || !saw_aligned_jalr_redirect) begin
            failures++;
            $display("FAIL JALR odd target was not redirected with bit 0 cleared");
        end else $display("PASS JALR odd target 73 redirected to aligned PC 72");
        if (failures == 0) begin
            $display("RESULT: PASS (%0d checks, %0d cycles)", checks, cycles);
            $finish;
        end else begin
            $display("RESULT: FAIL (%0d/%0d checks failed)", failures, checks);
            $fatal(1, "integration checks failed");
        end
    end

    initial begin
        repeat (300) @(posedge clk);
        $fatal(1, "testbench timeout");
    end
endmodule
