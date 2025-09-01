module Systolic_Array #(
    parameter ARRAY_SIZE = 3,
    // parameter INPUT_WIDTH = 32,
    parameter DATA_WIDTH = 8,
    parameter MAX_MATRICES = 2
)(
    input logic clk,
    input logic rst_n,
    input logic start,
    output logic done,
    output logic busy,
    output logic ready,
    input logic [(DATA_WIDTH * ARRAY_SIZE) - 1 : 0] MATRIX_A_COL, 
    input logic [(DATA_WIDTH * ARRAY_SIZE) - 1 : 0] MATRIX_B_ROW,
    output logic [clogb2(ARRAY_SIZE*MAX_MATRICES)-1:0] addr_matrix_A, 
    output logic [clogb2(ARRAY_SIZE*MAX_MATRICES)-1:0] addr_matrix_B, 
    output logic signed [7 : 0] result_output [(ARRAY_SIZE*ARRAY_SIZE)-1:0] 
);
logic signed [7:0] result1;
logic signed [7:0] result2;
logic signed [7:0] result3;
logic signed [7:0] result4;
logic signed [7:0] test_shifter;
logic signed [7:0] test_shifter2;
logic signed [7:0] test_shifter3;
logic signed [7:0] test_shifter4;

// logic signed [7:0] result4;
assign result1=result_output[0];
assign result2=result_output[1];
assign result3=result_output[2];
assign result4=result_output[3];
// assign test_shifter=local_buffer[load_counter][0];
// assign test_shifter2=local_buffer[1][0];
// assign result4=result_output[3];
typedef enum logic [2:0]{ 
    IDLE,
    WEIGHT_LOAD,
    ACTIVATION_LOAD,
    COMPUTE,
    STORE,
    DONE
} MULT_STATE_MACHINE;
MULT_STATE_MACHINE current_state,next_state;

logic weight_load_en;
logic compute_en;
logic signed [7:0]PE_ARRAY_input_A [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0];
logic signed [7:0]PE_ARRAY_input_B[ARRAY_SIZE-1:0][ARRAY_SIZE-1:0];
logic signed [7:0]PE_ARRAY_output_A[ARRAY_SIZE-1:0][ARRAY_SIZE-1:0];
logic signed [7:0]PE_ARRAY_output_B[ARRAY_SIZE-1:0][ARRAY_SIZE-1:0];
// reg  [DATA_WIDTH-1:0] result_matrix [0:ARRAY_SIZE*ARRAY_SIZE-1];
logic signed [7:0] activation_feed[ARRAY_SIZE-1:0];
logic signed [7:0] weight_feed[ARRAY_SIZE-1:0];
reg [7:0] local_buffer [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0];
logic [$clog2(2*ARRAY_SIZE):0] slide_counter;
logic [7:0] cycle_counter;
logic [7:0] load_counter;
generate 
    for (genvar i = 0; i < ARRAY_SIZE; i++) begin: gen_unpack
        always_comb begin
            if (current_state == COMPUTE) begin
                if (cycle_counter >= i) begin
                    if ((cycle_counter - i) < ARRAY_SIZE) begin
                        activation_feed[i] = local_buffer[i][cycle_counter - i];
                    end else begin
                        activation_feed[i] = '0;
                    end
                end else begin
                    activation_feed[i] = '0;
                end
            end else begin
                activation_feed[i] = '0;
            end
        end
        assign weight_feed[i] = MATRIX_B_ROW[(i+1)*DATA_WIDTH-1: i*DATA_WIDTH];
    end
endgenerate
assign test_shifter=activation_feed[0];
assign test_shifter2=activation_feed[1];



// always_ff @(posedge clk) begin
//     if(!rst_n) begin
//         for(int i=0; i<ARRAY_SIZE;i++) begin
//             for(int j=0; j<(2 * ARRAY_SIZE)-1;j++) begin
//                 shift_reg[i][j]<='0;
//             end
//         end
//     end
//     else begin
//             for(int i=0; i<ARRAY_SIZE-1;i++) begin
//                 for(int j=0; j<(2 * ARRAY_SIZE)-2;j++) begin
//                     shift_reg[i][j]<=shift_reg[i][j-1];
//                     if(weight_load_en) begin
//                         {shift_reg[i][j],shift_reg[i+1][j+1]}<=MATRIX_A_COL;
//                     end
//                 end
//             end
//     end
// end


generate
    for (genvar i = 0; i < ARRAY_SIZE; i++) begin: gen_row
        for (genvar j = 0; j < ARRAY_SIZE; j++) begin: gen_col
            PE processing_element(
                .clk(clk),
                .rst_n(rst_n),
                .weight_load_en(weight_load_en),
                .compute_en(compute_en),
                .input_A(PE_ARRAY_input_A[i][j]),
                .input_B(PE_ARRAY_input_B[i][j]),
                .output_A(PE_ARRAY_output_A[i][j]),
                .output_B(PE_ARRAY_output_B[i][j])
                );
        end
    end
endgenerate


always_comb begin
    for (int i = 0; i < ARRAY_SIZE; i++) begin
        for (int j = 0; j < ARRAY_SIZE; j++) begin
            PE_ARRAY_input_A[i][j]=(j == 0)? activation_feed[i]:PE_ARRAY_output_A[i][j-1];
        end
    end
    for (int i = 0; i < ARRAY_SIZE; i++) begin
        for (int j = 0; j < ARRAY_SIZE; j++) begin
            if(weight_load_en) begin
                PE_ARRAY_input_B[i][j]=(i==0)?weight_feed[j]:PE_ARRAY_output_B[i-1][j];
            end else begin
                PE_ARRAY_input_B[i][j]=(i==0)?'0:PE_ARRAY_output_B[i-1][j];
            end
        end
    end
end



always_ff @(posedge clk) begin
    if(!rst_n) begin
        current_state<=IDLE;
    end
    else begin
        current_state<= next_state;
    end
end

always_comb begin
    next_state = current_state;
    case(current_state)
        IDLE: begin 
            if(start)
                next_state= WEIGHT_LOAD;
        end
        WEIGHT_LOAD: 
            if(load_counter == ARRAY_SIZE-1) 
                next_state = ACTIVATION_LOAD;
        ACTIVATION_LOAD: next_state = COMPUTE;
        COMPUTE: begin
            if(cycle_counter>=(3 * ARRAY_SIZE - 1))
                next_state=DONE;
        end
        // STORE: next_state = DONE;
        DONE: next_state = IDLE;
    endcase
end

logic signed [7:0] debug;

always_ff @(posedge clk) begin
    if(!rst_n) begin
        cycle_counter<= '0;
        load_counter<='0;
        weight_load_en<='0;
        compute_en<='0;
        debug<='0;
        busy<='0;
        done<='0;
        addr_matrix_A<='0;
        // addr_matrix_B<=ARRAY_SIZE; this and incrementing the address were a simple workaround
        addr_matrix_B<=2*ARRAY_SIZE-1'b1;

        
        for (int j = 0; j <ARRAY_SIZE*ARRAY_SIZE; j++) begin
                    result_output[j] <= '0;
        end
        for(int i=0; i<ARRAY_SIZE;i++) begin
            for(int j=0; j<ARRAY_SIZE;j++) begin
                local_buffer[i][j]<='0;
            end
        end
        slide_counter<='0;
    end
    else begin
        case(current_state)
            IDLE: begin
                {cycle_counter,load_counter,weight_load_en,busy,done}<='0;        
                addr_matrix_A<='0;
                // addr_matrix_B<=ARRAY_SIZE; this and incrementing the address were a simple workaround
                addr_matrix_B<=2*ARRAY_SIZE-1'b1;

                slide_counter<='0;
                
            end
            WEIGHT_LOAD: begin
                busy          <= 1'b1;
                weight_load_en<= 1'b1;
                // if(load_counter < ARRAY_SIZE) begin
                    for(int r=0; r<ARRAY_SIZE; r++) begin
                        local_buffer[r][load_counter] <= MATRIX_A_COL[(r+1)*DATA_WIDTH-1 -: DATA_WIDTH];
                        {test_shifter3,test_shifter4} <= MATRIX_A_COL;
                    end
                
                // {local_buffer[1][load_counter],local_buffer[0][load_counter]} <= MATRIX_A_COL;
                if (load_counter < ARRAY_SIZE-1)
                    addr_matrix_A <= addr_matrix_A + 1'b1;
                // addr_matrix_B<=addr_matrix_B+1'b1;
                addr_matrix_B<=addr_matrix_B-1'b1;
                load_counter <= load_counter + 1'b1;

                slide_counter <= '0;
            end
            ACTIVATION_LOAD: begin
                weight_load_en <= '0;
                // addr_matrix_A<=addr_matrix_A+1'b1;
                // for(int r=0; r<ARRAY_SIZE; r++) begin
                //         local_buffer[r][load_counter] <= MATRIX_A_COL[(r+1)*DATA_WIDTH-1 -: DATA_WIDTH];
                //         {test_shifter3,test_shifter4} <= MATRIX_A_COL;
                //     end
                compute_en<='1;
            end
            COMPUTE: begin
                if(slide_counter<(2*ARRAY_SIZE-1))
                    slide_counter<=slide_counter+1'b1;
                cycle_counter <= cycle_counter + 1'b1;
                // case (cycle_counter)
                //     'd3: begin // cycle 1 for ARRAY_SIZE=2
                //         debug <= PE_ARRAY_output_B[ARRAY_SIZE-1][0];
                //         result_output[0] <= PE_ARRAY_output_B[ARRAY_SIZE-1][0]; // [0,0]
                //     end
                //     'd4: begin // cycle 2 for ARRAY_SIZE=2
                //         debug <= PE_ARRAY_output_B[ARRAY_SIZE-1][1];
                //         result_output[1] <= PE_ARRAY_output_B[ARRAY_SIZE-1][1]; // [0,1]
                //         result_output[2] <= PE_ARRAY_output_B[ARRAY_SIZE-1][0]; // [1,0]
                //     end
                //     'd5: begin // cycle 3 for ARRAY_SIZE=2
                //         debug <= PE_ARRAY_output_B[ARRAY_SIZE-1][1];
                //         result_output[3] <= PE_ARRAY_output_B[ARRAY_SIZE-1][1]; // [1,1]
                //     end
                // endcase
                // if (cycle_counter >= (2 * ARRAY_SIZE - 1)) begin
                if (cycle_counter >= (ARRAY_SIZE + 1)) begin
                    // int offset = cycle_counter - (2 * ARRAY_SIZE - 1);
                    int offset = cycle_counter - (ARRAY_SIZE + 1);
                    
                    // For each column, check if results are emerging
                    for (int col = 0; col < ARRAY_SIZE; col++) begin
                        if (offset >= col && offset < (col + ARRAY_SIZE)) begin
                            int row = offset - col;
                            int linear_index = row * ARRAY_SIZE + col;
                            result_output[linear_index] <= PE_ARRAY_output_B[ARRAY_SIZE-1][col];
                            debug <= PE_ARRAY_output_B[ARRAY_SIZE-1][col];
                        end
                    end
                end
                
                if (cycle_counter >= (2*ARRAY_SIZE)) compute_en<=1'b0;
            end
            // COMPUTE_STORE_OVERLAP: begin
            //     compute_en<='0;
            //     for (int j = 0; j < ARRAY_SIZE; j++) begin
            //         result_output[j] <= PE_ARRAY_output_B[ARRAY_SIZE-1][j];
            //     end
            // end
            DONE: begin
                done<='1;
                busy<='0;
            end
        endcase
    end
end
logic signed [7:0] debug_buf_00, debug_buf_01, debug_buf_10, debug_buf_11;

assign debug_buf_00 = local_buffer[0][0]; // Should be 1
assign debug_buf_01 = local_buffer[0][1]; 
assign debug_buf_10 = local_buffer[1][0];   
assign debug_buf_11 = local_buffer[1][1]; 
// Add more debug signals to see what's happening
logic signed [7:0] debug_pe_00, debug_pe_01, debug_pe_10, debug_pe_11;


assign debug_pe_00 = PE_ARRAY_output_B[0][0];
assign debug_pe_01 = PE_ARRAY_output_B[0][1]; 
assign debug_pe_10 = PE_ARRAY_output_B[1][0];   
assign debug_pe_11 = PE_ARRAY_output_B[1][1];
function integer clogb2 (input integer bit_depth);
		begin
			for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
		end
	endfunction
endmodule
