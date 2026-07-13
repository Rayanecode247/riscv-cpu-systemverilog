module hazard_detection_unit (
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_mem_read,

    input  logic [4:0] if_id_rs1,
    input  logic [4:0] if_id_rs2,

    output logic       stall
);

    always_comb begin
        stall = 1'b0;

        if (id_ex_mem_read &&
            ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)) &&
            (id_ex_rd != '0)) begin
            stall = 1'b1;
        end
    end

endmodule
