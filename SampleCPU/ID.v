`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,            稍微更改一下注释
    input wire [`StallBus-1:0] stall,
    
    output wire stallreq,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,     //if段传到id段的信息

    input wire [31:0] inst_sram_rdata,          //指令要读取的数据

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus, //wb段前向的信息
    input wire [`EX_TO_RF_WD-1:0] ex_to_rf_bus, //ex段前向的信息
    input wire [`MEM_TO_RF_WD-1:0] mem_to_rf_bus, //mem段前向的信息

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,        //id段传向ex段的信息

    output wire [`BR_WD-1:0] br_bus         //跳转指令
);

    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;      //临时寄存器，用来存储if段传来的信息
    wire [31:0] inst;           //指令
    wire [31:0] id_pc;          //id段的pc值
    wire ce;                    //使能信号

    wire wb_rf_we;              //是否前向的使能信号？
    wire [4:0] wb_rf_waddr;     //wb前向信号中的“目标地址”
    wire [31:0] wb_rf_wdata;    //wb前向新号中的"传输数据"

    wire ex_rf_we;              //是否前向的使能信号？
    wire [4:0] ex_rf_waddr;     //ex前向信号中的“目标地址”
    wire [31:0] ex_rf_wdata;    //ex前向新号中的"传输数据"

    wire mem_rf_we;              //是否前向的使能信号？
    wire [4:0] mem_rf_waddr;     //mem前向信号中的“目标地址”
    wire [31:0] mem_rf_wdata;    //mem前向新号中的"传输数据"

    always @ (posedge clk) begin        //if_to_id的信息传过来，在每个时钟周期的上沿
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;        
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
        end
        else if (stall[1]==`NoStop) begin       //如果没有特殊情况，就会把信息赋给if_to_id_bus_r寄存器，所有ID段执行的指令都要从这个寄存器里取
            if_to_id_bus_r <= if_to_id_bus;
        end
    end
    
    //从inst ram中取指
    assign inst = inst_sram_rdata;
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;


    //forwarding线路，将ex,mem,wb封装的线路在这里了解包
    assign {            //WB段前递的路径，在regfile里面实现了(即上课说的前半段周期写回，后半段周期递给ID)
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;

    assign {
        ex_rf_we,
        ex_rf_waddr,
        ex_rf_wdata
    } = ex_to_rf_bus;

    assign {
        mem_rf_we,
        mem_rf_waddr,
        mem_rf_wdata
    } = mem_to_rf_bus;


    //设置一些必要线路
    wire [5:0] opcode;      //操作码
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;                 //指令要运算的类型,例如逻辑运算，移位运算、算术运算等

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;             //指令要运算的子类型，子类型是比类型更详细的运算类型，如当运算类型是逻辑运算时，子类型可以是“或”、“与”等运算
    wire [7:0]  mem_op;

    wire data_ram_en;
    wire [3:0] data_ram_wen;
    
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2, rf_data1, rf_data2;

    //operation for regfile
    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (rs ),
        .rdata1 (rf_data1 ),
        .raddr2 (rt ),
        .rdata2 (rf_data2 ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  )
    );
    //前推线路，修改操作数
    assign rdata1 = (ex_rf_we && (ex_rf_waddr == rs)) ? ex_rf_wdata:
                    (mem_rf_we && (mem_rf_waddr == rs)) ? mem_rf_wdata:
                    (wb_rf_we && (wb_rf_waddr == rs)) ? wb_rf_wdata:
                                                        rf_data1;
    assign rdata2 = (ex_rf_we && (ex_rf_waddr == rt)) ? ex_rf_wdata:
                    (mem_rf_we && (mem_rf_waddr == rt)) ? mem_rf_wdata:
                    (wb_rf_we && (wb_rf_waddr == rt)) ? wb_rf_wdata:
                                                        rf_data2;                                                    


    //hi & lo reg for mul and div(to do)



//decode inst   
    //locate content of inst
    assign opcode = inst[31:26];        //对于ori指令只需要通过判断26-31bit的值，即可判断是否是ori指令
    assign rs = inst[25:21];            //rs寄存器
    assign rt = inst[20:16];            //rt寄存器
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];            //立即数
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];         //偏移量
    assign sel = inst[2:0];


    //candidate inst & opetion      操作：如果判断当前inst是某条指令，则对应指令的wire变为1,如判断当前inst是add指令，则inst_add <=2'b1
    wire inst_add,  inst_addi,  inst_addu,  inst_addiu;
    wire inst_sub,  inst_subu,  inst_slt,   inst_slti;
    wire inst_sltu, inst_sltiu, inst_div,   inst_divu;
    wire inst_mult, inst_multu, inst_and,   inst_andi;
    wire inst_lui,  inst_nor,   inst_or,    inst_ori;
    wire inst_xor,  inst_xori,  inst_sllv,  inst_sll;
    wire inst_srav, instsra,    inst_srlv,  inst_srl;
    wire inst_beq,  inst_bne,   inst_bgez,  inst_bgtz;
    wire inst_blez, inst_bltz,  inst_bgezal,inst_bltzal;
    wire inst_j,    inst_jal,   inst_jr,    inst_jalr;
    wire inst_mfhi, inst_mflo,  inst_mthi,  inst_mtlo;
    wire inst_break,inst_syscall;
    wire inst_lb,   inst_lbu,   inst_lh,    inst_lhu,   inst_lw;
    wire inst_sb,   inst_sh,    inst_sw;
    wire inst_eret, inst_nfc0,  inst_mtc0;

    //控制alu运算单元的
    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;
    //解码器
    decoder_6_64 u0_decoder_6_64(   
    	.in  (opcode  ),      //假如opcode的前六位都是0，则可以判断是ori指令      
        .out (op_d )            //输出一个64bit的信号
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );

     decoder_5_32 u2_decoder_5_32(
    	.in  (rd  ),
        .out (rd_d )
    );

     decoder_5_32 u3_decoder_5_32(
    	.in  (sa  ),
        .out (sa_d )
    );

    //操作码
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_lui     = op_d[6'b00_1111];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_addu    = op_d[6'b00_0000] & func_d[6'b10_0001];
    assign inst_beq     = op_d[6'b00_0100];
    assign inst_sub     = op_d[6'b00_0000] & func_d[6'b10_0010];
    assign inst_subu    = op_d[6'b00_0000] & func_d[6'b10_0011];
    assign inst_j       = op_d[6'b00_0010];  
    assign inst_jal     = op_d[6'b00_0011];
    assign inst_jr      = op_d[6'b00_0000] & func_d[6'b00_1000];
    assign inst_jalr    = op_d[6'b00_0000] & func_d[6'b00_1001];
    assign inst_sll     = op_d[6'b00_0000] & func_d[6'b00_0000];
    assign inst_or      = op_d[6'b00_0000] & func_d[6'b10_0101];  
    assign inst_lw      = op_d[6'b10_0011] & func_d[6'b10_0101];


    //选操作数      这里src1和src2分别是两个存储操作数的寄存器，具体怎么选操作数，在ex段写
    // rs to reg1
    assign sel_alu_src1[0] = inst_ori | inst_addiu | inst_sub | inst_subu | inst_addu
                            |inst_or;

    // pc to reg1
    assign sel_alu_src1[1] = inst_jal | inst_jalr;

    // sa_zero_extend to reg1
    assign sel_alu_src1[2] = inst_sll;

    
    // rt to reg2
    assign sel_alu_src2[0] = inst_sub | inst_subu | inst_addu | inst_sll | inst_or;
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] = inst_lui | inst_addiu;

    // 32'b8 to reg2
    assign sel_alu_src2[2] = inst_jal | inst_jalr;

    // imm_zero_extend to reg2
    assign sel_alu_src2[3] = inst_ori;


    //choose the op to be applied   选操作逻辑
    assign op_add = inst_addiu | inst_jal | inst_jalr | inst_addu;
    assign op_sub = inst_sub | inst_subu;
    assign op_slt = 1'b0;
    assign op_sltu = 1'b0;
    assign op_and = 1'b0;
    assign op_nor = 1'b0;
    assign op_or = inst_ori | inst_or;
    assign op_xor = 1'b0;
    assign op_sll = inst_sll;
    assign op_srl = 1'b0;
    assign op_sra = 1'b0;
    assign op_lui = inst_lui;

    assign alu_op = {op_add, op_sub, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};

    assign mem_op = {inst_lb, inst_lbu, inst_lh, inst_lhu,
                     inst_lw, inst_sb,  inst_sh, inst_sw};

    


    //关于指令写回的内容
    // load and store enable
    assign data_ram_en = inst_lw;

    // write enable
    assign data_ram_wen = 1'b0;


    //一些写回数的操作,包括是否要写回regfile寄存器堆、要存在哪一位里
    // regfile store enable
    assign rf_we = inst_ori | inst_lui | inst_addiu | inst_addu | inst_sub | inst_subu | inst_jal | inst_jalr
                  |inst_sll | inst_or  | inst_lw;



    // store in [rd]
    assign sel_rf_dst[0] = inst_sub | inst_subu |inst_addu | inst_sll | inst_or;        //例如要是想存在rd堆里
    // store in [rt] 
    assign sel_rf_dst[1] = inst_ori | inst_lui | inst_addiu| inst_lw;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal | inst_jalr;            //jalr不是存在rd中吗？ --默认先存到31位寄存器中

    // sel for regfile address
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd   //则会把他扩展成5位
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
    assign sel_rf_res = inst_lw; 

    //一条指令解码结束，把信息封装好，传给EX段
    assign id_to_ex_bus = {
        mem_op,
        id_pc,          // 158:127
        inst,           // 126:95
        alu_op,         // 94:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rdata1,         // 63:32
        rdata2          // 31:0
    };

    //跳转模块
    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;
    wire [31:0] pc_plus_4;
    assign pc_plus_4 = id_pc + 32'h4;

    assign rs_eq_rt = (rdata1 == rdata2);

    assign br_e = inst_beq & rs_eq_rt 
                | inst_j |inst_jal | inst_jalr | inst_jr;
    assign br_addr = inst_beq  ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) 
                    :inst_j    ? {id_pc[31:28],instr_index,2'b0}
                    :inst_jal  ? {id_pc[32:28],instr_index,2'b0}
                    :inst_jr   ? rdata1
                    :inst_jalr ? rdata1 
                    :32'b0;

    assign br_bus = {
        br_e,
        br_addr
    };
    


endmodule