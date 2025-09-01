`timescale 1ns / 1ps
module tb_axi_matrix_multiplier;
    // Parameters
    parameter ARRAY_SIZE = 5;
    parameter DATA_WIDTH = 8;
    parameter C_S00_AXIS_TDATA_WIDTH = 32;
    parameter C_M00_AXIS_TDATA_WIDTH = 32;
    // parameter C_M00_AXIS_START_COUNT = ARRAY_SIZE*ARRAY_SIZE;
//    parameter C_S_AXI_INTR_DATA_WIDTH = 32;
//    parameter C_S_AXI_INTR_ADDR_WIDTH = 5;
//    parameter C_NUM_OF_INTR = 1;
//    parameter C_INTR_SENSITIVITY = 32'hFFFFFFFF;
//    parameter C_INTR_ACTIVE_STATE = 32'hFFFFFFFF;
//    parameter C_IRQ_SENSITIVITY = 1;
//    parameter C_IRQ_ACTIVE_STATE = 1;
    
    // Clock and reset signals
    logic s00_axis_aclk = 0;
    logic s00_axis_aresetn = 0;
    logic m00_axis_aclk = 0;
    logic m00_axis_aresetn = 0;
//    logic s_axi_intr_aclk = 0;
//    logic s_axi_intr_aresetn = 0;
    
    // S00_AXIS interface signals (the one we'll use)
    logic [C_S00_AXIS_TDATA_WIDTH-1:0] s00_axis_tdata;
    logic s00_axis_tvalid = 0;
    logic s00_axis_tlast = 0;
    logic [(C_S00_AXIS_TDATA_WIDTH/8)-1:0] s00_axis_tstrb = 4'hF;
    wire s00_axis_tready;
    
    // M00_AXIS interface signals (unused but need to be connected)
    wire m00_axis_tvalid;
    wire [C_M00_AXIS_TDATA_WIDTH-1:0] m00_axis_tdata;
    wire [(C_M00_AXIS_TDATA_WIDTH/8)-1:0] m00_axis_tstrb;
    wire m00_axis_tlast;
    logic m00_axis_tready=0; //= 1; // Always ready to receive output
    
//    // S_AXI_INTR interface signals (unused but need to be connected)
//    logic [C_S_AXI_INTR_ADDR_WIDTH-1:0] s_axi_intr_awaddr = 0;
//    logic [2:0] s_axi_intr_awprot = 0;
//    logic s_axi_intr_awvalid = 0;
//    wire s_axi_intr_awready;
//    logic [C_S_AXI_INTR_DATA_WIDTH-1:0] s_axi_intr_wdata = 0;
//    logic [(C_S_AXI_INTR_DATA_WIDTH/8)-1:0] s_axi_intr_wstrb = 0;
//    logic s_axi_intr_wvalid = 0;
//    wire s_axi_intr_wready;
//    wire [1:0] s_axi_intr_bresp;
//    wire s_axi_intr_bvalid;
//    logic s_axi_intr_bready = 1;
//    logic [C_S_AXI_INTR_ADDR_WIDTH-1:0] s_axi_intr_araddr = 0;
//    logic [2:0] s_axi_intr_arprot = 0;
//    logic s_axi_intr_arvalid = 0;
//    wire s_axi_intr_arready;
//    wire [C_S_AXI_INTR_DATA_WIDTH-1:0] s_axi_intr_rdata;
//    wire [1:0] s_axi_intr_rresp;
//    wire s_axi_intr_rvalid;
//    logic s_axi_intr_rready = 1;
//    wire irq;
    
    // Clock generation
    always #5 s00_axis_aclk = ~s00_axis_aclk;
    always #5 m00_axis_aclk = ~m00_axis_aclk;
//    always #5 s_axi_intr_aclk = ~s_axi_intr_aclk;
    
    // DUT instantiation
    AXI_MATRIX_MULTIPLIER #(
        .ARRAY_SIZE(ARRAY_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
        .C_M00_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH)
        // .C_M00_AXIS_START_COUNT(C_M00_AXIS_START_COUNT)
//        .C_S_AXI_INTR_DATA_WIDTH(C_S_AXI_INTR_DATA_WIDTH),
//        .C_S_AXI_INTR_ADDR_WIDTH(C_S_AXI_INTR_ADDR_WIDTH),
//        .C_NUM_OF_INTR(C_NUM_OF_INTR),
//        .C_INTR_SENSITIVITY(C_INTR_SENSITIVITY),
//        .C_INTR_ACTIVE_STATE(C_INTR_ACTIVE_STATE),
//        .C_IRQ_SENSITIVITY(C_IRQ_SENSITIVITY),
//        .C_IRQ_ACTIVE_STATE(C_IRQ_ACTIVE_STATE)
    ) dut (
        // S00_AXIS interface
        .s00_axis_aclk(s00_axis_aclk),
        .s00_axis_aresetn(s00_axis_aresetn),
        .s00_axis_tready(s00_axis_tready),
        .s00_axis_tdata(s00_axis_tdata),
        .s00_axis_tstrb(s00_axis_tstrb),
        .s00_axis_tlast(s00_axis_tlast),
        .s00_axis_tvalid(s00_axis_tvalid),
        
        // M00_AXIS interface
        .m00_axis_aclk(m00_axis_aclk),
        .m00_axis_aresetn(m00_axis_aresetn),
        .m00_axis_tvalid(m00_axis_tvalid),
        .m00_axis_tdata(m00_axis_tdata),
        .m00_axis_tstrb(m00_axis_tstrb),
        .m00_axis_tlast(m00_axis_tlast),
        .m00_axis_tready(m00_axis_tready)
        
//        // S_AXI_INTR interface
//        .s_axi_intr_aclk(s_axi_intr_aclk),
//        .s_axi_intr_aresetn(s_axi_intr_aresetn),
//        .s_axi_intr_awaddr(s_axi_intr_awaddr),
//        .s_axi_intr_awprot(s_axi_intr_awprot),
//        .s_axi_intr_awvalid(s_axi_intr_awvalid),
//        .s_axi_intr_awready(s_axi_intr_awready),
//        .s_axi_intr_wdata(s_axi_intr_wdata),
//        .s_axi_intr_wstrb(s_axi_intr_wstrb),
//        .s_axi_intr_wvalid(s_axi_intr_wvalid),
//        .s_axi_intr_wready(s_axi_intr_wready),
//        .s_axi_intr_bresp(s_axi_intr_bresp),
//        .s_axi_intr_bvalid(s_axi_intr_bvalid),
//        .s_axi_intr_bready(s_axi_intr_bready),
//        .s_axi_intr_araddr(s_axi_intr_araddr),
//        .s_axi_intr_arprot(s_axi_intr_arprot),
//        .s_axi_intr_arvalid(s_axi_intr_arvalid),
//        .s_axi_intr_arready(s_axi_intr_arready),
//        .s_axi_intr_rdata(s_axi_intr_rdata),
//        .s_axi_intr_rresp(s_axi_intr_rresp),
//        .s_axi_intr_rvalid(s_axi_intr_rvalid),
//        .s_axi_intr_rready(s_axi_intr_rready),
//        .irq(irq)
    );
//     task enable_interrupts();
//     begin
//         $display("Time %0t: Enabling interrupts", $time);
        
//         // Enable Global Interrupt Enable (address 0x0)
//         @(posedge s_axi_intr_aclk);
//         s_axi_intr_awaddr = 5'h00;  // Address 0
//         s_axi_intr_awvalid = 1'b1;
//         s_axi_intr_wdata = 32'h00000001;  // Enable bit 0
//         s_axi_intr_wstrb = 4'hF;
//         s_axi_intr_wvalid = 1'b1;
        
//         // Wait for ready signals
//         wait(s_axi_intr_awready && s_axi_intr_wready);
//         @(posedge s_axi_intr_aclk);
        
//         s_axi_intr_awvalid = 1'b0;
//         s_axi_intr_wvalid = 1'b0;
        
//         // Wait for response
//         wait(s_axi_intr_bvalid);
//         @(posedge s_axi_intr_aclk);
        
//         // Enable Interrupt 0 (address 0x4)
//         @(posedge s_axi_intr_aclk);
//         s_axi_intr_awaddr = 5'h04;  // Address 4
//         s_axi_intr_awvalid = 1'b1;
//         s_axi_intr_wdata = 32'h00000001;  // Enable interrupt 0
//         s_axi_intr_wstrb = 4'hF;
//         s_axi_intr_wvalid = 1'b1;
        
//         // Wait for ready signals
//         wait(s_axi_intr_awready && s_axi_intr_wready);
//         @(posedge s_axi_intr_aclk);
        
//         s_axi_intr_awvalid = 1'b0;
//         s_axi_intr_wvalid = 1'b0;
        
//         // Wait for response
//         wait(s_axi_intr_bvalid);
//         @(posedge s_axi_intr_aclk);
        
//         $display("Time %0t: Interrupts enabled", $time);
//     end
// endtask

// Add interrupt monitoring
//    always @(posedge s_axi_intr_aclk) begin
//        if (irq) begin
//            $display("Time %0t: IRQ asserted!", $time);
//        end
//    end
    // Test stimulus
    initial begin
        $dumpfile("sim/axi_matrix_multiplier_test.vcd");
        $dumpvars(0, tb_axi_matrix_multiplier);
        
        // Initialize data
        s00_axis_tdata = '0;
        
        // Reset all interfaces
        s00_axis_aresetn = 0;
        m00_axis_aresetn = 0;
//        s_axi_intr_aresetn = 0;
        #50;
        s00_axis_aresetn = 1;
        m00_axis_aresetn = 1;
//        s_axi_intr_aresetn = 1;
        
        #20;
        
        $display("Starting matrix multiplication test at time %0t", $time);
        
        // Send 8 data words representing matrix elements
        // Matrix A (2x2): [1,2; 3,4] and Matrix B (2x2): [5,6; 7,8]
        // Data format: each 32-bit word contains matrix elements
        for(int j = 0; j < 2; j++) begin
            for(int i = 0; i < 50; i++) begin //32 //18
                // Setup data - simple test pattern
                case(j)
                    0: begin // First iteration: [1,2;3,4] * [7,8;5,6]
                        case(i)
                            0: s00_axis_tdata = 32'h01; // A[0,0]
                            1: s00_axis_tdata = 32'h02; // A[0,1]
                            2: s00_axis_tdata = 32'h03; // A[1,0]
                            3: s00_axis_tdata = 32'h04; // A[1,1]
                            4: s00_axis_tdata = 32'h07; // B[0,0]
                            5: s00_axis_tdata = 32'h08; // B[0,1]
                            6: s00_axis_tdata = 32'h05; // B[1,0]
                            7: s00_axis_tdata = 32'h06; // B[1,1]
                           8: s00_axis_tdata = 32'h01; // A[0,0]
                           9: s00_axis_tdata = 32'h02; // A[0,1]
                           10: s00_axis_tdata = 32'h03; // A[1,0]
                           11: s00_axis_tdata = 32'h04; // A[1,1]
                           12: s00_axis_tdata = 32'h07; // B[0,0]
                           13: s00_axis_tdata = 32'h08; // B[0,1]
                           14: s00_axis_tdata = 32'h05; // B[1,0]
                           15: s00_axis_tdata = 32'h06; // B[1,1]
                           16: s00_axis_tdata = 32'h01; // A[0,0]
                           17: s00_axis_tdata = 32'h02; // A[0,1]
                            18: s00_axis_tdata = 32'h03; // A[1,0]
                            19: s00_axis_tdata = 32'h04; // A[1,1]
                            20: s00_axis_tdata = 32'h05; // B[0,0]
                            21: s00_axis_tdata = 32'h06; // B[0,1]
                            22: s00_axis_tdata = 32'h07; // B[1,0]
                            23: s00_axis_tdata = 32'h08; // B[1,1]
                           24: s00_axis_tdata = 32'h01; // A[0,0]
                           25: s00_axis_tdata = 32'h02; // A[0,1]
                           26: s00_axis_tdata = 32'h03; // A[1,0]
                           27: s00_axis_tdata = 32'h04; // A[1,1]
                           28: s00_axis_tdata = 32'h05; // B[0,0]
                           29: s00_axis_tdata = 32'h06; // B[0,1]
                           30: s00_axis_tdata = 32'h07; // B[1,0]
                           31: s00_axis_tdata = 32'h08; // B[1,1]
                           32: s00_axis_tdata = 32'h01; // A[0,0]
                            33: s00_axis_tdata = 32'h02; // A[0,1]
                            34: s00_axis_tdata = 32'h03; // A[1,0]
                            35: s00_axis_tdata = 32'h04; // A[1,1]
                            36: s00_axis_tdata = 32'h07; // B[0,0]
                            37: s00_axis_tdata = 32'h08; // B[0,1]
                            38: s00_axis_tdata = 32'h05; // B[1,0]
                            39: s00_axis_tdata = 32'h06; // B[1,1]
                           40: s00_axis_tdata = 32'h01; // A[0,0]
                           41: s00_axis_tdata = 32'h02; // A[0,1]
                           42: s00_axis_tdata = 32'h03; // A[1,0]
                           43: s00_axis_tdata = 32'h04; // A[1,1]
                           44: s00_axis_tdata = 32'h07; // B[0,0]
                           45: s00_axis_tdata = 32'h08; // B[0,1]
                           46: s00_axis_tdata = 32'h05; // B[1,0]
                           47: s00_axis_tdata = 32'h06; // B[1,1]
                           48: s00_axis_tdata = 32'h01; // A[0,0]
                           49: s00_axis_tdata = 32'h02; // A[0,1]
                        endcase
                    end
                    1: begin // Second iteration: [2,3;4,5] * [8,9;6,7]
                        case(i)
                            0: s00_axis_tdata = 32'h03;
                            1: s00_axis_tdata = 32'h04;
                            2: s00_axis_tdata = 32'h05;
                            3: s00_axis_tdata = 32'h06;
                            4: s00_axis_tdata = 32'h09;
                            5: s00_axis_tdata = 32'h0A;
                            6: s00_axis_tdata = 32'h07;
                            7: s00_axis_tdata = 32'h08;
                           8: s00_axis_tdata = 32'h01; // A[0,0]
                           9: s00_axis_tdata = 32'h02; // A[0,1]
                           10: s00_axis_tdata = 32'h03; // A[1,0]
                           11: s00_axis_tdata = 32'h04; // A[1,1]
                           12: s00_axis_tdata = 32'h05; // B[0,0]
                           13: s00_axis_tdata = 32'h06; // B[0,1]
                           14: s00_axis_tdata = 32'h07; // B[1,0]
                           15: s00_axis_tdata = 32'h08; // B[1,1]
                           16: s00_axis_tdata = 32'h01; // A[0,0]
                            17: s00_axis_tdata = 32'h02; // A[0,1]
                            18: s00_axis_tdata = 32'h03; // A[1,0]
                            19: s00_axis_tdata = 32'h04; // A[1,1]
                            20: s00_axis_tdata = 32'h05; // B[0,0]
                            21: s00_axis_tdata = 32'h06; // B[0,1]
                            22: s00_axis_tdata = 32'h07; // B[1,0]
                            23: s00_axis_tdata = 32'h08; // B[1,1]
                           24: s00_axis_tdata = 32'h01; // A[0,0]
                           25: s00_axis_tdata = 32'h02; // A[0,1]
                           26: s00_axis_tdata = 32'h03; // A[1,0]
                           27: s00_axis_tdata = 32'h04; // A[1,1]
                           28: s00_axis_tdata = 32'h05; // B[0,0]
                           29: s00_axis_tdata = 32'h06; // B[0,1]
                           30: s00_axis_tdata = 32'h07; // B[1,0]
                           31: s00_axis_tdata = 32'h08; // B[1,1]
                           32: s00_axis_tdata = 32'h01; // A[0,0]
                            33: s00_axis_tdata = 32'h02; // A[0,1]
                            34: s00_axis_tdata = 32'h03; // A[1,0]
                            35: s00_axis_tdata = 32'h04; // A[1,1]
                            36: s00_axis_tdata = 32'h07; // B[0,0]
                            37: s00_axis_tdata = 32'h08; // B[0,1]
                            38: s00_axis_tdata = 32'h05; // B[1,0]
                            39: s00_axis_tdata = 32'h06; // B[1,1]
                           40: s00_axis_tdata = 32'h01; // A[0,0]
                           41: s00_axis_tdata = 32'h02; // A[0,1]
                           42: s00_axis_tdata = 32'h03; // A[1,0]
                           43: s00_axis_tdata = 32'h04; // A[1,1]
                           44: s00_axis_tdata = 32'h07; // B[0,0]
                           45: s00_axis_tdata = 32'h08; // B[0,1]
                           46: s00_axis_tdata = 32'h05; // B[1,0]
                           47: s00_axis_tdata = 32'h06; // B[1,1]
                           48: s00_axis_tdata = 32'h01; // A[0,0]
                           49: s00_axis_tdata = 32'h02; // A[0,1]
                        endcase
                    end
                    2: begin // Third iteration: [3,4;5,6] * [9,10;7,8]
                        case(i)
                            0: s00_axis_tdata = 32'h03;
                            1: s00_axis_tdata = 32'h04;
                            2: s00_axis_tdata = 32'h05;
                            3: s00_axis_tdata = 32'h06;
                            4: s00_axis_tdata = 32'h09;
                            5: s00_axis_tdata = 32'h0A;
                            6: s00_axis_tdata = 32'h07;
                            7: s00_axis_tdata = 32'h08;
//                            8: s00_axis_tdata = 32'h01; // A[0,0]
//                            9: s00_axis_tdata = 32'h02; // A[0,1]
//                            10: s00_axis_tdata = 32'h03; // A[1,0]
//                            11: s00_axis_tdata = 32'h04; // A[1,1]
//                            12: s00_axis_tdata = 32'h07; // B[0,0]
//                            13: s00_axis_tdata = 32'h08; // B[0,1]
//                            14: s00_axis_tdata = 32'h05; // B[1,0]
//                            15: s00_axis_tdata = 32'h06; // B[1,1]
//                            16: s00_axis_tdata = 32'h01; // A[0,0]
//                            17: s00_axis_tdata = 32'h02; // A[0,1]
                        endcase
                    end
                endcase
                
                if(i == 49) s00_axis_tlast = 1;
                
                // Assert valid and wait for handshake
                s00_axis_tvalid = 1;
                
                // Wait for both valid and ready to be high (successful handshake)
                do begin
                    @(posedge s00_axis_aclk);
                end while(!(s00_axis_tvalid && s00_axis_tready));
                
                $display("Sent data[%0d] = %h at time %0t", i, s00_axis_tdata, $time);
                #10
                // Deassert signals after successful transfer
                s00_axis_tlast = 0;
            end
            
            s00_axis_tvalid = 0;
            $display("All input data sent. Waiting for systolic array to complete...");
            
            // Wait for systolic array to complete computation
            #200;
            
            // Monitor output interface
            // if (m00_axis_tvalid) begin
            //     $display("Output available: %h at time %0t", m00_axis_tdata, $time);
            // end
            $display("Making master output ready at time %0t", $time);
            // m00_axis_tready = 1;
            
            // Wait longer to see if output appears
            // #300;
            
            // Monitor output interface
            
                $display("Cycle %0d: Asserting tready at time %0t", j, $time);
                m00_axis_tready = 1;
                
                // Wait for tlast to be asserted (indicating end of packet)
                while(!m00_axis_tlast) begin
                    @(posedge m00_axis_aclk);
                end
                
                // Wait one more clock edge to capture the tlast transfer
                @(posedge m00_axis_aclk);
                
                $display("Cycle %0d: Deasserting tready at time %0t", j, $time);
                m00_axis_tready = 0;
                
                // Wait 200ns before next cycle
                #200;
        end
        // Check if interrupt is generated
//        if (irq) begin
//            $display("Interrupt generated at time %0t", $time);
//        end
        
        #500;
        $display("Test completed at time %0t", $time);
        $finish;
    end
    // always @(posedge m00_axis_aclk) begin
    //     if (m00_axis_tvalid && m00_axis_tready) begin
    //         $display("Output transferred: %h, tlast: %b at time %0t", 
    //                 m00_axis_tdata, m00_axis_tlast, $time);
    //     end
    // end
    always @(posedge m00_axis_aclk) begin
        if (m00_axis_tvalid && !m00_axis_tready) begin
            $display("Output BLOCKED (tvalid=1, tready=0): %h at time %0t", 
                    m00_axis_tdata, $time);
        end
        if (m00_axis_tvalid && m00_axis_tready) begin
            $display("Output transferred: %h, tlast: %b at time %0t", 
                    m00_axis_tdata, m00_axis_tlast, $time);
        end
    end
    // Monitor systolic array internal signals (if accessible)
    initial begin
        #1;
        forever begin
            @(posedge s00_axis_aclk);
            // Monitor start signal to systolic array
            if (dut.start_systolic) begin
                $display("Systolic array started at time %0t", $time);
            end
        end
    end
    
endmodule