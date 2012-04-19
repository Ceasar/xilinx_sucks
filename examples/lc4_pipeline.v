mescale 1ns / 1ps
`define NOP 16'h0000

module lc4_processor(clk,
                    rst,
                    gwe,
                    imem_addr,
                    imem_out,
                    dmem_addr,
                    dmem_out,
                    dmem_we,
                    dmem_in,
                    test_stall,
                    test_pc,
                    test_insn,
                    test_regfile_we,
                    test_regfile_reg,
                    test_regfile_in,
                    test_nzp_we,
                    test_nzp_in,
                    test_dmem_we,
                    test_dmem_addr,
                    test_dmem_value,
                    switch_data,
                    seven_segment_data,
                    led_data
                    );
   
   input        clk;            // main clock
   input        rst;            // global reset
   input        gwe;            // global we for single-step clock
   
   output [15:0] imem_addr;   // Address to read from instruction memory
   input  [15:0] imem_out;      // Output of instruction memory
   output [15:0] dmem_addr;   // Address to read/write from/to data memory
   input  [15:0] dmem_out;      // Output of data memory
   output       dmem_we;        // Data memory write enable
   output [15:0] dmem_in;       // Value to write to data memory
   
   output [1:0]  test_stall;    // Testbench: is this is stall cycle? (don't compare the test values)
   output [15:0] test_pc;       // Testbench: program counter
   output [15:0] test_insn;     // Testbench: instruction bits
   output       test_regfile_we;  // Testbench: register file write enable
   output [2:0]  test_regfile_reg; // Testbench: which register to write in the register file
   output [15:0] test_regfile_in;  // Testbench: value to write into the register file
   output       test_nzp_we;    // Testbench: NZP condition codes write enable
   output [2:0]  test_nzp_in;   // Testbench: value to write to NZP bits
   output       test_dmem_we;   // Testbench: data memory write enable
   output [15:0] test_dmem_addr;   // Testbench: address to read/write memory
   output [15:0] test_dmem_value;  // Testbench: value read/writen from/to memory
   
   input  [7:0]   switch_data;
   output [15:0] seven_segment_data;
   output [7:0]  led_data;
     
    // *********************************************************************************
    // BYPASSING WIRES
    // *********************************************************************************
    
    // Execute
    wire [15:0] alu_in_a_mux_out;
    wire [1:0] alu_in_a_mux_sel;
    wire [15:0] alu_in_b_mux_out;
    wire [1:0] alu_in_b_mux_sel;
    
    // Memory
    wire [15:0] wm_mux_out;
    wire wm_mux_sel;
    
    // *********************************************************************************
    // Stall Wires
    // *********************************************************************************
    wire stall_out;
    wire [15:0] f_flush_out;
    
    // *********************************************************************************
    // Branch Predictor Wires
    // *********************************************************************************
    wire ne_out;
    
    // *********************************************************************************
    // REGISTER
    // *********************************************************************************
    
    //Control logic
    wire [1:0] r1sel_sel;
    wire [2:0] regfile_reg;
    wire r2sel_sel, regfile_in_sel, regfile_reg_sel;
    wire regfile_we, dmem_we, nzp_we;
    //control_logic cl(imem_out, r1sel_sel, r2sel_sel, regfile_reg_sel, pc_or_alu_out_sel, regfile_in_sel, regfile_we, dmem_we, nzp_we);
    
    // Reg. File
    wire [2:0] r1sel, r2sel;
    wire pc_next_sel;
    
    wire [15:0] r1data, r2data, regfile_in;

    lc4_regfile regfile(clk, gwe, rst,
                         r1sel, r1data, r2sel, r2data,
                         regfile_reg, regfile_in, regfile_we);
                         
                         

    // *********************************************************************************
    // FETCH
    // *********************************************************************************

    // PC
    wire [15:0]  pc;
    wire [15:0]  next_pc;
    wire [15:0]  pc_plus_one;
    
    wire [15:0] actual_next_pc;
    wire [15:0] target;
    wire [15:0] pc_in;
    
    Nbit_mux2to1 #(16) actual_next_pc_mux (.out(actual_next_pc), .a(target), .b(next_pc), .sel(ne_out));
   assign pc_in = (stall_out) ? pc : actual_next_pc;
    Nbit_reg #(16, 16'h8200) pc_reg (.in(pc_in), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    assign imem_addr = pc;
    
    // PC + 1
    assign pc_plus_one = pc + 1'b1;
    // Branch Predictor
    branch_predictor branch_predictor (pc, target);
    
    // *********************************************************************************
    // D-LATCH
    // *********************************************************************************
    
    wire [1:0] f_stall;
    wire [15:0] f_pc_plus_one, f_imem_out, f_dmem_addr, f_regfile_in;
    wire [2:0]  f_regfile_reg, f_nzp_in;
    wire        f_regfile_we, f_nzp_we, f_dmem_we;

    control_latch f_controls (.clk(clk), .gwe(gwe), .rst(rst),
                                   .i_stall(2'b0), .i_pc_plus_one(pc_plus_one), .i_imem_out(f_flush_out), .i_regfile_we(1'b0), .i_regfile_reg(3'b0), .i_regfile_in(16'b0), .i_nzp_we(1'b0), .i_nzp_in(3'b0), .i_dmem_we(1'b0), .i_dmem_addr(16'b0),
                            .o_stall(f_stall), .o_pc_plus_one(f_pc_plus_one), .o_imem_out(f_imem_out), .o_regfile_we(f_regfile_we), .o_regfile_reg(f_regfile_reg), .o_regfile_in(f_regfile_in), .o_nzp_we(f_nzp_we), .o_nzp_in(f_nzp_in), .o_dmem_we(f_dmem_we), .o_dmem_addr(f_dmem_addr));
    wire [15:0] f_tg_out;
    Nbit_reg #(16) f_tg (.in(target), .out(f_tg_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    // *********************************************************************************
    // DECODE
    // *********************************************************************************
   wire [4:0] d_opcode = f_imem_out[15:12];
    
    wire [2:0] r1sel_insn_8to6 = 2'b00;
    wire [2:0] r1sel_insn_11to9 = 2'b01;
    wire [2:0] r1sel_b111 = 2'b10;
    
    assign r1sel_sel = //arithmetic
                    (d_opcode == 4'b0001) ? r1sel_insn_8to6 :
                         
                    //compare
                    (d_opcode == 4'b0010) ? r1sel_insn_11to9 :
                     
                    //jump
                    (d_opcode == 4'b0100) ? r1sel_insn_8to6 :
                         
                    //boolean
                    (d_opcode == 4'b0101) ? r1sel_insn_8to6 :
 
                    //load
                    (d_opcode == 4'b0110) ? r1sel_insn_8to6 :
                     
                    //store
                    (d_opcode == 4'b0111) ? r1sel_insn_8to6 :
                     
                          //RTI
                          (d_opcode == 4'b1000) ? 3'b111 :
                         
                    //shift
                    (d_opcode == 4'b1010) ? r1sel_insn_8to6 :
 
                    //Jump
                    (d_opcode == 4'b1100) ? r1sel_insn_8to6 :
                         
                          //Hiconst
                          (d_opcode == 4'b1101) ? r1sel_insn_11to9 :

                          //Trap
                          (d_opcode == 4'b1111) ? r1sel_b111 : 3'b000;
                                         
    
    wire r2sel_insn_2to0 = 1'b0;
    wire r2sel_insn_11to9 = 1'b1;
    
    //only 11-9 for store
    assign r2sel_sel = (d_opcode == 4'b0111) ? r2sel_insn_11to9 : r2sel_insn_2to0;


    // r1sel, r2sel
    Nbit_mux3to1 #(3) r1sel_mux(r1sel_sel, f_imem_out[8:6], f_imem_out[11:9], 3'b111, r1sel);
    Nbit_mux2to1 #(3) r2sel_mux(r2sel_sel, f_imem_out[2:0], f_imem_out[11:9], r2sel);
    
    
    // *********************************************************************************
    // X-LATCH
    // *********************************************************************************
    wire [15:0] d_a_out, d_b_out;
    Nbit_reg #(16) D_a (.in(r1data), .out(d_a_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16) D_b (.in(r2data), .out(d_b_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    wire [1:0] d_stall;
    wire [15:0] d_pc_plus_one, d_imem_out, d_dmem_addr, d_regfile_in;
    wire [2:0]  d_regfile_reg, d_nzp_in;
    wire        d_regfile_we, d_nzp_we, d_dmem_we;
    
    control_latch d_controls (.clk(clk), .gwe(gwe), .rst(rst),
                                   .i_stall(f_stall), .i_pc_plus_one(f_pc_plus_one), .i_imem_out(f_imem_out), .i_regfile_we(f_regfile_we), .i_regfile_reg(f_regfile_reg), .i_regfile_in(f_regfile_in), .i_nzp_we(f_nzp_we), .i_nzp_in(f_nzp_in), .i_dmem_we(f_dmem_we), .i_dmem_addr(f_dmem_addr),
                            .o_stall(d_stall), .o_pc_plus_one(d_pc_plus_one), .o_imem_out(d_imem_out), .o_regfile_we(d_regfile_we), .o_regfile_reg(d_regfile_reg), .o_regfile_in(d_regfile_in), .o_nzp_we(d_nzp_we), .o_nzp_in(d_nzp_in), .o_dmem_we(d_dmem_we), .o_dmem_addr(d_dmem_addr));

    wire [15:0] d_tg_out;
    Nbit_reg #(16) d_tg (.in(f_tg_out), .out(d_tg_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    // *********************************************************************************
    // XECUTE
    // *********************************************************************************
    
    
    wire [15:0] alu_out, pc_or_alu_out;
    
    wire dmem_addr_sel_pc = 1'b0;
    wire dmem_addr_sel_alu_out = 1'b1;
    wire pc_or_alu_out_sel;
    wire [3:0] x_opcode = d_imem_out[15:12];
    
    //select pc (0) if instruction is a jump or trap (writing pc to R7)
    //otherwise, select alu
    assign pc_or_alu_out_sel = ((x_opcode == 4'b0100) || (x_opcode == 4'b1111)) ? dmem_addr_sel_pc : dmem_addr_sel_alu_out;
    //alu
    lc4_alu alu(d_imem_out, d_pc_plus_one-16'b1, alu_in_a_mux_out, alu_in_b_mux_out, alu_out); //check d_pc_out!!!! TODO - done for now
    Nbit_mux2to1 #(16) dmem_addr_mux(pc_or_alu_out_sel, d_pc_plus_one, alu_out, pc_or_alu_out); //TODO plus or not?

    
    // *********************************************************************************
    // M-LATCH
    // *********************************************************************************
    wire [15:0] x_o_out, x_b_out;
    Nbit_reg #(16) X_o (.in(pc_or_alu_out), .out(x_o_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16) X_b (.in(d_b_out), .out(x_b_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
    wire [1:0] x_stall;
    wire [15:0] x_pc_plus_one, x_imem_out, x_dmem_addr, x_regfile_in;
    wire [2:0]  x_regfile_reg, x_nzp_in;
    wire        x_regfile_we, x_nzp_we, x_dmem_we;
    
    control_latch x_controls (.clk(clk), .gwe(gwe), .rst(rst),
                                   .i_stall(d_stall), .i_pc_plus_one(d_pc_plus_one), .i_imem_out(d_imem_out), .i_regfile_we(d_regfile_we), .i_regfile_reg(d_regfile_reg), .i_regfile_in(d_regfile_in), .i_nzp_we(d_nzp_we), .i_nzp_in(d_nzp_in), .i_dmem_we(d_dmem_we), .i_dmem_addr(pc_or_alu_out),
                            .o_stall(x_stall), .o_pc_plus_one(x_pc_plus_one), .o_imem_out(x_imem_out), .o_regfile_we(x_regfile_we), .o_regfile_reg(x_regfile_reg), .o_regfile_in(x_regfile_in), .o_nzp_we(x_nzp_we), .o_nzp_in(x_nzp_in), .o_dmem_we(x_dmem_we), .o_dmem_addr(x_dmem_addr));
    
    
    // *********************************************************************************
    // MEMORY
    // *********************************************************************************
    assign dmem_we = (x_imem_out[15:12] == 4'b0111);

    assign dmem_addr =  (x_imem_out[15:12] == 4'b0110) ? x_o_out :
                           (x_imem_out[15:12] == 4'b0111) ? x_o_out :
                           16'd0;
                           
   //assign dmem_addr = pc_or_alu_out;
   assign dmem_in = wm_mux_out;
    
    // *********************************************************************************
    // W-LATCH
    // *********************************************************************************
    wire [15:0] m_o_out, m_d_out, temp;
    Nbit_reg #(16) M_o (.in(x_o_out), .out(m_o_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16) M_temp (.in(16'b1), .out(temp), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16) M_d (.in(dmem_out), .out(m_d_out), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    //assign m_o_out = x_o_out;

    wire [1:0] m_stall;
    wire [15:0] m_pc_plus_one, m_imem_out, m_dmem_addr, m_regfile_in;
   wire [2:0]  m_regfile_reg, m_nzp_in;
   wire         m_regfile_we, m_nzp_we, m_dmem_we;
    
   control_latch m_controls (.clk(clk), .gwe(gwe), .rst(rst),
                                   .i_stall(x_stall), .i_pc_plus_one(x_pc_plus_one), .i_imem_out(x_imem_out), .i_regfile_we(x_regfile_we), .i_regfile_reg(x_regfile_reg), .i_regfile_in(x_regfile_in), .i_nzp_we(x_nzp_we), .i_nzp_in(x_nzp_in), .i_dmem_we(x_dmem_we), .i_dmem_addr(dmem_addr),
                            .o_stall(m_stall), .o_pc_plus_one(m_pc_plus_one), .o_imem_out(m_imem_out), .o_regfile_we(m_regfile_we), .o_regfile_reg(m_regfile_reg), .o_regfile_in(m_regfile_in), .o_nzp_we(m_nzp_we), .o_nzp_in(m_nzp_in), .o_dmem_we(m_dmem_we), .o_dmem_addr(m_dmem_addr));
    // *********************************************************************************
    // WRITEBACK
    // *********************************************************************************
    
    wire regfile_reg_insn_11to9 = 1'b0;
    wire regfile_reg_111 = 1'b1;
    wire [3:0] w_opcode = m_imem_out[15:12];
    
    assign nzp_we = (w_opcode !== 4'b0000) && (w_opcode !== 4'b1100) && (w_opcode !== 4'b0111) && (w_opcode !== 4'b1000);
    
    assign regfile_reg_sel =     //jump
                        (w_opcode == 4'b0100) ? regfile_reg_111 :
                             //rti
                             (w_opcode == 4'b1000) ? regfile_reg_111 :
                             //trap
                             (w_opcode == 4'b1111) ? regfile_reg_111 :
    
                             regfile_reg_insn_11to9;    
                             
    assign regfile_we =
                                     //branch
                                     (w_opcode == 4'b0000) ? 1'b0 :
                                     //compare
                                     (w_opcode == 4'b0010) ? 1'b0 :
                                     //store
                                     (w_opcode == 4'b0111) ? 1'b0 :
                                     //RTI
                                     (w_opcode == 4'b1000) ? 1'b0 :
                                     //jump
                                     (w_opcode == 4'b1100) ? 1'b0 :
                                     1'b1;
    
                             
    // regfile_reg
    Nbit_mux2to1 #(3) regfile_reg_mux(regfile_reg_sel, m_imem_out[11:9], 3'b111, regfile_reg);
    
    
    wire [2:0] nzp_in, nzp_out;
    
    assign regfile_in_sel = (w_opcode == 4'b0110 /* LOAD */);
    Nbit_mux2to1 #(16)  regfile_in_mux(regfile_in_sel, m_o_out, m_d_out, regfile_in);
    
    //nzp
    nzp_unit nzp(regfile_in, nzp_in);
    Nbit_reg #(3) nzp_reg(nzp_in, nzp_out, clk, nzp_we, gwe, rst);
    
    //branch
    branchunit branch(m_imem_out, nzp_out, pc_next_sel);
    Nbit_mux2to1 #(16) next_pc_mux(pc_next_sel, m_pc_plus_one, m_o_out, next_pc);
    
    wire [15:0] dmem_value =     
                         //load
                         (m_imem_out[15:12] == 4'b0110) ? m_d_out :
                         //store
                         (m_imem_out[15:12] == 4'b0111) ? m_d_out :
                         //other
                         (16'h0000);



    // *********************************************************************************
    // BYPASSING
    // *********************************************************************************
    
    // Execute
    alu_in_a alu_in_a (.d_imem_out(d_imem_out), .x_imem_out(x_imem_out), .m_imem_out(m_imem_out), .out(alu_in_a_mux_sel));
    Nbit_mux3to1 #(16) alu_in_a_mux (.out(alu_in_a_mux_out), .a(x_o_out), .b(regfile_in), .c(d_a_out), .sel(alu_in_a_mux_sel));

    alu_in_b alu_in_b (.d_imem_out(d_imem_out), .x_imem_out(x_imem_out), .m_imem_out(m_imem_out), .out(alu_in_b_mux_sel));
    Nbit_mux3to1 #(16) alu_in_b_mux (.out(alu_in_b_mux_out), .a(x_o_out), .b(regfile_in), .c(d_b_out), .sel(alu_in_b_mux_sel));
    
    // Memory
    wm wm (.x_imem_out(x_imem_out), .m_imem_out(m_imem_out), .out(wm_mux_sel));
    Nbit_mux2to1 #(16) dmem_in_mux (.out(wm_mux_out), .a(x_b_out), .b(regfile_in), .sel(wm_mux_sel));
    
    
    
    // *********************************************************************************
    // STALL
    // *********************************************************************************
    
    stall stall (.f_imem_out(f_imem_out), .d_imem_out(d_imem_out), .x_imem_out(x_imem_out), .stall_out(stall_out));
    
    // F flush
    Nbit_mux2to1 #(16) f_flush_mux(.out(f_flush_out), .a(imem_out), .b(`NOP), .sel(ne_out));
    
    // D flush
    wire d_flush_sel = stall_out | ne_out;
    Nbit_mux2to1 #(16) d_flush_mux (.out(d_imem_out), .a(f_imem_out), .b(`NOP), .sel(d_flush_sel));
    
    // *********************************************************************************
    // ne_unit
    // *********************************************************************************
    
    ne_unit ne_unit (.a(next_pc), .b(d_tg_out), .ne_out(ne_out));
    
    
    
    











  assign test_stall = m_stall; // No stalling to report for single-cycle design
  assign test_pc = m_pc_plus_one-16'b1;         // Testbench: program counter
  assign test_insn = m_imem_out;        // Testbench: instruction bits
  assign test_regfile_we = regfile_we;  // Testbench: register file write enable
  assign test_regfile_reg = regfile_reg; // Testbench: which register to write in the register file
  assign test_regfile_in = regfile_in;  // Testbench: value to write into the register file
  assign test_nzp_we = nzp_we;  // Testbench: NZP condition codes write enable
  assign test_nzp_in = nzp_in;  // Testbench: value to write to NZP bits
  assign test_dmem_we = m_dmem_we;      // Testbench: data memory write enable
  assign test_dmem_addr = m_dmem_addr;  // Testbench: address to read/write memory
  assign test_dmem_value = dmem_value;  // Testbench: value read/writen from/to memory

  // For in-simulator debugging, you can use code such as the code
  // below to display the value of signals at each clock cycle.
`define DEBUG
`ifdef DEBUG
  always @(posedge gwe) begin
    $display(" ");
$display(" ");

$display("time: %d", $time);

$display("### FETCH ###");
$display("imem_addr: %h, target: %b, actual_next_pc: %b", imem_addr, target, actual_next_pc);
$display("imem_out: %b, pc_plus_one: %h", imem_out, pc_plus_one);

$display("### D-LATCH ###");
$display("f_imem_out: %b, f_pc_plus_one: %h", f_imem_out, f_pc_plus_one);
$display("f_regfile_in: %b", f_regfile_in);

$display("### DECODE ###");
$display("d_opcode: %b", d_opcode);

$display("### X-LATCH ###");
$display("d_imem_out: %b, d_pc_plus_one: %h", d_imem_out, d_pc_plus_one);
$display("d_a_out: %b, d_b_out: %b", d_a_out, d_b_out);
$display("d_regfile_in: %b", d_regfile_in);

$display("### XECUTE ###");
$display("x_opcode: %b, alu_out: %b, pc_or_alu_out: %b, pc_or_alu_out_sel: %b", x_opcode, alu_out, pc_or_alu_out, pc_or_alu_out_sel);

$display("$$$ BYPASSING $$$");
$display("alu_in_a_mux_sel: %b, alu_in_a_mux_out: %b, alu_in_b_mux_sel: %b, alu_in_b_mux_out: %b", alu_in_a_mux_sel, alu_in_a_mux_out, alu_in_b_mux_sel, alu_in_b_mux_out);
$display("alu_in_a_mux_out: %b, x_o_out: %b, regfile_in: %b, d_a_out: %b, alu_in_a_mux_sel: %b", alu_in_a_mux_out, x_o_out, regfile_in, d_a_out, alu_in_a_mux_sel);
$display("alu_in_b_mux_out: %b, x_o_out: %b, regfile_in: %b, d_b_out: %b, alu_in_b_mux_sel: %b", alu_in_b_mux_out, x_o_out, regfile_in, d_b_out, alu_in_b_mux_sel);

$display("### M-LATCH ###");
$display("x_imem_out: %b, x_pc_plus_one: %h", x_imem_out, x_pc_plus_one);
$display("x_o_out: %b, x_b_out: %b", x_o_out, x_b_out);
$display("x_regfile_in: %b", x_regfile_in);

$display("### MEMORY ###");
$display("dmem_we: %b, dmem_addr: %b, dmem_in: %b", dmem_we, dmem_addr, dmem_in);

$display("### W-LATCH ###");
$display("m_imem_out: %b, m_pc_plus_one: %h", m_imem_out, m_pc_plus_one);
$display("regfile_in_sel: %b, m_o_out: %b, m_d_out: %b", regfile_in_sel, m_o_out, m_d_out);
$display("m_regfile_in: %b", m_regfile_in);

$display("### WRITEBACK ###");
$display("w_opcode: %b, regfile_we: %b, regfile_in: %b", w_opcode, regfile_we, regfile_in);

$display("### REGISTER ###");
$display("r1sel: %b, r1data: %h, r2sel: %b, r2data: %h", r1sel, r1data, r2sel, r2data);
$display("### STALL ###");
$display("ne_out: %b, stall_out: %b, d_flush_sel: b", ne_out, stall_out, d_flush_sel);
  end
`endif


   // For on-board debugging, the LEDs and segment-segment display can
   // be configured to display useful information.  The below code
   // assigns the four hex digits of the seven-segment display to either
   // the PC or instruction, based on how the switches are set.
   
/*   assign seven_segment_data = (switch_data[6:0] == 7'd0) ? F_pc :
                            (switch_data[6:0] == 7'd1) ? imem_out :
                            (switch_data[6:0] == 7'd2) ? dmem_addr :
                            (switch_data[6:0] == 7'd3) ? dmem_out :
                            (switch_data[6:0] == 7'd4) ? dmem_in :
                            else 16'hDEAD;
   assign led_data = switch_data;
   */
endmodule

