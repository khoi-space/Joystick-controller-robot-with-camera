`timescale 1ps/1ps

module tb_motor_controller;

    initial begin
        $dumpfile("output/motor_controller.vcd");
        $dumpvars(0,  tb_motor_controller);
    end
endmodule