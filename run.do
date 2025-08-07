vlib work
vlog Counter.v SPI_Slave_Interface.v Single_Port_Asynch_RAM.v SPI_Wrapper.v SPI_Wrapper_TB.v +cover -covercells
vsim -voptargs=+acc work.SPI_Wrapper_TB -cover
add wave *
run -all
