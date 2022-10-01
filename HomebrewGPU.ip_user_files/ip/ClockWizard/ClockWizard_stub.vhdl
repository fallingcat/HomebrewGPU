-- Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
-- Date        : Sat Oct  1 19:15:55 2022
-- Host        : TIGER running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               E:/MyWork/HomebrewGPU/HomebrewGPU.runs/ClockWizard_synth_1/ClockWizard_stub.vhdl
-- Design      : ClockWizard
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tcsg324-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ClockWizard is
  Port ( 
    clk_200 : out STD_LOGIC;
    clk_40 : out STD_LOGIC;
    clk_80 : out STD_LOGIC;
    resetn : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end ClockWizard;

architecture stub of ClockWizard is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_200,clk_40,clk_80,resetn,locked,clk_in1";
begin
end;
