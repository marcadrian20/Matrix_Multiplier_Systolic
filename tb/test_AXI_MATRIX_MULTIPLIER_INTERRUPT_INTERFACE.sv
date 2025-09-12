`timescale 1ns / 1ps

module test_AXI_MATRIX_MULTIPLIER_INTERRUPT_INTERFACE();

    // Parameters
    parameter integer C_S_AXI_DATA_WIDTH = 32;
    parameter integer C_S_AXI_ADDR_WIDTH = 5;
    parameter integer C_NUM_OF_INTR = 1;
    
    // Clock and Reset
    reg S_AXI_ACLK;
    reg S_AXI_ARESETN;
    
    // AXI4-Lite signals
    reg [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR;
    reg [2:0] S_AXI_AWPROT;
    reg S_AXI_AWVALID;
    wire S_AXI_AWREADY;
    reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA;
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB;
    reg S_AXI_WVALID;
    wire S_AXI_WREADY;
    wire [1:0] S_AXI_BRESP;
    wire S_AXI_BVALID;
    reg S_AXI_BREADY;
    reg [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR;
    reg [2:0] S_AXI_ARPROT;
    reg S_AXI_ARVALID;
    wire S_AXI_ARREADY;
    wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA;
    wire [1:0] S_AXI_RRESP;
    wire S_AXI_RVALID;
    reg S_AXI_RREADY;
    
    // User signals
    reg results_ready;
    wire irq;
    
    // Instantiate DUT
    AXI_MATRIX_MULTIPLIER_INTERRUPT_INTERFACE #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
        .C_NUM_OF_INTR(C_NUM_OF_INTR)
    ) dut (
        .results_ready(results_ready),
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWPROT(S_AXI_AWPROT),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARPROT(S_AXI_ARPROT),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),
        .irq(irq)
    );
    
    // Clock generation
    initial begin
        S_AXI_ACLK = 0;
        forever #5 S_AXI_ACLK = ~S_AXI_ACLK; // 100MHz clock
    end
    
    // Timeout watchdog
    initial begin
        #10000; // 10us timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    // AXI Write Task with timeout
    task axi_write;
        input [C_S_AXI_ADDR_WIDTH-1:0] addr;
        input [C_S_AXI_DATA_WIDTH-1:0] data;
        integer timeout_counter;
        begin
            $display("Attempting AXI write to addr=0x%02x, data=0x%08x", addr, data);
            timeout_counter = 0;
            
            @(posedge S_AXI_ACLK);
            S_AXI_AWADDR = addr;
            S_AXI_AWVALID = 1'b1;
            S_AXI_WDATA = data;
            S_AXI_WVALID = 1'b1;
            S_AXI_WSTRB = 4'hF;
            S_AXI_BREADY = 1'b1;
            
            // Wait for both AWREADY and WREADY with timeout
            while (!(S_AXI_AWREADY && S_AXI_WREADY) && timeout_counter < 100) begin
                @(posedge S_AXI_ACLK);
                timeout_counter = timeout_counter + 1;
            end
            
            if (timeout_counter >= 100) begin
                $display("ERROR: AXI write address/data timeout - AWREADY=%b, WREADY=%b", S_AXI_AWREADY, S_AXI_WREADY);
                S_AXI_AWVALID = 1'b0;
                S_AXI_WVALID = 1'b0;
                S_AXI_BREADY = 1'b0;
            end else begin
                @(posedge S_AXI_ACLK);
                S_AXI_AWVALID = 1'b0;
                S_AXI_WVALID = 1'b0;
                
                // Wait for write response with timeout
                timeout_counter = 0;
                while (!S_AXI_BVALID && timeout_counter < 100) begin
                    @(posedge S_AXI_ACLK);
                    timeout_counter = timeout_counter + 1;
                end
                
                if (timeout_counter >= 100) begin
                    $display("ERROR: AXI write response timeout - BVALID=%b", S_AXI_BVALID);
                    S_AXI_BREADY = 1'b0;
                end else begin
                    @(posedge S_AXI_ACLK);
                    S_AXI_BREADY = 1'b0;
                    $display("AXI write completed successfully");
                end
            end
        end
    endtask
    
    // AXI Read Task with timeout
    task axi_read;
        input [C_S_AXI_ADDR_WIDTH-1:0] addr;
        output [C_S_AXI_DATA_WIDTH-1:0] data;
        integer timeout_counter;
        begin
            $display("Attempting AXI read from addr=0x%02x", addr);
            timeout_counter = 0;
            data = 32'h0;
            
            @(posedge S_AXI_ACLK);
            S_AXI_ARADDR = addr;
            S_AXI_ARVALID = 1'b1;
            S_AXI_RREADY = 1'b1;
            
            // Wait for ARREADY with timeout
            while (!S_AXI_ARREADY && timeout_counter < 100) begin
                @(posedge S_AXI_ACLK);
                timeout_counter = timeout_counter + 1;
            end
            
            if (timeout_counter >= 100) begin
                $display("ERROR: AXI read address timeout - ARREADY=%b", S_AXI_ARREADY);
                S_AXI_ARVALID = 1'b0;
                S_AXI_RREADY = 1'b0;
            end else begin
                @(posedge S_AXI_ACLK);
                S_AXI_ARVALID = 1'b0;
                
                // Wait for read data with timeout
                timeout_counter = 0;
                while (!S_AXI_RVALID && timeout_counter < 100) begin
                    @(posedge S_AXI_ACLK);
                    timeout_counter = timeout_counter + 1;
                end
                
                if (timeout_counter >= 100) begin
                    $display("ERROR: AXI read data timeout - RVALID=%b", S_AXI_RVALID);
                    S_AXI_RREADY = 1'b0;
                end else begin
                    data = S_AXI_RDATA;
                    @(posedge S_AXI_ACLK);
                    S_AXI_RREADY = 1'b0;
                    $display("AXI read completed: data=0x%08x", data);
                end
            end
        end
    endtask
    
    // Test stimulus
    reg [31:0] read_data;
    
    initial begin
        // Generate waveform files
        $dumpfile("interrupt_test.vcd");
        $dumpvars(0, test_AXI_MATRIX_MULTIPLIER_INTERRUPT_INTERFACE);
        
        // Initialize signals
        S_AXI_ARESETN = 1'b0;
        S_AXI_AWADDR = 0;
        S_AXI_AWPROT = 0;
        S_AXI_AWVALID = 1'b0;
        S_AXI_WDATA = 0;
        S_AXI_WSTRB = 0;
        S_AXI_WVALID = 1'b0;
        S_AXI_BREADY = 1'b0;
        S_AXI_ARADDR = 0;
        S_AXI_ARPROT = 0;
        S_AXI_ARVALID = 1'b0;
        S_AXI_RREADY = 1'b0;
        results_ready = 1'b0;
        
        // Reset sequence
        #100;
        S_AXI_ARESETN = 1'b1;
        #50;
        
        $display("Starting interrupt controller test...");
        $display("DUT ready signals: AWREADY=%b, WREADY=%b, ARREADY=%b", 
                 S_AXI_AWREADY, S_AXI_WREADY, S_AXI_ARREADY);
        
        // Test basic functionality first - just check if AXI interface responds
        $display("Test 0: Basic AXI interface check");
        #20;
        
        // Test 1: Enable global interrupt
        $display("Test 1: Enable global interrupt");
        axi_write(5'h00, 32'h00000001); // Enable global interrupt
        #50;
        
        axi_read(5'h00, read_data);
        #50;
        
        if (read_data[0] == 1'b1) 
            $display("PASS: Global interrupt enabled");
        else 
            $display("FAIL: Global interrupt not enabled, read_data=0x%08x", read_data);
        
        // Test 2: Enable interrupt 0
        $display("Test 2: Enable interrupt 0");
        axi_write(5'h04, 32'h00000001); // Enable interrupt 0
        #50;
        
        axi_read(5'h04, read_data);
        #50;
        
        if (read_data[0] == 1'b1) 
            $display("PASS: Interrupt 0 enabled");
        else 
            $display("FAIL: Interrupt 0 not enabled, read_data=0x%08x", read_data);
        
        // Test 3: Check initial IRQ state
        $display("Test 3: Check initial IRQ state");
        if (irq == 1'b0) 
            $display("PASS: IRQ initially deasserted");
        else 
            $display("INFO: IRQ initially asserted - this might be expected");
        
        // Test 4: Trigger interrupt with results_ready
        $display("Test 4: Trigger interrupt with results_ready");
        #50;
        results_ready = 1'b1;
        #20;
        results_ready = 1'b0;
        #100; // Wait longer for interrupt processing
        
        $display("IRQ state after results_ready toggle: %b", irq);
        
        // Test 5: Read all interrupt registers
        $display("Test 5: Read all interrupt registers");
        
        axi_read(5'h00, read_data); // Global interrupt enable
        $display("Global Interrupt Enable: 0x%08x", read_data);
        #20;
        
        axi_read(5'h04, read_data); // Interrupt enable
        $display("Interrupt Enable: 0x%08x", read_data);
        #20;
        
        axi_read(5'h08, read_data); // Interrupt status
        $display("Interrupt Status: 0x%08x", read_data);
        #20;
        
        axi_read(5'h0C, read_data); // Interrupt ack
        $display("Interrupt Ack: 0x%08x", read_data);
        #20;
        
        axi_read(5'h10, read_data); // Interrupt pending
        $display("Interrupt Pending: 0x%08x", read_data);
        #20;
        
        $display("Final IRQ state: %b", irq);
        
        $display("Test completed - check waveforms in interrupt_test.vcd");
        #200;
        $finish;
    end
    
    // Enhanced monitoring
    initial begin
        $display("Time | results_ready | irq | reset | AXI_AWREADY | AXI_WREADY | AXI_BVALID | AXI_ARREADY | AXI_RVALID");
        $display("----|---------------|-----|-------|-------------|------------|------------|------------|------------");
        $monitor("%4t | %13b | %3b | %5b | %11b | %10b | %10b | %10b | %10b", 
                 $time, results_ready, irq, S_AXI_ARESETN, S_AXI_AWREADY, S_AXI_WREADY, S_AXI_BVALID, S_AXI_ARREADY, S_AXI_RVALID);
    end

endmodule