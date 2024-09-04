/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example(
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
  
parameter [9:0] CIRCLE_CENTER_X = 320; // Center x-coordinate
parameter [9:0] CIRCLE_CENTER_Y = 240; // Center y-coordinate
parameter [9:0] CIRCLE_RADIUS = 200;   // Radius of the circle

parameter [9:0] NUMBER_2_X_MIN = 220; // Min x-coordinate for number "2"
parameter [9:0] NUMBER_2_X_MAX = 280; // Max x-coordinate for number "2"
parameter [9:0] NUMBER_2_Y_MIN = 150; // Min y-coordinate for number "2"
parameter [9:0] NUMBER_2_Y_MAX = 300; // Max y-coordinate for number "2"

parameter [9:0] NUMBER_1_X_MIN = 350; // Min x-coordinate for number "1"
parameter [9:0] NUMBER_1_X_MAX = 380; // Max x-coordinate for number "1"
parameter [9:0] NUMBER_1_Y_MIN = 150; // Min y-coordinate for number "1"
parameter [9:0] NUMBER_1_Y_MAX = 300; // Max y-coordinate for number "1"
parameter [9:0] LINE_THICKNESS = 15;   // Thickness for the vertical line

wire [3:0] moving_x = pix_x + counter;
wire [3:0] moving_y = pix_y + (counter >> 2); 
wire [3:0] combined = moving_x[3:0] ^ moving_y[3:0]; 

wire [19:0] distance_squared = (pix_x - CIRCLE_CENTER_X) * (pix_x - CIRCLE_CENTER_X) + 
                               (pix_y - CIRCLE_CENTER_Y) * (pix_y - CIRCLE_CENTER_Y);

wire in_circle = (distance_squared <= (CIRCLE_RADIUS * CIRCLE_RADIUS));

wire in_number_2 = (pix_x >= NUMBER_2_X_MIN && pix_x <= NUMBER_2_X_MAX &&
                    pix_y >= NUMBER_2_Y_MIN && pix_y <= NUMBER_2_Y_MAX) &&
                   (
                    ((pix_y >= NUMBER_2_Y_MIN) && (pix_y < NUMBER_2_Y_MIN + LINE_THICKNESS)) ||               // Top horizontal line with thickness
                    ((pix_y >= NUMBER_2_Y_MIN + 75 - (LINE_THICKNESS >> 1)) && (pix_y <= NUMBER_2_Y_MIN + 75 + (LINE_THICKNESS >> 1)) && pix_x <= NUMBER_2_X_MAX ) || // Middle horizontal line with thickness
                    ((pix_y >= NUMBER_2_Y_MAX - LINE_THICKNESS) && (pix_y <= NUMBER_2_Y_MAX)) ||              // Bottom horizontal line with thickness
                    ((pix_x >= NUMBER_2_X_MAX - 10) && (pix_y <= NUMBER_2_Y_MIN + 75)) ||                    // Top right curve of "2"
                    ((pix_y > NUMBER_2_Y_MIN + 75) && (pix_x <= NUMBER_2_X_MIN + 10))                        // Downward slope from middle left
                   );

wire in_number_1 = (pix_x >= NUMBER_1_X_MIN && pix_x <= NUMBER_1_X_MAX &&
                    pix_y >= NUMBER_1_Y_MIN && pix_y <= NUMBER_1_Y_MAX) &&
                   ((pix_x >= NUMBER_1_X_MIN + (LINE_THICKNESS >> 1)) && 
                    (pix_x <= NUMBER_1_X_MAX - (LINE_THICKNESS >> 1))); 

wire is_in_21_shape = in_circle && (in_number_2 || in_number_1);

wire [1:0] G_21 = {moving_x[0] ^ combined[3], moving_y[1] | pix_y[5]};

wire [1:0] R_bg = {pix_y[3] | combined[2], moving_y[2] ~^ pix_x[0]};
wire [1:0] G_bg = {moving_x[1] & pix_y[9], combined[1] | moving_y[1]};
wire [1:0] B_bg = {combined[0] ~| pix_y[2], moving_x[0] ^ moving_y[0]};

assign R = (video_active && in_circle) ? R_bg : 2'b00;

assign G = (video_active && is_in_21_shape) ? G_21 : 
           (video_active && in_circle) ? G_bg : 2'b00;

assign B = (video_active && in_circle) ? B_bg : 2'b00;

  
  always @(posedge vsync) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end
  
endmodule

/*
Video sync generator, used to drive a VGA monitor.
Timing from: https://en.wikipedia.org/wiki/Video_Graphics_Array
To use:
- Wire the hsync and vsync signals to top level outputs
- Add a 3-bit (or more) "rgb" output to the top level
*/

module hvsync_generator(clk, reset, hsync, vsync, display_on, hpos, vpos);

  input clk;
  input reset;
  output reg hsync, vsync;
  output display_on;
  output reg [9:0] hpos;
  output reg [9:0] vpos;

  // declarations for TV-simulator sync parameters
  // horizontal constants
  parameter H_DISPLAY       = 640; // horizontal display width
  parameter H_BACK          =  48; // horizontal left border (back porch)
  parameter H_FRONT         =  16; // horizontal right border (front porch)
  parameter H_SYNC          =  96; // horizontal sync width
  // vertical constants
  parameter V_DISPLAY       = 480; // vertical display height
  parameter V_TOP           =  33; // vertical top border
  parameter V_BOTTOM        =  10; // vertical bottom border
  parameter V_SYNC          =   2; // vertical sync # lines
  // derived constants
  parameter H_SYNC_START    = H_DISPLAY + H_FRONT;
  parameter H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
  parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  parameter V_SYNC_START    = V_DISPLAY + V_BOTTOM;
  parameter V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  wire hmaxxed = (hpos == H_MAX) || reset;	// set when hpos is maximum
  wire vmaxxed = (vpos == V_MAX) || reset;	// set when vpos is maximum
  
  // horizontal position counter
  always @(posedge clk)
  begin
    hsync <= (hpos>=H_SYNC_START && hpos<=H_SYNC_END);
    if(hmaxxed)
      hpos <= 0;
    else
      hpos <= hpos + 1;
  end

  // vertical position counter
  always @(posedge clk)
  begin
    vsync <= (vpos>=V_SYNC_START && vpos<=V_SYNC_END);
    if(hmaxxed)
      if (vmaxxed)
        vpos <= 0;
      else
        vpos <= vpos + 1;
  end
  
  // display_on is set when beam is in "safe" visible frame
  assign display_on = (hpos<H_DISPLAY) && (vpos<V_DISPLAY);

endmodule
