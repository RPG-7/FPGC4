# Progress
Here I keep a simple list of my latest progress and a simple TODO list

## Progress log
- Added library support in assembler
- Added sprites
- Rewrote FSX2 for CRT display
- Finally updated the documentation a bit
- Created and ordered PCB
- PCB received, assembled and tested
- Updated documentation quite a bit
- Added 4 extension interrupts
- Changes PS/2 controller to only check for scan codes and send an interrupt
- Reimplemented programmable timer

## Future plans
These are kinda ordered based on priority

- Improve and write more libraries
- Improve hardware stack (size, check usage, get pointer, etc.)
- Enable second SPI and UART port
- Write a platformer game
- Create a pattern and palette table generator
- Add logo to boot screen animation in bootloader
- Add a custom syntax highlighting for the assembly language.
- Create webpage on b4rt.nl with documentation, since this file is getting pretty big
- Create a web server with W5500 chip
- Write an OS
- Add Gameboy printer via Arduino to I/O
- Write a simplistic C compiler. Use software stack with dedicated stack pointer register.
- Change SPI Flash for SDCARD

## Todo documentation
- add DSUB9 pinout
- talk about memory bottleneck, Instruction per clock cycle.
- add design mistakes for io wing (uart pulldown, no shield to ground)
- add uart bootloader code/description to bootloader section
- think about removing bootloader code in documentation
- add some snippet of code + binary in assembler documentation
- check if uart bootloader jumpt to addr 5 or addr 0 when done
- add new functions to assembler page
	- rbp rsp mapped to r14 r15 for c compiler
	- added negative offset option for read, write and copy instruction
- add page for C compiler
	- add that r12 is used as tmp register (use example)
	- explain x86_64 -> b332 and similarities
	- note about the 4 word int offset because x86_64 has byte addressable memory (FPGC4 has word addressable memory). But because plenty of space and simplification for print statements in text, it is not worth it (for now) to change it to 1 word offset and risk more compiler bugs. This means that chars are stored in 32 bit spaces and therefore have no overflow. This also means that using variables longer that 32 bits (longs) are cutoff at 32 bits. Should not be a big issue, since we only have 27 bits addresses anyways.
	- testing compiler: currently by hand using gtkwave. In the future: 1) create single command for compiling c -> asm, asm -> machine -> uploading to FPGC4. 2) add software reset over UART, so we can upload without user interaction. 3) add asm code in tests.c files (at end of main) that send return code over UART back to pc. 4) use automated compiling, reset+upload, listen for return code, to verify if a test was successful. 5) create muliple tests.c files to test all functionality.
	- make a list of what is supported and some things that are not supported (division, switch)

## Todo C compiler related
- [done] Add neg offset flag in READ and WRITE and COPY instructions
- [done] Implement neg offset for READ and WRITE and COPY instructions
- [done] Map the name rbp and rsp to r14 and r15 in assembler
- add int1-4 functions
- add prefix with load 0x700000 rsp
- change return for hald on main
- change main from int to void
- add more instructions and test files
- eventually clean up code, remove size arg
- add inline assembly
- add static defines (apply before preprocessor)
- add hex support!!! (and binary while at it) (better do this in preprocessing)
- add bitwise | ^ and & operators (look at commit 31180511de0f95cf5dbda0bf98df71901a2fd1ed)

## Future improvements (FPGC5?)
- Maybe byte addressable memory
- Maybe pipelining
- Maybe DMA controller
- Maybe SDRAM for framebuffer (shared between CPU and GPU)