(* use_dsp = "yes" *)module PE(
    input logic clk,
    input logic rst_n,
    input logic weight_load_en,
    input logic compute_en,
    input logic signed [7:0] input_A,
    input logic signed [7:0] input_B,
    output logic signed [7:0] output_A,
    output logic signed [7:0] output_B
);

    ////////////////////////////////////
    // This shall be a TSSA type PE
    // B is a stationary weight
    //input_b can be the weight or the propagated MAC result from above(partial sum)
    ///////////////////////////////////
    logic signed [7:0] A, B;
    logic signed [15:0] ACCUMULATOR;
    logic signed [7:0] PARTIAL_SUM_INPUT;

    assign PARTIAL_SUM_INPUT=weight_load_en ? '0 : input_B;


    always_ff @(posedge clk) begin
        if(!rst_n) begin
            {A,B,ACCUMULATOR}<='0;
        end else begin
            // A<=compute_en?input_A : A;
            A<=input_A;
            B<=weight_load_en?input_B : B;
            // ACCUMULATOR<= compute_en? A*B + PARTIAL_SUM_INPUT : ACCUMULATOR;
            ACCUMULATOR<= A*B + PARTIAL_SUM_INPUT;

        end
    end

    assign output_B=weight_load_en? B : ACCUMULATOR[7:0];
    assign output_A= A;

endmodule