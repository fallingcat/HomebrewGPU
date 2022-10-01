# The package naming convention is <core_name>_xmdf
package provide mig_xmdf 1.0

# This includes some utilities that support common XMDF operations 
package require utilities_xmdf

# Define a namespace for this package. The name of the name space
# is <core_name>_xmdf
namespace eval ::mig_xmdf {
# Use this to define any statics
}

# Function called by client to rebuild the params and port arrays
# Optional when the use context does not require the param or ports
# arrays to be available.
proc ::mig_xmdf::xmdfInit { instance } {
	# Variable containing name of library into which module is compiled
	# Recommendation: <module_name>
	# Required
	utilities_xmdf::xmdfSetData $instance Module Attributes Name mig
}
# ::mig_xmdf::xmdfInit

# Function called by client to fill in all the xmdf* data variables
# based on the current settings of the parameters
proc ::mig_xmdf::xmdfApplyParams { instance } {

set fcount 0
	# Array containing libraries that are assumed to exist
	# Examples include unisim and xilinxcorelib
	# Optional
	# In this example, we assume that the unisim library will
	# be magically
	# available to the simulation and synthesis tool
	utilities_xmdf::xmdfSetData $instance FileSet $fcount type logical_library
	utilities_xmdf::xmdfSetData $instance FileSet $fcount logical_library unisim
	incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/clocking/mig_7series_v4_2_clk_ibuf.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/clocking/mig_7series_v4_2_infrastructure.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/clocking/mig_7series_v4_2_iodelay_ctrl.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/clocking/mig_7series_v4_2_tempmon.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_arb_mux.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_arb_row_col.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_arb_select.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_bank_cntrl.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_bank_common.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_bank_compare.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_bank_mach.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_bank_queue.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_bank_state.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_col_mach.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_mc.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_rank_cntrl.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_rank_common.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_rank_mach.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ecc/mig_7series_v4_2_ecc_buf.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ecc/mig_7series_v4_2_ecc_dec_fix.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ecc/mig_7series_v4_2_ecc_gen.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ecc/mig_7series_v4_2_ecc_merge_enc.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ecc/mig_7series_v4_2_fi_xor.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ip_top/mig_7series_v4_2_memc_ui_top_std.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ip_top/mig_7series_v4_2_mem_intfc.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/mig.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/mig_mig.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_byte_group_io.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_byte_lane.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_calib_top.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_if_post_fifo.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_of_pre_fifo.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_4lanes.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ck_addr_cmd_delay.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_dqs_found_cal.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_dqs_found_cal_hr.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_init.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_cntlr.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_data.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_edge.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_lim.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_mux.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_po_cntlr.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_samp.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_oclkdelay_cal.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_prbs_rdlvl.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_rdlvl.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_tempmon.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_top.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrcal.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrlvl.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrlvl_off_delay.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_ddr_prbs_gen.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_poc_cc.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_poc_edge_store.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_poc_meta.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_poc_pd.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_poc_tap_base.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/phy/mig_7series_v4_2_poc_top.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ui/mig_7series_v4_2_ui_cmd.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ui/mig_7series_v4_2_ui_rd_data.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ui/mig_7series_v4_2_ui_top.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/rtl/ui/mig_7series_v4_2_ui_wr_data.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/constraints/mig.ucf
utilities_xmdf::xmdfSetData $instance FileSet $fcount type ucf 
utilities_xmdf::xmdfSetData $instance FileSet $fcount associated_module mig
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path mig/user_design/constraints/mig.xdc
utilities_xmdf::xmdfSetData $instance FileSet $fcount type xdc 
utilities_xmdf::xmdfSetData $instance FileSet $fcount associated_module mig
incr fcount

}

# ::gen_comp_name_xmdf::xmdfApplyParams
