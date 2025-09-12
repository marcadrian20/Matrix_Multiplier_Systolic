
`timescale 1 ns / 1 ps

	module AXI_MATRIX_MULTIPLIER #
	(
		// Users to add parameters here
        parameter ARRAY_SIZE = 8,
        // parameter INPUT_WIDTH = 32,
        parameter DATA_WIDTH = 8,
        parameter MAX_MATRICES=2,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32
		// parameter integer C_M00_AXIS_START_COUNT	= ARRAY_SIZE*ARRAY_SIZE //32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready

	);
    //Signals and ports for the systolic array
    logic [(DATA_WIDTH * ARRAY_SIZE) - 1 : 0] MATRIX_A_COL_FEED; 
    logic [(DATA_WIDTH * ARRAY_SIZE) - 1 : 0] MATRIX_B_ROW_FEED; 
    logic [clogb2(ARRAY_SIZE*MAX_MATRICES)-1:0]addr_matrix_A;
	logic [clogb2(ARRAY_SIZE*MAX_MATRICES)-1:0]addr_matrix_B;
	logic signed [(2 * DATA_WIDTH)-1 : 0] result_output [(ARRAY_SIZE*ARRAY_SIZE)-1:0];
	logic start_systolic;
	logic systolic_done;
	logic systolic_busy;
	logic results_ready;
    
// Instantiation of Axi Bus Interface S00_AXIS
	AXI_MATRIX_MULTIPLIER_SLAVE_INPUT_STREAM # ( 
	    .ARRAY_SIZE(ARRAY_SIZE),
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
    ) AXI_MATRIX_MULTIPLIER_SLAVE_INPUT_STREAM_inst (
        .MATRIX_A_COL_FEED(MATRIX_A_COL_FEED),
        .MATRIX_B_ROW_FEED(MATRIX_B_ROW_FEED),
        .addr_matrix_A(addr_matrix_A),
        .addr_matrix_B(addr_matrix_B),
		.start_systolic(start_systolic),
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid)
	);

// Instantiation of Axi Bus Interface M00_AXIS
	AXI_MATRIX_MULTIPLIER_MASTER_OUTPUT_STREAM # ( 
	    .ARRAY_SIZE(ARRAY_SIZE),
		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH)
		// .C_M_START_COUNT(C_M00_AXIS_START_COUNT)
	) AXI_MATRIX_MULTIPLIER_MASTER_OUTPUT_STREAM_inst (
		.systolic_busy(systolic_busy),
		.systolic_done(systolic_done),
		.result_output_matrix(result_output),
		.M_AXIS_ACLK(m00_axis_aclk),
		.M_AXIS_ARESETN(m00_axis_aresetn),
		.M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TSTRB(m00_axis_tstrb),
		.M_AXIS_TLAST(m00_axis_tlast),
		.M_AXIS_TREADY(m00_axis_tready)
	);


	// Systolic Array signals and instantiation 
    localparam  MATRIX_SIZE = ARRAY_SIZE*ARRAY_SIZE;
    

    Systolic_Array #(
            .ARRAY_SIZE(ARRAY_SIZE),
            .DATA_WIDTH(DATA_WIDTH)
    ) systolic_array (
            .clk(s00_axis_aclk),
            .rst_n(s00_axis_aresetn),
            .start(start_systolic),
            .done(systolic_done),
            .busy(systolic_busy),
            .MATRIX_A_COL(MATRIX_A_COL_FEED),
            .MATRIX_B_ROW(MATRIX_B_ROW_FEED),
			.addr_matrix_A(addr_matrix_A),
        	.addr_matrix_B(addr_matrix_B),
            .result_output(result_output)
        );
	// User logic ends
	function integer clogb2 (input integer bit_depth);
		begin
			for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
		end
	endfunction
	endmodule
