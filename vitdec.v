module vitdec_forward (		enc_data1, 
				enc_data2, 
				enc_data3, 
				enc_data4,
				clk, 
				rst, 
				frame_rst, 
				result);
parameter			r			=	2,	//r = 2 radix4; r = 1 radix2;
				n			=	2,
				m			=	7,
				k			=	1,
				nu			=	6,
				state			=	64,
				tb_length		=	128,
				tb_length_log		=	7,
				bitwise			=	3,
				reglen			=	9;

input	[0:bitwise-1]		enc_data1		,
				enc_data2		,
				enc_data3		,
				enc_data4		;
input				clk			,
				rst			,
				frame_rst		;

output	[0:r-1]			result			;

reg	[0:m-1]			generator		[0:n-1];
reg	[0:bitwise-1]		input_temp		[0:n*r-1];
reg	[0:n*r-1]		hamm_calc_index		[0:2^(n*r)-1];
reg	[0:bitwise+r-1]		hamm_dist		[0:n*r-1];
reg	[0:bitwise+r-1]		hamm_dist_tmp0		[0:r-1][0:n*r-1];
reg	[0:bitwise+r-1]		hamm_dist_tmp1		[0:n*r-1];
reg	[0:r+nu-1]		branch_index_tmp	;
reg	[2*r-1:0]		hamm_dist_index		[0:r*2-1][0:state-1];
reg	[0:bitwise-1]		hamm_temp		[0:n*r-1][0:2^(n*r)-1];
wire	[0:reglen-1]		branch_metric_calc	[0:2*r-1][0:state-1];		//wire
wire	[0:r*(2r-1)-1]		decision_tmp		[0:state-1];			//wire	
reg	[0:reglen-1]		branch_metric		[0:state-1];			//reg
wire	[0:reglen-1]		branch_metric_w		[0:state-1];			//wire
reg	[0:nu-1]		branch_metric_index	[0:2*r-1][0:state-1];
reg	[0:r-1]			decision		[0:state-1];			//reg
reg				tb_ram			[0:state-1][0:tb_length-1][0:3];
reg	[0:nu-1]		counter_st		;
reg	[0:3]			counter_id0		;
reg	[0:3]			counter_id1		;
reg	[0:3]			counter_id2		;
reg	[0:3]			counter_id3		;
reg	[0:tb_length_log-1]	counter_tb		;
reg	[0:tb_length_log-1]	counter_tbn		;
reg	[0:nu-1]		tb_state		;
reg	[0:nu-1]		dec_state		;
reg	[0:tb_length-1]		decode_tmp		;
reg	[0:tb_length-1]		output_seq		;
reg	[0:r-1]			result_temp		;

integer			i, j, ii, jj, kk;

genvar			gi, gj, gk, gii, gjj, gkk;

initial
begin
	if (n == 2 && m == 7)
	begin
		generator[0] = 7'b1111001;
		generator[1] = 7'b1011011;
	end
	else
	begin
		$display("no generator!!!\n");
	end

	for (j = 0; j < 2^(n*r); j = j + 1)
	begin
		hamm_calc_index[j] = j;
	end

	counter_st = 0;
	counter_id0 = 0;
	counter_id1 = 1;
	counter_id2 = 2;
	counter_id3 = 3;
	counter_tb = 0;
	counter_tbn = -1;
	decode_tmp = 0;
	output_seq = 0;
	result_temp = 0;
	tb_state = 7;
	dec_state = 7;
	tb_ram[0:state-1][0:tb_length-1][0:3] = 0;
/*	for (i = 0; i < state; i = i + 1)
		for (j = 0; j < 2*r; j = j + 1)
		begin
			branch_index_tmp = i * 2 * r + j;
			for (ii = r - 1; ii >= 0; ii = ii - 1)*/
end

generate for (gi = 0; gi < state; gi = gi + 1)
	for (gj = 0; gj < 2*r; gj = gj + 1)
	begin
		branch_index_tmp = gi * 2 * r + gj;
		for (gii = r - 1; gii >= 0; gii = gii - 1)
			for (gjj = n - 1; gjj >= 0; gjj = gjj - 1)
				assign hamm_dist_index[gj][gi][gii*2+gjj] = ^(generator^branch_metric_tmp[gii:gii+nu]);
	end
endgenerate

always @ (posedge clk or rst)
begin
	if 	(rst == 0)		counter_tb = 0;
	else if	(frame_rst == 1)	counter_tb = 0;
	else 				counter_tb = counter_tb + 1;
end

always @ (posedge clk or rst)
begin
	if 	(rst == 0)		counter_tbn = ~counter_tb;
	else if	(frame_rst == 1)	counter_tbn = ~counter_tb;
	else 				counter_tbn = counter_tbn - 1;
end

always @ (posedge clk or rst)
begin
	if 	(rst == 0)		counter_id0 = 0;
	else if	(frame_rst == 1)	counter_id0 = 0;
	else if (counter_tb == 0)	counter_id0 = counter_id0 + 1;
	else				counter_id0 = counter_id0;
end

always @ (posedge clk or rst)
begin
	if 	(rst == 0)		counter_id1 = 1;
	else if	(frame_rst == 1)	counter_id1 = 1;
	else if (counter_tb == 0)	counter_id1 = counter_id1 + 1;
	else				counter_id1 = counter_id1;
end

always @ (posedge clk or rst)
begin
	if 	(rst == 0)		counter_id2 = 2;
	else if	(frame_rst == 1)	counter_id2 = 2;
	else if (counter_tb == 0)	counter_id2 = counter_id2 + 1;
	else				counter_id2 = counter_id2;
end

always @ (posedge clk or rst)
begin
	if 	(rst == 0)		counter_id3 = 3;
	else if	(frame_rst == 1)	counter_id3 = 3;
	else if (counter_tb == 0)	counter_id3 = counter_id3 + 1;
	else				counter_id3 = counter_id3;
end


always @ (posedge clk or rst)
begin
	if (rst == 0)	
	begin	
		generate 
			for (gi = 0; gi < n*r; gi = gi + 1)	input_temp = 0;
		endgenerate
	end
	else if (frame_rst == 1)
	begin	
		generate 
			for (gi = 0; gi < n*r; gi = gi + 1)	input_temp = 0;
		endgenerate
	end
	else
	begin
		generate
		begin
			case (r)
			1:
			begin
				input_temp[0] = enc_data1;
				input_temp[1] = enc_data2;
			end
			2:
			begin
				input_temp[0] = enc_data1;
				input_temp[1] = enc_data2;
				input_temp[2] = enc_data3;
				input_temp[3] = enc_data4;
			end
			default:
			begin
				input_temp[0] = enc_data1;
				input_temp[1] = enc_data2;
				input_temp[2] = enc_data3;
				input_temp[3] = enc_data4;
			end
		end
		endgenerate				
	end
end


generate for (gi = 0; gi < 2^(n*r); gi = gi + 1)
begin
	for (gj = 0; gj < n*r; gj = gj + 1)
		hamm_temp[gj][gi] = input_temp[gj] ^ { bitwise{hamm_calc_index} };
	for (gj = 0; gj < n*r; gj = gj + 1)
		hamm_dist_tmp1[gi] = hamm_dist_tmp1[gi] + hamm_temp[gj][gi];
end
endgenerate

generate for (gi = 0; gi < 2^(n*r); gi = gi + 1)
begin
	always @ (posedge clk or rst)	
	begin
		if (rst == 0)			hamm_dist[gi] = 0;
		else if (frame_rst == 1)	hamm_dist[gi] = 0;
		else 				hamm_dist[gi] = hamm_dist_tmp1[gi];
	end
end
endgenerate

generate for (gi = 0; gi < state; gi = gi + 1)
	for (gj = 0; gj < 2*r; gj = gj + 1)
		branch_metric_calc[gj][gi] = branch_metric[gi*2*r+gj] + hamm_dist[hamm_dist_index[gj][gi]];
	end
end
endgenerate

generate for (gi = 0; gi < state; gi = gi + 1)
begin
	gk = 0;
	for (gii = 0; gii < 2*r; gii = gii + 1)
	begin
		for (gjj = gii + 1; gjj < 2*r; gjj = gjj + 1)
		begin
			decision_tmp[gi][gk] = branch_metric_calc[gii][gi] > branch_metric_calc[gjj][gi];
			gk = gk + 1;
		end
	end
end
endgenerate

generate for (gi = 0; gi < state; gi = gi + 1)
begin
	case (r)
	
	2:	begin
			always @ (posedge clk or rst)
			begin
				if (rst == 0)			decision[gi] = 0;
				else if (frame_rst == 1)	decision[gi] = 0;
				else 	
				case (decision_tmp[gi])
					6'bxxx000	:	decision[gi] = 0;
					6'bx00xx1	:	decision[gi] = 1;
					6'b0x1x1x	:	decision[gi] = 2;
					6'b11x1xx	:	decision[gi] = 3;
					default		:	decision[gi] = 0;
				endcase
			end
			always @ (posedge clk or rst)
			begin
				if (rst == 0)			branch_metric[gi] = 0;
				else if (frame_rst == 1)	branch_metric[gi] = 0;
				else 
				case (decision_tmp[gi])
					6'bxxx000	:	branch_metric[gi] = branch_metric_calc[0][gi];
					6'bx00xx1	:	branch_metric[gi] = branch_metric_calc[1][gi];
					6'b0x1x1x	:	branch_metric[gi] = branch_metric_calc[2][gi];
					6'b11x1xx	:	branch_metric[gi] = branch_metric_calc[3][gi];
					default		:	branch_metric[gi] = branch_metric_calc[0][gi];
				endcase
			end
		end

	1:	begin
			always @ (posedge clk or rst)
			begin
				if (rst == 0)			decision[gi] = 0;
				else if (frame_rst == 1)	decision[gi] = 0;
				else 				decision[gi] = decision_tmp[gi];
			end
			always @ (posedge clk or rst)
			begin
				if (rst == 0)			branch_metric[gi] = 0;
				else if (frame_rst == 1)	branch_metric[gi] = 0;
				else 				
					case (decision_tmp[gi])
						1'b0		:	branch_metric[gi] = branch_metric_calc[0][gi];
						1'b1		:	branch_metric[gi] = branch_metric_calc[1][gi];
						default		:	branch_metric[gi] = branch_metric_calc[0][gi];
					endcase
			end
		end	

	default:begin
			always @ (posedge clk or rst)
			begin
				if (rst == 0)			decision[gi] = 0;
				else if (frame_rst == 1)	decision[gi] = 0;
				else 	
				case (decision_tmp[gi])
					6'bxxx000	:	decision[gi] = 0;
					6'bx00xx1	:	decision[gi] = 1;
					6'b0x1x1x	:	decision[gi] = 2;
					6'b11x1xx	:	decision[gi] = 3;
					default		:	decision[gi] = 0;
				endcase
			end
			always @ (posedge clk or rst)
			begin
				if (rst == 0)			branch_metric[gi] = 0;
				else if (frame_rst == 1)	branch_metric[gi] = 0;
				else 
				case (decision_tmp[gi])
					6'bxxx000	:	branch_metric[gi] = branch_metric_calc[0][gi];
					6'bx00xx1	:	branch_metric[gi] = branch_metric_calc[1][gi];
					6'b0x1x1x	:	branch_metric[gi] = branch_metric_calc[2][gi];
					6'b11x1xx	:	branch_metric[gi] = branch_metric_calc[3][gi];
					default		:	branch_metric[gi] = branch_metric_calc[0][gi];
				endcase
			end
		end
	endcase	
end
		
endgenerate

generate for (gi = 0; gi < r; gi = gi + 1)
begin
always @ (posedge clk or rst)
begin
//	if (rst == 0)			tb_ram = 0;
//	else if (frame_rst == 1)	tb_ram = 0;
//	else 
	for (gj = 0; gj < state; gj = gj + 1)
		tb_ram[gj][counter_tb+gi][counter_id0] = decision[gj][gi];
//		tb_ram[gj][counter_tb:counter_tb+r-1][counter_id0] = decision[gj];
	
end
end
endgenerate	

endmodule
