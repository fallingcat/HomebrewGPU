onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+mig -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.mig xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {mig.udo}

run -all

endsim

quit -force
