`timescale 1us/1ns
module SPI_Wrapper_TB ();
	
reg clk,rst_n;
reg MOSI;
reg SS_n;

wire MISO;
wire [9:0] Internal_SPI_Reg_value_wrap;
wire [2:0] current_state_wrap;
wire address_saved_flag_wrap;
wire [3:0] spi_count_wrap ;
wire tx_valid_wrap;
wire [7:0] ram_data_out;

//registers to use them to store the sent or recieved bytes 
reg [9:0] Sent_Byte;
reg [7:0] Recieved_Byte;

//Instantiation
SPI_Wrapper SPI_Wrapper_DUT (
	.clk 					(clk),
	.rst_n					(rst_n),
	.MOSI 					(MOSI),
	.SS_n 					(SS_n),
	.MISO 					(MISO),
	.Internal_SPI_Reg_value (Internal_SPI_Reg_value_wrap),
	.current_state 			(current_state_wrap),
	.address_saved_flag 	(address_saved_flag_wrap),
	.spi_count 				(spi_count_wrap),
	.ram_data_out 			(ram_data_out),
	.tx_valid_wrap 			(tx_valid_wrap)
	);

// Clock generation
localparam clk_period = 2; // by default the period of the clk is 2nsec (frequency = 500KHz) 
initial begin
	clk = 0;
	forever #1 clk = ~clk;
end


initial begin
	
	reset();

	Sent_Byte = 10'b00_1111_1111; //0ff
	Send_Byte(Sent_Byte);
	Sent_Byte = 10'b1_1100_1111; //1cf , Data Sent to RAM = 8'hcf
	Send_Byte(Sent_Byte);
	Sent_Byte = 10'b10_1111_1111;  //2ff
	Send_Byte(Sent_Byte);

	Sent_Byte = 10'b11_0001_0001; //311
	Recieve_Byte(Sent_Byte,Recieved_Byte);

	$display("--------------------------");
	$display("Received Byte = %b (0x%0h)", Recieved_Byte, Recieved_Byte);
	$display("--------------------------");
	#(clk_period * 4);
	$stop;
	
end

// task for reseting spi wrapper
task reset();
	begin
		rst_n = 0;
		SS_n = 1;
		#(clk_period * 2);
		rst_n = 1;
		#(clk_period * 2);
	end
endtask 

// task for sending the byte through the MOSI input port
task Send_Byte(input reg [9:0] Byte);
	integer i;
	begin	
		SS_n = 0;
		#(clk_period);
		for (i = 9; i>=0 ; i=i-1) begin
			MOSI = Byte[i];
			#(clk_period);
		end
		SS_n = 1;
		#(clk_period);
	end
endtask 


// task for READ_DATA state , it sends the last byte in the communication between the slave and the ram  
// & recieves the data byte from the ram through the MISO output port
task Recieve_Byte(input reg [9:0] Byte,output reg [9:0] Rx_Byte);
	integer i;
	begin
		SS_n = 0;
		#(clk_period);
		for (i = 9; i>=0 ; i=i-1) begin
		    MOSI = Byte[i];
	    	#(clk_period);
		end

		@(posedge tx_valid_wrap);
		wait (MISO == 0 || MISO == 1 );

		for (i = 0; i <= 7 ; i=i+1) begin   
			Rx_Byte[i] = MISO;
			@(negedge clk);
		end
		#(clk_period);
		SS_n = 1;
	end
endtask 



endmodule : SPI_Wrapper_TB


