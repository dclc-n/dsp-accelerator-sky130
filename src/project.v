`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // [7:4] Mode, [3:0] Data In (Nibble)
    output wire [7:0] uo_out,   // [7:4] Status/Done, [3:0] Result (Nibble)
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path (Checksum out)
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (1 = Output)
    input  wire       ena,      // Chip Enable
    input  wire       clk,      // Clock (SkyWater 130nm)
    input  wire       rst_n     // Active-low Reset
);

    assign uio_oe = 8'hFF;

    wire [3:0] mode_sel   = ui_in[7:4];
    wire [3:0] in_nibble  = ui_in[3:0];

    reg [7:0]  prev_sample;
    reg [7:0]  calc_out;
    reg [7:0]  checksum;
    reg        done_flag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sample <= 8'd0;
            calc_out    <= 8'd0;
            checksum    <= 8'd0;
            done_flag   <= 1'b0;
        end else if (ena) begin
            prev_sample <= {4'd0, in_nibble};
            done_flag   <= 1'b1;

            case (mode_sel)
                4'd0: begin // 2D FIR Filter
                    calc_out <= ((in_nibble * 4'd5) + (prev_sample[3:0] * 4'd2) + 8'd8) >> 2;
                end
                4'd1: begin // GEMV Dot-Product
                    calc_out <= (in_nibble * 4'd3) + 8'd7;
                end
                4'd2: begin // Spectral processing
                    calc_out <= (in_nibble * in_nibble) + 8'd1;
                end
                default: begin // Linear scaling
                    calc_out <= (in_nibble << 1) + 8'd5;
                end
            endcase

            checksum <= checksum ^ calc_out;
        end
    end

    assign uo_out  = {done_flag, 3'b000, calc_out[3:0]};
    assign uio_out = checksum;

endmodule
