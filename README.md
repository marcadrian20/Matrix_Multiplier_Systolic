# Matrix Multiplier
Parametrizable  NxN matrix multiplier implemented in  SystemVerilog

## Features
- Weight-stationary (TPU-style) PEs
- Scalable up to 16x16(through ARRAY_SIZE, may go higher, did not test)
- Easy to integrate into PYNQ 

## TODO
- Proper pipelining
- Matrix caching/buffering
- Maybe async FIFOs to saturate the memory interface faster (worth a shot)

## NOTES
- 142MHz at 8x8 possible, many factors may increase or decrease FMAX.
- Tested on Zedboard (ZYNQ 7000)
