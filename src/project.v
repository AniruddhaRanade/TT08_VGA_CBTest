/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [9:0] counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  //wire [9:0] moving_x = pix_x + counter;

    parameter [9:0] CIRCLE_CENTER_X = 320; 
    parameter [9:0] CIRCLE_CENTER_Y = 240; 
    parameter [9:0] CIRCLE_RADIUS = 200;   
    
    wire [9:0] moving_x = pix_x + counter;
    wire [9:0] moving_y = pix_y + (counter >> 2); 
    wire [9:0] combined = moving_x ^ moving_y;    
    
    
    wire [19:0] distance_squared = (pix_x - CIRCLE_CENTER_X) * (pix_x - CIRCLE_CENTER_X) + 
                                   (pix_y - CIRCLE_CENTER_Y) * (pix_y - CIRCLE_CENTER_Y);
    
    
    wire in_circle = (distance_squared <= (CIRCLE_RADIUS * CIRCLE_RADIUS));
    
    assign R = (video_active && in_circle) ? {moving_x[3] ^ pix_y[6], moving_y[8] | moving_x[1]} : 2'b00;
    assign R = (video_active && in_circle) ? {moving_x[9] ^ pix_y[1], combined[4] ~^ moving_y[7]} : 2'b00;
    assign R = (video_active && in_circle) ? {combined[5] | moving_x[2], pix_y[7] & moving_x[8]} : 2'b00;
    assign R = (video_active && in_circle) ? {pix_x[4] ~| moving_y[3], moving_x[5] & pix_y[0]} : 2'b00;
    
    
    assign G = (video_active && in_circle) ? {moving_x[0] ^ combined[6], moving_y[1] | pix_y[5]} : 2'b00;
    assign G = (video_active && in_circle) ? {pix_y[9] & combined[3], moving_x[7] ^ pix_y[2]} : 2'b00;
    assign G = (video_active && in_circle) ? {moving_y[2] ~^ pix_x[8], combined[1] & moving_x[4]} : 2'b00;
    assign G = (video_active && in_circle) ? {combined[7] | pix_y[6], moving_y[9] & moving_x[0]} : 2'b00;
    assign G = (video_active && in_circle) ? {moving_x[8] ^ pix_y[3], combined[2] ~| moving_y[5]} : 2'b00;
    
    
    assign B = (video_active && in_circle) ? {combined[8] & pix_y[4], moving_y[7] ~^ moving_x[6]} : 2'b00;
    assign B = (video_active && in_circle) ? {moving_x[5] | combined[0], pix_y[8] & moving_y[1]} : 2'b00;
    assign B = (video_active && in_circle) ? {pix_x[2] ~| moving_x[7], combined[9] ^ pix_y[5]} : 2'b00;
    assign B = (video_active && in_circle) ? {moving_y[3] & combined[6], moving_x[4] ~^ pix_y[0]} : 2'b00;
    assign B = (video_active && in_circle) ? {combined[5] ^ pix_y[7], moving_x[1] & moving_y[2]} : 2'b00;


  
  always @(posedge vsync) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end

endmodule
