# HomebrewGPU
HomebrewGPU is a simple ray tracing GPU on FPGA which implements basic ray-primitive intersection, BVH traversal, shadowing, reflection and refraction.
This is a project I used to learn programming in Verilog and I think it should be educational to someone who is new to FPGA.

![](/doc/HomebrewGPU.gif "")

## FPGA Board
[NEXYS A7](https://digilent.com/reference/programmable-logic/nexys-a7/start)

## Number Format
The GPU uses 2 basic number formats for ALU.

1. Q18.14 fixed point
2. Q2.14 fixed point for nomalized value

## Architecture
![](/doc/GPU_Architecture.png "")

### Thread Generator

### BVH Structure

### Primitive Unit

### Ray Core

### Frame Buffer Writer
