module Single_Port_Asynch_RAM #(parameter MEM_DEPTH = 256,parameter ADDR_SIZE = 8)(
	input clk,    
	input rst_n,  
	input [ADDR_SIZE+1:0] din,
	input rx_valid,
	output reg tx_valid,
	output [ADDR_SIZE-1:0] dout
);

// Memory to save all the data by addressing sent by spi slave  
reg [ADDR_SIZE-1:0] Memory [0:MEM_DEPTH-1];


reg [ADDR_SIZE-1:0] dout_reg;

// register used as a flag to be high when the address of the reading is holded to be read from the ram
reg Address_Saved;

// register used to hold the address for writing data sent by spi slave 
reg [ADDR_SIZE-1:0] Write_Address_reg;

// register used to hold the address for reading data to sent it to spi slave 
reg [ADDR_SIZE-1:0] Read_Address_reg;
	


always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		 dout_reg <= 'b0;
		 tx_valid <= 0;
		 Address_Saved<=0;
		 Write_Address_reg <=0; 
		 Read_Address_reg <=0;
	end else if (rx_valid) begin
		case (din[9:8])
		2'b00 : begin 
			Write_Address_reg <= din[7:0];
			Address_Saved<=1;
			tx_valid<=0;
		end

		2'b01 : begin 
			Memory[Write_Address_reg] <= din[7:0];
			Address_Saved<=0;
			tx_valid<=0;
		end

		2'b10 : begin 
			Read_Address_reg <= din[7:0];
			Address_Saved<=1;
			tx_valid<=0;
		end

		2'b11 : begin 
			tx_valid <= 1;
			dout_reg <= Memory[Read_Address_reg];
			Address_Saved <= 0;
		end
		endcase
	end 

		 
	
end


assign dout = dout_reg;



endmodule : Single_Port_Asynch_RAM