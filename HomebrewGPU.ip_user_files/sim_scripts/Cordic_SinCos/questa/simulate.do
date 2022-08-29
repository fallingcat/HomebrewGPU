onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib Cordic_SinCos_opt

do {wave.do}

view wave
view structure
view signals

do {Cordic_SinCos.udo}

run -all

quit -force
