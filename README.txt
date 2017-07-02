This project is not meant to be maintained

------

This is the source files for a Challenge to create and simulate a SUBLEQ machine in two hours (succeeded at twelfth hour). I failed to actually display results in SSDs, so you need additional fixes if you want to synthesize it. Bootloader, however, should work.


------

Quick intro:

The instruction:

SUBLEQ a, b, c

is equivalent to pseudocode:

*b = *b - *(b + a<<2)
if (*b <= 0) goto pc + 4 + (c << 2)

Here, b is 16-bit, a and c are 8-bit.

This is the instruction format:
| 16-bit B | 8-bit A | 8-bit C |

Memory maps can be read in MMU.vhd and SFR.vhd. I found out the problem in memory mapping _after_ I finished simulating, and figured that 32 bits are not enough. So I improvised SFR by overlapping memory addresses. So, anything written in SFR will also be in main memory.

board_top.vhd is the synthesize top module
cpu_top_tb.vhd is the simulation top module.