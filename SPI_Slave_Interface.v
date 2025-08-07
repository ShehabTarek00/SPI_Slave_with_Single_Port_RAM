module SPI_Slave_Interface #(parameter ADDR_SIZE = 8 , parameter Max_Count = 10) (
	input clk,    
	input rst_n,  
	input SS_n,
	input tx_valid, //Out from the RAM
	input  [ADDR_SIZE-1:0] tx_data, //dout from the RAM
	input MOSI, // Master Out - Slave In
	output reg rx_valid, //Out from the RAM
	output [ADDR_SIZE+1:0] rx_data,//din for the RAM
	output reg MISO, // Master In - Slave Out
	output [9:0] Internal_SPI_Reg_value, // to track the internal register of the spi slave
	output [2:0] current_state, // to track the current state of the spi slave's machine
	output address_saved_flag, // to track the address flag
	output [$clog2(Max_Count)-1:0] spi_count // to track the counter inside the spi slave
);


//Counter Instantiation
reg rst_n_counter;
localparam Count_Width = $clog2(Max_Count);
wire [Count_Width-1:0] Count;
Counter #(Max_Count) Counter_10 (clk,(~SS_n),rst_n_counter,Count);

// register used as a flag to be high when the address of the reading is holded to be read from the ram
reg Address_Saved; 

// parameters for the machine states 
localparam IDLE		=3'd0;
localparam CHK_CMD	=3'd1;
localparam WRITE	=3'd2;
localparam READ_ADD =3'd3;
localparam READ_DATA=3'd4;


reg [2:0] Current_State,Next_State;
reg [9:0] Internal_SPI_Reg;


//State Memory always block
always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin
		Current_State <= IDLE;
		Internal_SPI_Reg <= 'b0;
	end else begin
		Current_State <= Next_State;
	end
end


//Next state Logic always block
always @(*) begin 
	case (Current_State)
	IDLE : 
	begin
		if (SS_n) begin
		 	Next_State = IDLE;
		 	rst_n_counter = 0;
		 end 
		 else begin
		 	Next_State = CHK_CMD;
		 end
	end

	CHK_CMD : 
	begin 
		rst_n_counter = 1;
		if (SS_n) begin
			Next_State = IDLE;
		end
	 	else begin 
		//Internal_SPI_Reg[9] = MOSI;
		 	if (MOSI == 0) begin
		 		Next_State = WRITE;
		 		rst_n_counter = 0;
		 	end
	 	else if (MOSI == 1) begin
	 		if (Address_Saved) begin
	 			Next_State = READ_DATA ;
	 			rst_n_counter = 0;
	 		end
	 	else begin
	 		Next_State = READ_ADD ;
	 		rst_n_counter = 0;
	 		end
	 	end
	 	end
	end

	WRITE : 
	begin 
		rst_n_counter = 1;
		if (SS_n) begin
			Next_State = IDLE;
		end
		else if (Count < 10) begin
			Next_State = WRITE;
		end
		else begin
			rst_n_counter = 0;
			Next_State = IDLE;
		end 
	end

	READ_ADD : 
	begin 
		rst_n_counter = 1;
		if (SS_n) begin
			Next_State = IDLE;
		end
		else if (Count < 10) begin
			Next_State = READ_ADD;
		end
		else begin
			rst_n_counter = 0;
			Next_State = IDLE;
		end 
	end

	READ_DATA : 
	begin 
		rst_n_counter = 1;
		if (SS_n) begin
			Next_State = IDLE;
		end
		else if (Count < 10) begin
			Next_State = READ_DATA;
		end
		else begin
			rst_n_counter = 0;
			Next_State = IDLE;
		end 
	end

	default : 
	begin
		rst_n_counter = 0;
		Next_State = IDLE;
	end 
	endcase
end


//Output Logic always block
always @(posedge clk) begin   
	case (Current_State)
		IDLE : 
			begin
				rx_valid = 0;
        		Internal_SPI_Reg = 'b0;
			end
		CHK_CMD : 
			begin
				rx_valid = 0;
        		if (~SS_n) Internal_SPI_Reg = {9'b0,MOSI};
			end
		WRITE : 
			begin
				if (~SS_n && Count < 10) begin
				rx_valid = 0;
				Internal_SPI_Reg = {Internal_SPI_Reg[8:0], MOSI}; 
	            end
				else rx_valid = 1; 
			end
		READ_ADD : 
			begin
				if (~SS_n && Count < 10) begin
				rx_valid = 0;
				Internal_SPI_Reg = {Internal_SPI_Reg[8:0], MOSI}; 
	            end
				else rx_valid = 1; 
			end
		READ_DATA : 
			begin
				if (Count < 9 && (~SS_n)) begin
					
				if (tx_valid) MISO = tx_data[Count];


            	rx_valid = 0;
            	Internal_SPI_Reg = {Internal_SPI_Reg[8:0], MOSI};
	            end
	           	else rx_valid = 1;
			end
		default : 
			begin
				rx_valid = 0;
        		Internal_SPI_Reg = 'b0;
			end
	endcase
end 
//end of output logic always block



// Address_Saved always block
always @(posedge clk or negedge rst_n) begin  
	if(~rst_n) begin
		 Address_Saved <= 0;
	end else begin
		if ((Count == 'd9) && (Current_State == READ_ADD)) Address_Saved <= 1'b1;
		else if ((Count == 'd9) && (Current_State == READ_DATA)) Address_Saved <= 1'b0;
	end
end




assign rx_data = (rx_valid == 1)  ? Internal_SPI_Reg : 'bX ;
assign current_state = Current_State;
assign address_saved_flag = Address_Saved;
assign spi_count = Count;
assign Internal_SPI_Reg_value = Internal_SPI_Reg;


endmodule : SPI_Slave_Interface




