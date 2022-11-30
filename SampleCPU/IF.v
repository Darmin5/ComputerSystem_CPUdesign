`include "lib/defines.vh"
module IF(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,

    // input wire flush,
    // input wire [31:0] new_pc,

    input wire [`BR_WD-1:0] br_bus,

    output wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    output wire inst_sram_en,           //是否取指；inst表示指令，en表示使能信号
    output wire [3:0] inst_sram_wen,        //wen表示是否去写ram，这里inst我们只读不写
    output wire [31:0] inst_sram_addr,      //addr表示地址
    output wire [31:0] inst_sram_wdata      //wdata表示要写入的内容
);
    reg [31:0] pc_reg;          //PC寄存器
    reg ce_reg;                 //寄存器使能信号
    wire [31:0] next_pc;        //下一个pc的地址
    wire br_e;                  //分支指令使能信号
    wire [31:0] br_addr;        //分支地址

    assign {
        br_e,
        br_addr
    } = br_bus;         //跳转指令


    always @ (posedge clk) begin            //时序逻辑
        if (rst) begin
            pc_reg <= 32'hbfbf_fffc;
        end
        else if (stall[0]==`NoStop) begin           //如果流水线不stop，则跳转到下一条pc
            pc_reg <= next_pc;
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            ce_reg <= 1'b0;
        end
        else if (stall[0]==`NoStop) begin
            ce_reg <= 1'b1;
        end
    end


    assign next_pc = br_e ? br_addr             //查看跳转指令使能信号br_e，如果跳转，则下一条pc为要跳转的地址br_addr，否则下一条pc为当前pc+4
                   : pc_reg + 32'h4;

    
    assign inst_sram_en = ce_reg;
    assign inst_sram_wen = 4'b0;            //一直保持全0
    assign inst_sram_addr = pc_reg;
    assign inst_sram_wdata = 32'b0;         //一直保持全0
    assign if_to_id_bus = {
        ce_reg,
        pc_reg
    };

endmodule