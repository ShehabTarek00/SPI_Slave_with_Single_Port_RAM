module SPI_Wrapper (
	input clk, 
	input rst_n,
	input MOSI,
	input  SS_n,

	output MISO ,
	output [7:0] ram_data_out, // to track the output data from the RAM
	output [9:0] Internal_SPI_Reg_value, // to track the internal register in the spi slave
	output [2:0] current_state, // to track the current state of the spi slave machine
	output address_saved_flag, // to track the address flag
	output [3:0] spi_count , // to track the counter
	output tx_valid_wrap // to track the tx_valid 
);

//parameters
localparam MEM_DEPTH = 256;
localparam ADDR_SIZE = 8;
localparam Max_Count = 10;

wire tx_valid; //Out from the RAM
wire [ADDR_SIZE-1:0]tx_data; //dout from the RAM
wire rx_valid; //Out from the RAM
wire [ADDR_SIZE+1:0]rx_data;//din for the RAM

//internal wires for tracking
wire [ADDR_SIZE+1:0] Internal_SPI_Reg_value_wrap;
wire [2:0] current_state_wrap;
wire address_saved_flag_wrap;
wire [3:0] spi_count_wrap ;



//Instantiation of SPI Slave & RAM

Single_Port_Asynch_RAM #(MEM_DEPTH,ADDR_SIZE) SPI_RAM (
	.clk     (clk),
	.rst_n   (rst_n),
	.tx_valid(tx_valid),
	.rx_valid(rx_valid),
	.din     (rx_data),
	.dout    (tx_data)
	);

SPI_Slave_Interface #(ADDR_SIZE,Max_Count) SPI_Interface (
	.clk                   (clk),
	.rst_n                 (rst_n),
	.SS_n                  (SS_n),
	.tx_valid              (tx_valid),
	.rx_valid              (rx_valid),
	.MOSI                  (MOSI),
	.MISO                  (MISO),
	.tx_data               (tx_data),
	.rx_data               (rx_data),
	.Internal_SPI_Reg_value(Internal_SPI_Reg_value_wrap),
	.spi_count             (spi_count_wrap),
	.current_state         (current_state_wrap),
	.address_saved_flag    (address_saved_flag_wrap)
	);


assign  Internal_SPI_Reg_value  =Internal_SPI_Reg_value_wrap ;
assign current_state  = current_state_wrap;
assign address_saved_flag  = address_saved_flag_wrap;
assign spi_count  = spi_count_wrap;
assign tx_valid_wrap = tx_valid;
assign ram_data_out = tx_data;


endmodule : SPI_Wrapper