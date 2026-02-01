// `define DEBUG

module spi_master (
    input wire i_clk,
    input wire i_rst_n,
    input wire [7:0] i_spi_clk_div,

    // Trigger / Flag
    input wire i_en,
    output reg o_done,

    input wire [7:0] i_tx_byte,
    output reg [7:0] o_rx_byte,

    // SPI interface
    output reg o_spi_sck,
    output reg o_spi_mosi,      // Bit to transmit
    input wire i_spi_miso      // Bit received
);

    localparam STATE_IDLE = 2'd0;
    localparam STATE_TRANSFER = 2'd1;

    reg [1:0] r_state;
    reg [7:0] r_tx_shift;
    reg [7:0] r_rx_shift;
    reg [7:0] r_clk_div_cnt;
    reg [3:0] r_bit_cnt;

    wire [7:0] w_effective_div = (i_spi_clk_div == 8'd0) ? 8'd1 : i_spi_clk_div;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            `ifdef DEBUG
                $display("[SPI] Reset");
            `endif

            r_state <= STATE_IDLE;
            o_done <= 1'b0;
            r_tx_shift <= 8'h00;
            r_rx_shift <= 8'h00;
            r_clk_div_cnt <= 8'h00;
            r_bit_cnt <= 4'd0;
            o_spi_sck <= 1'b0;
            o_spi_mosi <= 1'b0;
        end

        else begin
            o_done <= 1'b0;

            case (r_state)
                STATE_IDLE: begin
                    o_done <= 1'b0;
                    o_spi_sck <= 1'b0;
                    o_spi_mosi <= 1'b0;
                    r_clk_div_cnt <= 8'h00;
                    r_bit_cnt <= 4'd0;

                    if (i_en) begin
                        r_tx_shift <= i_tx_byte;
                        r_rx_shift <= 8'h00;
                        o_spi_mosi <= i_tx_byte[7];
                        r_state <= STATE_TRANSFER;
                    end else begin
                        r_state <= STATE_IDLE; // Stay
                    end
                end

                STATE_TRANSFER: begin
                    if (r_clk_div_cnt == (w_effective_div - 1)) begin
                        r_clk_div_cnt <= 8'h00;

                        if (o_spi_sck == 1'b0) begin
                            // Rising Edge: Sample data from MISO 
                            o_spi_sck <= 1'b1;
                            r_rx_shift <= {r_rx_shift[6:0], i_spi_miso};

                            if (r_bit_cnt == 4'd7) begin
                                o_rx_byte <= {r_rx_shift[6:0], i_spi_miso};
                            end else begin
                                o_rx_byte <= o_rx_byte; // Stay
                            end

                            r_bit_cnt <= r_bit_cnt + 1'b1;
                        end else begin
                            // Falling Edge: Shift data to MOSI
                            o_spi_sck <= 1'b0;

                            if (r_bit_cnt == 4'd8) begin
                                o_done <= 1'b1;
                                r_state <= STATE_IDLE;
                            end else begin
                                r_tx_shift <= {r_tx_shift[6:0], 1'b0};
                                o_spi_mosi <= r_tx_shift[6];
                            end
                        end
                    end else begin
                        r_clk_div_cnt <= r_clk_div_cnt + 1'b1;
                        o_done <= 1'b0;
                    end
                end
                default: begin
                    r_state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule