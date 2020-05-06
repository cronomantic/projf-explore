// Project F: Hello Arty I - Top
// (C)2020 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io/posts/hello-arty-2/

`default_nettype none
`timescale 1ns / 1ps

module top(
    input wire logic clk,
    output     logic [3:0] led
    );

    pwm pwm_led_0 (.clk, .duty(4),   .pwm_out(led[0]));
    pwm pwm_led_1 (.clk, .duty(16),  .pwm_out(led[1]));
    pwm pwm_led_2 (.clk, .duty(64),  .pwm_out(led[2]));
    pwm pwm_led_3 (.clk, .duty(255), .pwm_out(led[3]));
endmodule
