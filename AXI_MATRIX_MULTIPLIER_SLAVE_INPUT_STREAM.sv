`timescale 1 ns / 1 ps
module AXI_MATRIX_MULTIPLIER_SLAVE_INPUT_STREAM #
	(
		// Users to add parameters here
		parameter integer ARRAY_SIZE = 2,
		parameter integer DATA_WIDTH = 8,
		parameter integer MAX_MATRICES = 2,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here
		output logic [(DATA_WIDTH * ARRAY_SIZE) - 1 : 0] MATRIX_A_COL_FEED,
		output logic [(DATA_WIDTH * ARRAY_SIZE) - 1 : 0] MATRIX_B_ROW_FEED,
		input logic [clogb2(ARRAY_SIZE*MAX_MATRICES)-1:0]addr_matrix_A,
		input logic [clogb2(ARRAY_SIZE*MAX_MATRICES)-1:0]addr_matrix_B,
		output logic start_systolic,
		// User ports ends
		// Do not modify the ports beyond this line

		// AXI4Stream sink: Clock
		input wire  S_AXIS_ACLK,
		// AXI4Stream sink: Reset
		input wire  S_AXIS_ARESETN,
		// Ready to accept data in
		output wire  S_AXIS_TREADY,
		// Data in
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
		// Byte qualifier
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
		// Indicates boundary of last packet
		input wire  S_AXIS_TLAST,
		// Data is in valid
		input wire  S_AXIS_TVALID
	);
	// function called clogb2 that returns an integer which has the 
	// value of the ceiling of the log base 2.
	function integer clogb2 (input integer bit_depth);
	  begin
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	      bit_depth = bit_depth >> 1;
	  end
	endfunction

	// Total number of input data.
	localparam NUMBER_OF_INPUT_WORDS  =  ARRAY_SIZE * ARRAY_SIZE * MAX_MATRICES;
	// bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
	localparam bit_num  = clogb2(NUMBER_OF_INPUT_WORDS-1);
	// Define the states of state machine
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO
	parameter [1:0] IDLE = 1'b0,        // This is the initial/idle state 

	                WRITE_FIFO  = 1'b1; // In this state FIFO is written with the
	                                    // input stream data S_AXIS_TDATA 
	wire  	axis_tready;
	// State variable
	reg mst_exec_state;  
	// FIFO implementation signals
	genvar byte_index;     
	// FIFO write enable
	wire fifo_wren;
	// FIFO full flag
	reg fifo_full_flag;
	// FIFO write pointer
	reg [bit_num-1:0] write_pointer;
	// sink has accepted all the streaming data and stored in FIFO
	  reg writes_done;
	// I/O Connections assignments

	assign S_AXIS_TREADY	= axis_tready;
	// Control state machine implementation
	always @(posedge S_AXIS_ACLK) 
	begin  
	  if (!S_AXIS_ARESETN) 
	  // Synchronous reset (active low)
	    begin
	      mst_exec_state <= IDLE;
	    end  
	  else
	    case (mst_exec_state)
	      IDLE: 
	        // The sink starts accepting tdata when 
	        // there tvalid is asserted to mark the
	        // presence of valid streaming data 
	          if (S_AXIS_TVALID)
	            begin
	              mst_exec_state <= WRITE_FIFO;
	            end
	          else
	            begin
	              mst_exec_state <= IDLE;
	            end
	      WRITE_FIFO: 
	        // When the sink has accepted all the streaming input data,
	        // the interface swiches functionality to a streaming master
	        if (writes_done)
	          begin
	            mst_exec_state <= IDLE;
	          end
	        else
	          begin
	            // The sink accepts and stores tdata 
	            // into FIFO
	            mst_exec_state <= WRITE_FIFO;
	          end

	    endcase
	end
	// AXI Streaming Sink 
	// 
	// The example design sink is always ready to accept the S_AXIS_TDATA  until
	// the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
	assign axis_tready = ((mst_exec_state == WRITE_FIFO) && (write_pointer <= NUMBER_OF_INPUT_WORDS-1));

	always@(posedge S_AXIS_ACLK)
	begin
	  if(!S_AXIS_ARESETN)
	    begin
	      write_pointer <= 0;
	      writes_done <= 1'b0;
	    end  
	  else
	  	if(writes_done && !bram_processing_done)
			write_pointer<='0;
	    if (write_pointer <= NUMBER_OF_INPUT_WORDS-1)
	      begin
	        if (fifo_wren)
	          begin
	            // write pointer is incremented after every write to the FIFO
	            // when FIFO write signal is enabled.
	            write_pointer <= write_pointer + 1;
	            writes_done <= 1'b0;
	          end
	          if ((write_pointer == NUMBER_OF_INPUT_WORDS-1)|| S_AXIS_TLAST)
	            begin
	              // reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
	              // has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	              writes_done <= 1'b1;
	            end
	      end  
	end

	// FIFO write enable generation
	assign fifo_wren = S_AXIS_TVALID && axis_tready;


	reg  [C_S_AXIS_TDATA_WIDTH-1:0] stream_data_fifo [0 : NUMBER_OF_INPUT_WORDS-1];
    always @( posedge S_AXIS_ACLK )
	begin
	    if (fifo_wren)// && S_AXIS_TSTRB[byte_index])
	    begin
		    stream_data_fifo[write_pointer] <= S_AXIS_TDATA;
	    end
	end  
	localparam NUM_COL=ARRAY_SIZE;

	reg [(DATA_WIDTH*ARRAY_SIZE)-1:0] INPUT_BRAM [0:(ARRAY_SIZE*MAX_MATRICES)-1];
	logic [clogb2(NUMBER_OF_INPUT_WORDS)-1:0] fifo_read_pointer;
	logic [clogb2(ARRAY_SIZE*MAX_MATRICES)-1:0] bram_write_addr;
	logic [clogb2(ARRAY_SIZE)-1:0] bram_col_index;
	logic [(DATA_WIDTH*ARRAY_SIZE)-1:0] write_data;
	logic BRAM_WE;
	logic bram_processing_done;
	always_ff @(posedge S_AXIS_ACLK) begin
		if(!S_AXIS_ARESETN) begin
			{fifo_read_pointer,bram_write_addr,bram_col_index,write_data,BRAM_WE,start_systolic,bram_processing_done}<='0;
		end
		else begin
			start_systolic<='0;
			 if(writes_done && !bram_processing_done) begin
				BRAM_WE<=1'b1;
				{fifo_read_pointer, bram_col_index}<='0;
				bram_processing_done <= 1'b1;

        	end
			if(BRAM_WE&&fifo_read_pointer<NUMBER_OF_INPUT_WORDS) begin
				if(bram_col_index==ARRAY_SIZE-1) begin
					// INPUT_BRAM[bram_write_addr]<=write_data;
		            INPUT_BRAM[bram_write_addr] <= write_data | (stream_data_fifo[fifo_read_pointer][7:0] << (bram_col_index*DATA_WIDTH));
					bram_col_index<='0;
					bram_write_addr<=bram_write_addr+1'b1;
					write_data<='0;
				end
				else begin 
					bram_col_index<=bram_col_index+1'b1;
					write_data[bram_col_index*DATA_WIDTH+:DATA_WIDTH]<= stream_data_fifo[fifo_read_pointer][7:0];
				end
				fifo_read_pointer<=fifo_read_pointer+1'b1;
				if(fifo_read_pointer==NUMBER_OF_INPUT_WORDS-1)
				begin 
					BRAM_WE<='0;
					bram_write_addr<='0;//Eliminate for pipelining? writing to bram while processing the other matrices? #TODO do smth bout it
					start_systolic<='1;
				end
			end
			if(!writes_done) begin
				bram_processing_done <= 1'b0;
			end
		end

	end
	always_ff @(posedge S_AXIS_ACLK) begin
		if (!S_AXIS_ARESETN) begin
			// MATRIX_A_COL_FEED <= '0;
			MATRIX_B_ROW_FEED <= '0;
		end else begin 
			// MATRIX_A_COL_FEED<=INPUT_BRAM[addr_matrix_A];
			MATRIX_B_ROW_FEED<=INPUT_BRAM[addr_matrix_B];
		end
	end
	// User logic ends
		assign MATRIX_A_COL_FEED=INPUT_BRAM[addr_matrix_A];
		// assign MATRIX_B_ROW_FEED=INPUT_BRAM[addr_matrix_B];
	//#TODO pipeline the matrix a feed if needed, i can close timing at 100Mhz with enough headroom. The combinational path should be split for over 100 ig.
	//#TODO Maybe remove the xilinx template comments?
endmodule

