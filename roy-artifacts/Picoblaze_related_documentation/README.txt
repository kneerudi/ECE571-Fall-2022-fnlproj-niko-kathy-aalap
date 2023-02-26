README.txt
README file for the Picoblaze-related documentation folder
for the ECE 571 final project.
Created by Roy Kravitz (roy.kravitz@pdx.edu) on 15-Nov-2022
-----------------------------------------------------------
This folder includes these documents:
o KCPSM3_Manual.pdf -the documentation for the original Picoblaze.  Sort of in the form
of a powerpoint presentation.  There is a fair amount of material that is specific to the
Xilinx FPGA implementation which can be skipped for this project, but it is the definitive
document describing the Picoblaze ISA (Instruction Set Architecture)

o pacoblaze_by_Pablo_Bleyer_Kocik.pdf - this is documentation on the RTL implementation
of the Picoblaze ISA by Pablo Bleyer Kocik.  The Pipelined Picoblaze is based on Pacoblaze.
There is a (very) short section on how to use KCASM.jar.  This is a Java=based assembler for Picoblaze that accepts the same syntax as the KCPSM3.exe assembler.  There is no C compiler, Python interpreter, or whatever.  Picoblaze is a simple 8-bit microcontroller that you program in assembly language.  I included KCASM.jar because KCPSM3.exe only runs on Windows and I'd hazard a guess and say that some of your PC's are not Windows-based.  You need to have a Jave runtime system on your PC.  The command for running a .jar file is java -jar KCASM.jar.  Refer to the documentation to see the options.

o picoblaze_by_KenC.pdf.  This is an interesting (to me, at least) discussion of the thought that Ken put into designing the Picoblaze ISA and implmementing it for an FPGA.

o Picoblaze User Guide.pdf - This is the Xilinx documentation on the Picoblaze. There is some duplication between KCPSM3_Manual.pdf.

o Pipelined Picoblaze (Rojoblaze) Block diagram_nofwd_nohaz.pdf - Block diagram of the
Pipelined Picoblaze implementation that does not include hazard detection.

o Pipelined Picoblaze (RojoBlaze) Block Diagram _fwd_haz.pdf - Block diagram of the Pipelined Picoblaze implementation that includes hazard detection.

