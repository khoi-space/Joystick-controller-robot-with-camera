`timescale 1ps/1ps

module tb_spi_master;
    reg i_clk;
    reg i_rst_n;
    reg [7:0] i_spi_clk_div;
    reg i_en;
    reg [7:0] i_tx_byte;
    wire o_done;
    wire [7:0] o_rx_byte;
    wire o_spi_sck;
    wire o_spi_mosi;
    reg i_spi_miso;

    reg [7:0] bit_cnt;
    reg [7:0] slave_tx_data = 8'hA5;

    spi_master uut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_spi_miso(i_spi_miso),
        .i_en(i_en),
        .i_tx_byte(i_tx_byte),
        .i_spi_clk_div(i_spi_clk_div),
        .o_done(o_done),
        .o_rx_byte(o_rx_byte),
        .o_spi_mosi(o_spi_mosi),
        .o_spi_sck(o_spi_sck)
    );

    parameter CLK_PERIOD = 10;
    initial begin
        i_clk = 0;
    end

    always #(CLK_PERIOD/2) i_clk = ~i_clk;

    initial begin
        $dumpfile("spi_master.vcd");
        $dumpvars(0, tb_spi_master);
    end

    // Slave emulator (i.g. nrf24l01)
    task send_spi_byte(input [7:0] data_to_send, input [7:0] slave_reply);
        reg [7:0] captured_mosi;
        begin
            @(posedge i_clk);
            i_tx_byte = data_to_send;
            i_en = 1'b1;
            captured_mosi = 8'h00;

            @(posedge i_clk);
            i_en = 0;

            bit_cnt = 7;
            i_spi_miso = slave_reply[7];

            // Capture the MSB that is already present before the clock starts toggling
            @(posedge o_spi_sck);
            captured_mosi = {captured_mosi[6:0], o_spi_mosi};

            repeat (7) begin
                @(negedge o_spi_sck);
                i_spi_miso = slave_reply[bit_cnt - 1];
                @(posedge o_spi_sck);
                captured_mosi = {captured_mosi[6:0], o_spi_mosi};
                bit_cnt = bit_cnt - 1;
            end
            
            wait(o_done);

            // Check TX results
            if (captured_mosi !== data_to_send)
                $display("[FAIL TX] Sent: %h, Expect: %h", captured_mosi, data_to_send);
            else
                $display("[PASS TX] Sent: %h, Expect: %h", captured_mosi, data_to_send);

            // Check RX results
            if (o_rx_byte !== slave_reply)
                $display("[FAIL RX] Received: %h, Expect: %h", o_rx_byte, slave_reply);
            else
                $display("[PASS RX] Received: %h, Expect: %h", o_rx_byte, slave_reply);            
            #(CLK_PERIOD * 5);
        end
    endtask

    initial begin
        i_rst_n = 0;
        i_en = 0;
        i_tx_byte = 0;
        i_spi_miso = 0;
        i_spi_clk_div = 8'd2;

        #(CLK_PERIOD * 5);
        i_rst_n = 1;
        #(CLK_PERIOD * 5);

        $display("\nTest 1: send: 8'hA5 | receive: 8'h5A");
        send_spi_byte(8'hA5, 8'h5A);

        $display("\nTest 2: send: 8'h12 | receive: 8'hff");
        send_spi_byte(8'h12, 8'hFF);

        $display("\nTest 3: send: 8'h13 | receive: 8'h81");
        i_spi_clk_div = 8'd4;
        send_spi_byte(8'h13, 8'h81);

        $display("Finished");
        $finish;
    end
endmodule