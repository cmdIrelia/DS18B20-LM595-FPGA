module LCD(
		sys_clk,
		sys_rst_n,
		
		Num1,
		Num2,
		Num3,
		Num4,
		
		DIO,
		SCLK,
		RCLK
		);

input sys_clk,sys_rst_n;
		
input[7:0] Num1;
input[7:0] Num2;
input[7:0] Num3;
input[7:0] Num4;

output reg DIO;
output reg SCLK;
output reg RCLK;


reg[31:0] count_5us;
reg clk;
always@(posedge sys_clk or negedge sys_rst_n) begin
	if(!sys_rst_n) begin
		count_5us<='b0;
		clk<='b0;
	end
	else begin
		if(count_5us<='d500_000) begin
			count_5us<=count_5us+1'b1;
			clk=~clk;
		end
		else begin
			count_5us<='b0;
		end
	end
end

//++++++++++++++++++++++++++++++++++++++
// 格雷码
localparam S00     = 5'h00;
localparam S01     = 5'h01;
localparam S10     = 5'h03;
localparam S11     = 5'h02;
localparam S20     = 5'h06;
localparam S21     = 5'h07;
localparam S30     = 5'h05;
localparam S31     = 5'h04;
localparam S7      = 5'h0C;
localparam WRITE0  = 5'h0D;
localparam WRITE1  = 5'h0F;
localparam WRITE2  = 5'h0E;
localparam WRITE3  = 5'h0A;
localparam WRITE4  = 5'h0B;
localparam WRITE5  = 5'h09;
localparam WRITE6  = 5'h08;
localparam WRITE7  = 5'h18;

reg[7:0] lut[10:0];
initial begin
	lut[0]='hc0;
	lut[1]='hf9;
	lut[2]='ha4;
	lut[3]='hb0;
	lut[4]='h99;
	lut[5]='h92;
	lut[6]='h82;
	lut[7]='hf8;
	lut[8]='h80;
	lut[9]='h90;
	lut[10]='hc6;//'c'
end

reg[7:0] state;
reg[7:0] next_state,next_state2;
reg[7:0] write_data;
reg[7:0] write_data_cycle;
reg[7:0] write_cycle;
always @(posedge clk or negedge sys_rst_n) begin
	if(!sys_rst_n) begin
		state<=S00;
		DIO='b0;
		SCLK<='b0;
		RCLK<='b0;
		write_cycle<='b0;
		write_data_cycle<='d0;
	end
	else begin
		case(state)
		S00: begin
			write_data<=lut[Num1];
			state<=WRITE0;	//写数字
			next_state2<=S01;
		end
		S01: begin
			write_data<=1;
			state<=WRITE0;	//选位
			next_state2<=WRITE1;	//RCLK输出
			next_state<=S10;
		end
		S10: begin
			write_data<=lut[Num2];
			state<=WRITE0;	//写数字
			next_state2<=S11;
		end
		S11: begin
			write_data<=2;
			state<=WRITE0;	//选位
			next_state2<=WRITE1;	//RCLK输出
			next_state<=S20;
		end
		S20: begin
			write_data<=lut[Num3] & (~'h80);
			state<=WRITE0;	//写数字
			next_state2<=S21;
		end
		S21: begin
			write_data<=4;
			state<=WRITE0;	//选位
			next_state2<=WRITE1;	//RCLK输出
			next_state<=S30;
		end
		S30: begin
			write_data<=lut[Num4];
			state<=WRITE0;	//写数字
			next_state2<=S31;
		end
		S31: begin
			write_data<=8;
			state<=WRITE0;	//选位
			next_state2<=WRITE1;	//RCLK输出
			next_state<=S00;
		end

		
		WRITE0: begin
			DIO<=write_data['d7-write_data_cycle];
			case(write_cycle)
				0: begin
					write_cycle<=write_cycle+1'b1;
				end
				1: begin 
					SCLK=1'b0;
					write_cycle<=write_cycle+1'b1;
				end
				2: begin
					SCLK=1'b1;
					write_cycle<='b0;	//完成一位数据写出
					if(write_data_cycle=='d7) begin
						write_data_cycle<='b0;
						state<=next_state2;
					end
					else begin
						write_data_cycle<=write_data_cycle+1'b1;	//下一位数据
					end
				end
			endcase
		end
		
		WRITE1: begin
			RCLK<=1'b0;
			state<=WRITE2;
		end
		WRITE2: begin
			RCLK<=1'b1;
			state<=WRITE3;
		end
		WRITE3: begin
			state<=next_state;
		end
		endcase
	end
end
endmodule
	
