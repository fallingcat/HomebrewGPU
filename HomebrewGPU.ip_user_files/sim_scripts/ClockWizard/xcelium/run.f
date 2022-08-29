-makelib xcelium_lib/xpm -sv \
  "C:/Xilinx/Vivado/2021.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "C:/Xilinx/Vivado/2021.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../ip/ClockWizard/ClockWizard_clk_wiz.v" \
  "../../../ip/ClockWizard/ClockWizard.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

