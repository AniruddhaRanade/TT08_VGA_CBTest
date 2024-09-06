/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Author: Uri Shaked
 */

`default_nettype none
`define COLOR_WHITE 3'd7

module tt_um_vga_cbtest  (
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
  reg [1:0] R;
  reg [1:0] G;
  reg [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // Configuration
  wire cfg_tile = ui_in[0];
  // wire cfg_solid_color = ui_in[1];

  // TinyVGA PMOD
  assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in[7:1], uio_in};

  hvsync_generator vga_sync_gen (
      .clk(clk),
      .reset(~rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x),
      .vpos(pix_y)
  );


  wire red_pixel_value;
  wire green_pixel_value;
  wire blue_pixel_value;
  wire [5:0] pallete_color;
  wire [5:0] color;

  wire [9:0] x = pix_x;
  wire [9:0] y = pix_y;
  wire logo_pixels = cfg_tile || (x[9:7] == 0 && y[9:7] == 0);

  bitmap_rom rom1 (
      .x(x[6:0]),
      .y(y[6:0]),
      .red_pixel(red_pixel_value),
      .green_pixel(green_pixel_value),
      .blue_pixel(blue_pixel_value)
  );

  palette palette_inst (
      .color_index(3'd7),
      .rrggbb(pallete_color)
  );

  assign color = pallete_color;

  // RGB output logic
  always @(posedge clk) begin
    if (~rst_n) begin
      R <= 0;
      G <= 0;
      B <= 0;
    end else begin
      R <= 0;
      G <= 0;
      B <= 0;
      if (video_active && logo_pixels) begin
        R <= red_pixel_value ? color[5:4] : 0;
        G <= green_pixel_value ? color[3:2] : 0;
        B <= blue_pixel_value ? color[1:0] : 0;
      end
    end
  end

endmodule
