`default_nettype none
module palette (
    input  wire [2:0] color_index,
    output wire [5:0] rrggbb
);

  reg [5:0] palette[7:0];

  initial begin
    palette[0] = 6'b111000;
    palette[1] = 6'b110110;  
    palette[2] = 6'b101101; 
    palette[3] = 6'b111000;  
    palette[4] = 6'b110011;  
    palette[5] = 6'b011111;   
    palette[6] = 6'b001011;  
    palette[7] = 6'b000000;  // black
  end

  assign rrggbb = palette[color_index];

endmodule
