onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+Cordic_SinCos -L xbip_utils_v3_0_10 -L c_reg_fd_v12_0_6 -L xbip_dsp48_wrapper_v3_0_4 -L xbip_pipe_v3_0_6 -L xbip_dsp48_addsub_v3_0_6 -L xbip_addsub_v3_0_6 -L c_addsub_v12_0_14 -L xbip_bram18k_v3_0_6 -L mult_gen_v12_0_16 -L axi_utils_v2_0_6 -L cordic_v6_0_16 -L xil_defaultlib -L secureip -O5 xil_defaultlib.Cordic_SinCos

do {wave.do}

view wave
view structure

do {Cordic_SinCos.udo}

run -all

endsim

quit -force
