module PE#(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 16
)(
    input logic clk,
    input logic rst_n,
    input logic weight_load_en,
    input logic compute_en,
    input logic signed [DATA_WIDTH-1:0] input_A,
    input logic signed [ACC_WIDTH-1:0] input_B,
    output logic signed [DATA_WIDTH-1:0] output_A,
    output logic signed [ACC_WIDTH-1:0] output_B
);

    ////////////////////////////////////
    // This shall be a TSSA type PE
    // B is a stationary weight
    //input_b can be the weight or the propagated MAC result from above(partial sum)
    ///////////////////////////////////
    logic signed [DATA_WIDTH-1:0] A;
    logic signed [ACC_WIDTH-1:0] B;
    logic signed [ACC_WIDTH-1:0] ACCUMULATOR;
    logic signed [ACC_WIDTH-1:0] PARTIAL_SUM_INPUT;

    assign PARTIAL_SUM_INPUT=weight_load_en ? '0 : input_B;


    always_ff @(posedge clk) begin
        if(!rst_n) begin
            {A,B,ACCUMULATOR}<='0;
        end else begin
            // A<=compute_en?input_A : A;
            A<=input_A;
            if(weight_load_en)
                B<=input_B[DATA_WIDTH-1:0];  
            // B<=weight_load_en?input_B : B;
            // ACCUMULATOR<= compute_en? A*B + PARTIAL_SUM_INPUT : ACCUMULATOR;
            ACCUMULATOR<= A*B + PARTIAL_SUM_INPUT;

        end
    end

    // assign output_B=weight_load_en? B : ACCUMULATOR[7:0];
    assign output_B=weight_load_en? {{(ACC_WIDTH-DATA_WIDTH){B[DATA_WIDTH-1]}},B} : ACCUMULATOR;
    assign output_A= A;

endmodule