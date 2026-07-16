module cpu_top #(
    parameter int IMEM_DEPTH = 1024,
    parameter int DMEM_DEPTH = 1024
)(
    input logic clk,
    input logic reset
);

    logic [31:0] f_pc;
    logic [31:0] f_pc_next;
    logic [31:0] f_pc_plus4;
    logic [31:0] f_instruction;

    logic pc_stall;
    logic pc_redirect_valid;
    logic [31:0] pc_redirect_target;

    logic if_id_stall;
    logic if_id_flush;
    logic [31:0] d_pc;
    logic [31:0] d_pc_plus4;
    logic [31:0] d_instruction;

    logic [6:0] d_opcode;
    logic [4:0] d_rd;
    logic [2:0] d_funct3;
    logic [4:0] d_rs1;
    logic [4:0] d_rs2;
    logic       d_funct7_5;

    logic       d_reg_write, d_mem_read, d_mem_write, d_branch, d_jump, d_alu_src;
    logic [1:0] d_alu_src_a, d_alu_op, d_result_src;
    logic [31:0] d_immediate;
    logic [31:0] d_read_data1, d_read_data2;

    logic id_ex_flush;

    logic       e_reg_write, e_mem_read, e_mem_write, e_branch, e_jump, e_alu_src;
    logic [1:0] e_alu_src_a, e_alu_op, e_result_src;
    logic [2:0] e_funct3;
    logic       e_funct7_5;
    logic [31:0] e_pc, e_pc_plus4;
    logic [31:0] e_read_data1, e_read_data2;
    logic [31:0] e_immediate;
    logic [4:0] e_rs1, e_rs2, e_rd;

    logic hazard_stall;
    logic [1:0] e_forward_a, e_forward_b;
    logic [31:0] e_operand_a_fwd, e_operand_b_fwd;
    logic [31:0] e_alu_op_a, e_alu_op_b;
    logic [3:0] e_alu_ctrl;
    logic [31:0] e_alu_result;
    logic       e_zero;
    logic [31:0] e_branch_target;
    logic       e_branch_taken;
    logic       e_redirect_valid;
    logic [31:0] e_redirect_target;

    logic       m_reg_write, m_mem_read, m_mem_write, m_branch, m_jump;
    logic [1:0] m_result_src;
    logic [2:0] m_funct3;
    logic [31:0] m_alu_result;
    logic       m_zero;
    logic [31:0] m_write_data;
    logic [31:0] m_pc_plus4;
    logic [31:0] m_branch_target;
    logic [4:0] m_rd;

    logic [31:0] m_read_data;

    logic       w_reg_write;
    logic [1:0] w_result_src;
    logic [31:0] w_alu_result;
    logic [31:0] w_read_data;
    logic [31:0] w_pc_plus4;
    logic [4:0] w_rd;
    logic [31:0] w_write_data;

    assign f_pc_plus4 = f_pc + 32'd4;

    always_comb begin
        if (pc_redirect_valid)
            f_pc_next = pc_redirect_target;
        else if (pc_stall)
            f_pc_next = f_pc;
        else
            f_pc_next = f_pc_plus4;
    end

    always_ff @(posedge clk) begin
        if (reset)
            f_pc <= 32'h00000000;
        else
            f_pc <= f_pc_next;
    end

    instruction_memory #(
        .WIDTH(32),
        .DEPTH(IMEM_DEPTH),
        .ADDR_BITS(32)
    ) u_instruction_memory (
        .addr(f_pc),
        .instruction(f_instruction)
    );

    if_id u_if_id (
        .clk(clk),
        .reset(reset),
        .stall(if_id_stall),
        .flush(if_id_flush),
        .pc_in(f_pc),
        .pc_plus4_in(f_pc_plus4),
        .instruction_in(f_instruction),
        .pc_out(d_pc),
        .pc_plus4_out(d_pc_plus4),
        .instruction_out(d_instruction)
    );

    assign d_opcode   = d_instruction[6:0];
    assign d_rd       = d_instruction[11:7];
    assign d_funct3   = d_instruction[14:12];
    assign d_rs1      = d_instruction[19:15];
    assign d_rs2      = d_instruction[24:20];
    assign d_funct7_5 = d_instruction[30];

    control_unit u_control_unit (
        .opcode(d_opcode),
        .reg_write(d_reg_write),
        .mem_read(d_mem_read),
        .mem_write(d_mem_write),
        .branch(d_branch),
        .jump(d_jump),
        .alu_src(d_alu_src),
        .alu_src_a(d_alu_src_a),
        .alu_op(d_alu_op),
        .result_src(d_result_src)
    );

    immediate_generator u_immediate_generator (
        .instruction(d_instruction),
        .immediate(d_immediate)
    );

    register_file u_register_file (
        .clk(clk),
        .reg_write(w_reg_write),
        .read_reg1(d_rs1),
        .read_reg2(d_rs2),
        .write_reg(w_rd),
        .write_data(w_write_data),
        .read_data1(d_read_data1),
        .read_data2(d_read_data2)
    );

    id_ex u_id_ex (
        .clk(clk),
        .reset(reset),
        .flush(id_ex_flush),

        .reg_write_in(d_reg_write),
        .mem_read_in(d_mem_read),
        .mem_write_in(d_mem_write),
        .branch_in(d_branch),
        .jump_in(d_jump),
        .alu_src_in(d_alu_src),
        .alu_src_a_in(d_alu_src_a),
        .alu_op_in(d_alu_op),
        .result_src_in(d_result_src),
        .funct3_in(d_funct3),

        .pc_in(d_pc),
        .pc_plus4_in(d_pc_plus4),
        .read_data1_in(d_read_data1),
        .read_data2_in(d_read_data2),
        .immediate_in(d_immediate),
        .rs1_in(d_rs1),
        .rs2_in(d_rs2),
        .rd_in(d_rd),
        .funct7_5_in(d_funct7_5),

        .reg_write_out(e_reg_write),
        .mem_read_out(e_mem_read),
        .mem_write_out(e_mem_write),
        .branch_out(e_branch),
        .jump_out(e_jump),
        .alu_src_out(e_alu_src),
        .alu_src_a_out(e_alu_src_a),
        .alu_op_out(e_alu_op),
        .result_src_out(e_result_src),
        .funct3_out(e_funct3),

        .pc_out(e_pc),
        .pc_plus4_out(e_pc_plus4),
        .read_data1_out(e_read_data1),
        .read_data2_out(e_read_data2),
        .immediate_out(e_immediate),
        .rs1_out(e_rs1),
        .rs2_out(e_rs2),
        .rd_out(e_rd),
        .funct7_5_out(e_funct7_5)
    );

    hazard_detection_unit u_hazard_detection_unit (
        .id_ex_rd(e_rd),
        .id_ex_mem_read(e_mem_read),
        .if_id_rs1(d_rs1),
        .if_id_rs2(d_rs2),
        .stall(hazard_stall)
    );

    assign pc_stall    = hazard_stall;
    assign if_id_stall = hazard_stall;
    assign if_id_flush = pc_redirect_valid;
    assign id_ex_flush = hazard_stall | pc_redirect_valid;

    forwarding_unit u_forwarding_unit (
        .id_ex_rs1(e_rs1),
        .id_ex_rs2(e_rs2),
        .ex_mem_rd(m_rd),
        .ex_mem_reg_write(m_reg_write),
        .mem_wb_rd(w_rd),
        .mem_wb_reg_write(w_reg_write),
        .forward_a(e_forward_a),
        .forward_b(e_forward_b)
    );

    always_comb begin
        unique case (e_forward_a)
            2'b10:   e_operand_a_fwd = m_alu_result;
            2'b01:   e_operand_a_fwd = w_write_data;
            default: e_operand_a_fwd = e_read_data1;
        endcase
    end

    always_comb begin
        unique case (e_forward_b)
            2'b10:   e_operand_b_fwd = m_alu_result;
            2'b01:   e_operand_b_fwd = w_write_data;
            default: e_operand_b_fwd = e_read_data2;
        endcase
    end

    always_comb begin
        unique case (e_alu_src_a)
            2'b01:   e_alu_op_a = e_pc;
            2'b10:   e_alu_op_a = '0;
            default: e_alu_op_a = e_operand_a_fwd;
        endcase
    end

    assign e_alu_op_b = e_alu_src ? e_immediate : e_operand_b_fwd;

    alu_control u_alu_control (
        .alu_op(e_alu_op),
        .funct3(e_funct3),
        .funct7_5(e_funct7_5),
        .alu_control(e_alu_ctrl)
    );

    alu u_alu (
        .operand_a(e_alu_op_a),
        .operand_b(e_alu_op_b),
        .alu_control(e_alu_ctrl),
        .alu_result(e_alu_result),
        .zero(e_zero)
    );

    assign e_branch_target = e_pc + e_immediate;

    // Branch condition: alu_op==2'b01 always computes rs1-rs2 (SUB) regardless
    // of funct3, so `zero` alone only gives correct semantics for BEQ
    // (funct3=000). BNE (funct3=001) must branch when NOT equal, so we invert
    // zero using funct3[0]. NOTE: BLT/BGE/BLTU/BGEU (funct3 100/101/110/111)
    // are NOT supported by this datapath yet -- that would require alu_control
    // to select SLT/SLTU for the branch alu_op case based on funct3, which is
    // not implemented here. Only BEQ/BNE are functionally correct today.
    assign e_branch_taken = e_branch & (e_funct3[0] ? ~e_zero : e_zero);

    assign e_redirect_valid   = e_jump | e_branch_taken;
    assign e_redirect_target  = e_jump ? e_alu_result : e_branch_target;
    assign pc_redirect_valid  = e_redirect_valid;
    assign pc_redirect_target = e_redirect_target;

    ex_mem u_ex_mem (
        .clk(clk),
        .reset(reset),

        .reg_write_in(e_reg_write),
        .mem_read_in(e_mem_read),
        .mem_write_in(e_mem_write),
        .branch_in(e_branch),
        .jump_in(e_jump),
        .result_src_in(e_result_src),
        .funct3_in(e_funct3),

        .alu_result_in(e_alu_result),
        .zero_in(e_zero),
        .write_data_in(e_operand_b_fwd),
        .pc_plus4_in(e_pc_plus4),
        .branch_target_in(e_branch_target),
        .rd_in(e_rd),

        .reg_write_out(m_reg_write),
        .mem_read_out(m_mem_read),
        .mem_write_out(m_mem_write),
        .branch_out(m_branch),
        .jump_out(m_jump),
        .result_src_out(m_result_src),
        .funct3_out(m_funct3),

        .alu_result_out(m_alu_result),
        .zero_out(m_zero),
        .write_data_out(m_write_data),
        .pc_plus4_out(m_pc_plus4),
        .branch_target_out(m_branch_target),
        .rd_out(m_rd)
    );

    data_memory #(
        .DEPTH(DMEM_DEPTH)
    ) u_data_memory (
        .clk(clk),
        .mem_write(m_mem_write),
        .mem_read(m_mem_read),
        .addr(m_alu_result),
        .write_data(m_write_data),
        .funct3(m_funct3),
        .read_data(m_read_data)
    );

    mem_wb u_mem_wb (
        .clk(clk),
        .reset(reset),

        .reg_write_in(m_reg_write),
        .result_src_in(m_result_src),

        .alu_result_in(m_alu_result),
        .read_data_in(m_read_data),
        .pc_plus4_in(m_pc_plus4),
        .rd_in(m_rd),

        .reg_write_out(w_reg_write),
        .result_src_out(w_result_src),

        .alu_result_out(w_alu_result),
        .read_data_out(w_read_data),
        .pc_plus4_out(w_pc_plus4),
        .rd_out(w_rd)
    );

    always_comb begin
        unique case (w_result_src)
            2'b01:   w_write_data = w_read_data;
            2'b10:   w_write_data = w_pc_plus4;
            default: w_write_data = w_alu_result;
        endcase
    end

endmodule
