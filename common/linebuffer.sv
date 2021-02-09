// Project F: Linebuffer
// (C)2021 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module linebuffer #(
    parameter WIDTH=8,    // data width of each channel
    parameter LEN=640,    // length of line
    parameter SCALE=1     // scaling factor (>=1)
    ) (
    input  wire logic clk_in,    // input clock
    input  wire logic clk_out,   // output clock
    output      logic data_req,  // request input data (clk_in)
    input  wire logic en_in,     // enable input (clk_in)
    input  wire logic en_out,    // enable output (clk_out)
    input  wire logic vbi,       // start of vertical blanking (clk_out)
    input  wire logic [WIDTH-1:0] din_0,  din_1,  din_2,  // data in (clk_in)
    output      logic [WIDTH-1:0] dout_0, dout_1, dout_2  // data out (clk_out)
    );

    // output data to display
    logic [$clog2(LEN)-1:0] addr_out;        // output address (pixel counter)
    logic [$clog2(SCALE)-1:0] cnt_v, cnt_h;  // scale counters

    always_ff @(posedge clk_out) begin
        if (vbi) begin  // ensure addr and counters are reset at frame start
            addr_out <= 0;
            cnt_h <= 0;
            cnt_v <= 0;
        end else if (en_out) begin
            /* verilator lint_off WIDTH */
            if (cnt_h == SCALE-1) begin
            /* verilator lint_on WIDTH */
                cnt_h <= 0;
                if (addr_out == LEN-1) begin  // end of line
                    addr_out <= 0;
                    /* verilator lint_off WIDTH */
                    if (cnt_v == SCALE-1) begin  // end of line set
                    /* verilator lint_on WIDTH */
                        cnt_v <= 0;
                    end else cnt_v <= cnt_v + 1;
                end else addr_out <= addr_out + 1;
            end else cnt_h <= cnt_h + 1;
        end
    end

    // request new data on receipt of vbi or at end of line set
    logic get_data;  // (clk_out)
    always_comb begin
        get_data = 0;
        if (vbi) get_data = 1;
        /* verilator lint_off WIDTH */
        if (cnt_h == SCALE-1 && addr_out == LEN-1 && cnt_v == SCALE-1) begin
        /* verilator lint_on WIDTH */
            get_data = 1;
        end
    end

    // request fresh data - need to be in clk_in domain
    xd xd_req (.clk_i(clk_out), .clk_o(clk_in), .i(get_data), .o(data_req));

    // read data in
    logic [$clog2(LEN)-1:0] addr_in = 0;
    always_ff @(posedge clk_in) begin
        if (en_in) addr_in <= (addr_in == LEN-1) ? 0 : addr_in + 1;
        if (data_req) addr_in <= 0;  // reset addr_in when we request new data
    end

    // channel 0
    bram_sdp #(.WIDTH(WIDTH), .DEPTH(LEN)) ch0 (
        .clk_write(clk_in),
        .clk_read(clk_out),
        .we(en_in),
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_in(din_0),
        .data_out(dout_0)
    );

    // channel 1
    bram_sdp #(.WIDTH(WIDTH), .DEPTH(LEN)) ch1 (
        .clk_write(clk_in),
        .clk_read(clk_out),
        .we(en_in),
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_in(din_1),
        .data_out(dout_1)
    );

    // channel 2
    bram_sdp #(.WIDTH(WIDTH), .DEPTH(LEN)) ch2 (
        .clk_write(clk_in),
        .clk_read(clk_out),
        .we(en_in),
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_in(din_2),
        .data_out(dout_2)
    );
endmodule
