/*
	Copyright (c) 2004 Pablo Bleyer Kocik.

    Modified for EE573 Fall 2005 by John Lynch, OGI/OHSU

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice, this
	list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.

	3. The name of the author may not be used to endorse or promote products
	derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
	EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
	IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.

    Behavioral KCPSMX instruction decode unit.

	Acknowledgment:  SystemVerilog version created and tested by SethR, MilesS,
	ShubhankaSPM, and Supraj Vastrad for ECE 571 Winter 2020 final project
*/

import kcpsmx3_inc::*;

module kcpsmx_idu (
    instruction,
    operation,
    shift_operation,
    shift_direction,
    shift_constant,
    operand_selection,
    x_address,
    y_address,
    implied_value,
    port_address,
    scratch_address,
    code_address,
    conditional,
    condition_flags,
    interrupt_enable
);

  input instr_t instruction;  ///< Instruction.
  output opcode_t operation;  ///< Main operation.
  output shift_op_t shift_operation;  ///< Rotate/shift operation.
  output logic shift_direction;  ///< Rotate/shift
  ///left(0)/right(1).
  output logic shift_constant;  ///< Shift constant value.
  output logic operand_selection;  ///< Operand selection
  ///(kps(0)/y(1)).
  output logic [REGISTER_DEPTH-1:0] x_address, y_address;  ///< Operation x source/target,
  ///y source.
  output logic [OPERAND_WIDTH-1:0] implied_value;  ///< Operand constant source.
  output logic [PORT_DEPTH-1:0] port_address;  ///< Port address.
  output logic [SCRATCH_DEPTH-1:0] scratch_address;  ///< Scratchpad address.
  output logic [CODE_DEPTH-1:0] code_address;  ///< Program address.
  output logic conditional;  ///< Conditional operation
  ///(unconditional(0)/conditional
  ///(1)).
  output cond_flag_t condition_flags;  ///< Condition flags on zero
  ///and carry.
  output logic interrupt_enable;  ///< Interrupt
  ///disable(0)/enable(1).

  assign operation = instruction.operation;
  assign x_address = instruction.instr_type.reg_reg.x_addr;
  assign y_address = instruction.instr_type.reg_reg.y_addr;
  assign operand_selection = instruction.op_cond_sel;
  assign interrupt_enable = instruction.instr_type.interrupt.en;
  assign scratch_address = instruction.instr_type.scratch.scratch_addr;
  assign shift_direction = instruction.instr_type.shift.dir;
  assign shift_operation = instruction.instr_type.shift.op;
  assign shift_constant = instruction.instr_type.shift.constant;
  assign conditional = instruction.op_cond_sel;
  assign condition_flags = instruction.instr_type.jump.flags;
  assign implied_value = instruction.instr_type.reg_const.constant;
  assign port_address = instruction.instr_type.port.port_addr;
  assign code_address = instruction.instr_type.jump.code_addr;

  //Concurrent IDU assertions -- put these in the rojo module to have access to a clock.

endmodule
