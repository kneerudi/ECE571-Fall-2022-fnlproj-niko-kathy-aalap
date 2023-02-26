/*
tb_testprogs.sv - A short testbench to drive a RojoBlaze and look at the results in the scratchpad.

Author: Seth Rohrbach
Modified: March 17, 2020

----------
Description:

This testbench just waits for the last scratch pad ram location to be written to,
then prints out the values in all the scratch pads.
Designed simply to see the results of a number of short test programs for the RojoBlaze.

Acknowledgment:  SystemVerilog version created and tested by SethR, MilesS,
ShubhankaSPM, and Supraj Vastrad for ECE 571 Winter 2020 final project

NOTE: (RK) I included 2 of the teams test programs as examples.

*/


import kcpsmx3_inc::*;


module alt_rojo_tb;

  parameter tck = 10, program_size = 1024;

  string memfile[] = '{
      // ADD ADDITIONAL TESTS HERE
      "alu_test.mem"
  };

  reg clk, rst;  // clock, reset
  reg [OPERAND_WIDTH-1:0] prt[0:PORT_SIZE];
  wire [OPERAND_WIDTH-1:0] pa, po;  // port id, port out
  wire rd, wr;  // read strobe, write strobe
  wire ir, ia;  // interrupt req, interrupt ack
  wire [OPERAND_WIDTH-1:0] pi;  // port in
  wire [1:152] opcode;  // disassembler output
  logic [7:0] local_mem[0:63];  //Local mem for testing use


  kcpsmx dut (
      .clk(clk),
      .reset(rst),
      .port_id(pa),
      .read_strobe(rd),
      .write_strobe(wr),
      .in_port(pi),
      .out_port(po),
      .interrupt(ir),
      .interrupt_ack(ia)
  );

  disassembler dis (
      .instruction  (dut.instruction),
      .kcpsm3_opcode(opcode)
  );

  integer i;  // loop index
  initial begin
    $monitor(
        "[T: %0d ] || OP: %0s || ZERO: %0d || CARRY: %0d || SHIFT_BIT: %0d || SHIFT_OP: %0s || REG_DATA: %0h || ADD_SUB: %h || OP1: %h || OP2: %h || SCR_WR_EN: %b || RG_WR_EN: %b || WR_SRB: %b || ZR_CR_WR_EN: %h ",
        $time, opcode, dut.zero, dut.alu.carry_out, dut.alu.shift_bit,
        dut.alu.shift_operation.name(), dut.alu.result, dut.alu.addsub_result[7:0],
        dut.alu.operand_a, dut.alu.operand_b, dut.scratch_write_enable, dut.register_write_enable,
        dut.write_strobe, dut.zero_carry_write_enable, dut.read_strobe);
    clk = 0;
    rst = 1;
    repeat (5) @(negedge clk);
    rst = 0;  // free processor
    for (i = 0; i < 64; i = i + 1) begin  //initialize local mem
      local_mem[i] = 8'b0;
    end
  end

  always #(tck / 2) clk = ~clk;

  always @(opcode) begin
    $display(
        "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
  end
  /* Assertions */

  //boundary check - when write enable is on then check the address is within 6 bit boundary
  always @(posedge clk) begin
    assert property(dut.scratch_write_enable |-> (dut.scratch_address >= 6'd0 && dut.scratch_address <=6'd63))
    else
      $display("\n\nError scratchpad address boundary issue address = %d\n\n", dut.scratch_address);

  end

  always @(posedge clk) begin
    assert property(dut.instruction[17:13] !== 5'h01 &&
                    dut.instruction[17:13] !== 5'h04 &&
                    dut.instruction[17:13] !== 5'h08 &&
                    dut.instruction[17:13] !== 5'h0b &&
                    dut.instruction[17:13] !== 5'h11 &&
                    dut.instruction[17:13] !== 5'h12 &&
                    dut.instruction[17:13] !== 5'h13 &&
                    dut.instruction[17:13] !== 5'h14 &&
                    dut.instruction[17:13] !== 5'h19 &&
                    dut.instruction[17:13] !== 5'h1b &&
                    dut.instruction[17:13] !== 5'h1d &&
                    dut.instruction[17:13] !== 5'h1f)
    else
      $display(
          "\n\nError instruction[17:13] = %x, should be inside opcode_t\n\n", dut.instruction[17:13]
      );
  end


  // PC should jump to the target address
  property pc_jump;
    @(posedge clk) disable iff (rst) (((dut.instruction[17:13] === 5'h1a) || (dut.instruction[17:13] === 5'h18)) && (dut.enable_PC === 1'b1) && (dut.conditional_match)) |=> ((dut.program_counter) === $past(
        dut.idu_code_address
    ))
  endproperty
  assert property (pc_jump)
  else
    $display(
        "\n\n Error OP: %s , PC is [%d], address is [%d] \n\n",
        $past(
            opcode
        ),
        (dut.program_counter),
        $past(
            dut.idu_code_address, 1
        )
    );

  // to check if the opcode matches with idu_operation
  property opcode_check;
    @(posedge clk) disable iff (rst) (dut.instruction[17:13] === dut.idu_operation)
  endproperty
  assert property (opcode_check)
  else
    $display(
        "\n\n Error OP: %s , inst is [%d] operation is [%d] \n\n",
        $past(
            opcode
        ),
        $past(
            dut.instruction[17:13]
        ),
        $past(
            dut.idu_operation
        )
    );

  // to check if PC is zero when reset is asserted
  property reset_check;
    @(posedge clk) ((rst) |=> ##2 (dut.program_counter) === RESET_VECTOR)
  endproperty
  assert property (reset_check)
  else
    $display(
        "\n\n Error: PC is [%d] RESET_VECTOR is [%d] \n\n",
        $past(
            dut.program_counter
        ),
        (RESET_VECTOR)
    );

  //check if PC rollover
  property rollover_check;
    @(posedge clk) disable iff (rst) ((dut.instruction[17:13] === 5'h1a) && (dut.program_counter === 10'hFFFFFFFF)
    |-> ##2 (dut.program_counter === 10'h0))
  endproperty
  assert property (rollover_check)
  else
    $display(
        "\n\n Error: PC is [%d] Instruction is [%s] \n\n",
        dut.program_counter,
        dut.instruction[17:13]
    );

  /* If ADD result is 0 then zero flag is asserted */
  //---------------------------------------------------------------------------
  property zero_flag;
    @(clk) disable iff (rst) ((dut.instruction[17:13] === 5'h0c) && (dut.alu.result === 2'h0)) |-> (##[1:5] dut.zero)
  endproperty
  assert property (zero_flag)
  else
    $display(
        "\n\n ALU Result was 0; Error OP: %s , Zero flag was not set [ %h ], FAIL \n\n",
        opcode,
        dut.zero
    );
  //---------------------------------------------------------------------------
  /* If ADD result is 0 then carry flag is asserted */
  property carry_flag;
    @(posedge clk) disable iff (rst) ((dut.instruction[17:13] === 5'h0c) && (dut.alu.result > 2'hff)) |-> (##1 dut.alu.carry_out);
  endproperty
  assert property (carry_flag)
  else
    $display(
        "\n\n ALU was Result > FF ; Error OP: %s , ALU Carry Out was not set [ %h ], FAIL \n\n",
        opcode,
        dut.alu.carry_out
    );
  //---------------------------------------------------------------------------
  /* If ADDCY result is 0 then carry flag is asserted */
  property addcy_carry_flag;
    @(posedge clk) disable iff (rst) ((dut.instruction[17:13] === 5'h0d) && (dut.alu.result > 2'hff)) |-> (##1 dut.alu.carry_out);
  endproperty
  assert property (addcy_carry_flag)
  else
    $display(
        "\n\n ALU Result > FF; Error OP: %s , ALU Carry Out was not set [ %h ], FAIL \n\n",
        opcode,
        dut.alu.carry_out
    );
  //---------------------------------------------------------------------------
  /* If SUB 0 minus 0 will set the Zero flag */
  property sub_zero_flag;
    @(posedge clk) disable iff (rst) ((dut.instruction[17:13] === 5'h0e) && (dut.alu.result < 2'h0)) |-> (##1 dut.zero);
  endproperty
  assert property (sub_zero_flag)
  else
    $display(
        "\n\n ALU Result < 0; Error OP: %s , Zero Flag was not set [ %h ], FAIL \n\n",
        opcode,
        dut.zero
    );
  //---------------------------------------------------------------------------
  /* If SUB result is negative set carry */
  property sub_carry_flag;
    @(posedge clk) disable iff (rst) ((dut.instruction[17:13] === 5'h0e) && (dut.alu.result < 2'h0)) |-> (##1 dut.alu.carry_out);
  endproperty
  assert property (sub_carry_flag)
  else
    $display(
        "\n\n ALU Result < 0; Error OP: %s , ALU Carry Out was not set [ %h ], FAIL \n\n",
        opcode,
        dut.alu.carry_out
    );
  //---------------------------------------------------------------------------
  /* If SUBCY result is negative set carry */
  property subcy_carry_flag;
    @(posedge clk) disable iff (rst) ((dut.instruction[17:13] === 5'h0f) && (dut.alu.result < 2'h0)) |-> (##1 dut.alu.carry_out);
  endproperty
  assert property (subcy_carry_flag)
  else
    $display(
        "\n\n Subcy ALU Result < 0; Error OP: %s , Zero Flag was not set [ %h ], FAIL \n\n",
        opcode,
        dut.alu.carry_out
    );
  //---------------------------------------------------------------------------
  /* If we JUMP and ZERO flag is set, if the next instruction is AND sX, sX */
  /* Carry bit should be cleared  with AND sX, sX */
  //---------------------------------------------------------------------------
  property clear_carry_flag;
    @(posedge clk) disable iff (rst) ((dut.instruction[17:13] === 5'h05) && (dut.instruction[11:8] === dut.instruction[7:4]) && (dut.alu.carry_out ) ) |=> (##1 (dut.alu.carry_out === 0));
  endproperty
  assert property (clear_carry_flag)
  else
    $display(
        "\n\n AND sX, sX should clear Carry Flag; Error OP: %s , Carry Flag should has de-asserted but it is [ %h ], FAIL \n\n",
        opcode,
        dut.alu.carry_out
    );

  //---------------------------------------------------------------------------
  /* If we COMPARE 0,0 we should NOT set the Carry Flag */
  //---------------------------------------------------------------------------
  property set_carry_flag;
    @(posedge clk) disable iff (rst) ((dut.instruction[17:13] === 5'h0a) && (dut.instruction[11:8] === dut.instruction[7:4]) ) |=> (##1 (dut.alu.carry_out === 0) && dut.zero);
  endproperty
  assert property (set_carry_flag)
  else
    $display(
        "\n\n COMPARE sX, sX should set Zero flag but not Carry Flag; Error OP: %s , Carry Flag should has de-asserted but it is [ %h ], FAIL \n\n",
        opcode,
        dut.alu.carry_out
    );

  //---------------------------------------------------------------------------
  /* When shiftbit then op1 + op2 == result */
  //---------------------------------------------------------------------------

  property test_ADD_SUB;
    @(negedge clk) disable iff (rst)  ( ((dut.alu.operand_a !== 2'hx) && (dut.alu.operand_a)) && ( (dut.alu.operand_b !== 2'hx) && dut.alu.operand_b)

    |-> (((dut.alu.operand_a + dut.alu.operand_b ) === dut.alu.addsub_result[7:0]) || (dut.alu.operand_a - dut.alu.operand_b ) === dut.alu.addsub_result[7:0]) );
  endproperty
  assert property (test_ADD_SUB)
  else
    $display(
        "\n\n Error: OP1 %h +/- OP2 %h should NOT equal %h, you should ignore the error if OP1 == FF && OP2 == 1 \n\n",
        dut.alu.operand_a,
        dut.alu.operand_b,
        dut.alu.addsub_result[7:0]
    );


  /* Since we decrement by 1 to write to scrachpad OP1 and Result from previous OP should be at most 1 less 8 */
  property test_STORE;
    @(negedge clk) disable iff (rst) ((dut.instruction[17:13] === 5'h17) && (dut.instruction[11:8] === 2'h2 && dut.instruction[7:4] )
   |-> dut.alu.operand_a === (dut.alu.result + 2'h01)) ;
  endproperty
  assert property (test_STORE)
  else
    $display(
        "\n\n Error: STORE after SUB S2,01 operand_a [OP1] is %h the next result should be  %h , but is %h, FAIL \n\n",
        dut.alu.operand_a,
        (dut.alu.operand_a - 2'h01),
        dut.alu.result

    );


  always @(posedge clk) begin
    foreach (memfile[test]) begin
      $display(
          "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
      $display("Running test file %s", memfile[test]);
      $display(
          "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
      rst = 1;
      @(negedge clk);
      $readmemh(memfile[test], dut.rom.ram);
      repeat (4) @(negedge clk);
      rst = 0;
      #6000
        if (dut.scratch.spr[63]) begin
          repeat (40) @(negedge clk);

          $write("Test Program concluded.\n");
          $display(
              "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
          $write("Scratch Pad Mem Values:\n");
          $display(
              "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
          for (i = 0; i < 64; i = i + 1) begin
            $write("RAM[%0d] = %2h\n", i, dut.scratch.spr[i]);
            $display(
                "-------------------------------------------------------------------------------------------------------");
          end
          $display(
              "===================================================================================================");
        end else
          $display(
              "\n \n ---------------------------------------- \n FAILED To Write to Scratchpad \n\n"
          );
    end
    $stop;
  end


endmodule
