onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib mig_opt

do {wave.do}

view wave
view structure
view signals

do {mig.udo}

run -all

quit -force
