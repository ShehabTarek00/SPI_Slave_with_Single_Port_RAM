module Counter #(parameter Max_Count = 10) (
	input clk,    
	input enable, 
	input rst_n,
	output reg [$clog2(Max_Count)-1:0] Count // determine the width of the counter depending on the Max_Count by log2 function
);



always @(posedge clk or negedge rst_n) begin 
	if (~rst_n) begin
		Count <= 0;
	end
	else if (~(Count == (Max_Count+1))) begin // the counter stops at reaching Max_Count+1
		Count <= Count + 1;
	end
	else begin
		Count <= 0 ;
	end
end

endmodule : Counter