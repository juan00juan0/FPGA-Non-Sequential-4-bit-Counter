`timescale 1ns / 1ps

module NonSeqCounter_4bit(
    input BTNC,
    input CLK,
    output reg LED,
    output [7:0] SEG,
    output [7:0] AN
    );
    reg [3:0] Count = 4'b1001;
    reg [3:0] State = 3'b0000;
    reg [3:0] NextState = 3'b0000;
    
    
    parameter width1 = 100000000;
    parameter width2=10000;
    reg [7:0] Sarray [0:7]; //64 bit 2D array holding desired values for all digits
    wire [63:0] Pass_Array; // 64 bit 1D array used to pass the 2D array to submodule
    wire [7:0] Seg_val0; // holding 8 bit cathode values to pass to submodule
    wire [7:0] Seg_val1;
    wire [7:0] Seg_val2;
    wire [7:0] Seg_val3;
    wire [7:0] Seg_val4;
    wire Clk_Slow, Clk_Multi; //Clocks from divider module
    
    //assign LED = SW;
    //Clk_Divider # (width1,width2) In1 (CLK, Clk_Slow, Clk_Multi); //Here is the instanitatin of the clock divider module
    Clk_Divider CD0(CLK, Clk_Slow, Clk_Multi);
    //Clk_Slow not used in this project
    SetSegments D0({3'b000, Count[0]}, Seg_val0); //the 1'b0 turns off decimal pt
//    assign Sarray [0] = Seg_val0; //Have to use Seg_valx because can't pass 2D array
    SetSegments D1({3'b000, Count[1]},Seg_val1);
//    assign Sarray [1] = Seg_val1;
    SetSegments D2({3'b000, Count[2]}, Seg_val2); //the 1'b0 turns off decimal pt
//    assign Sarray [2] = Seg_val2; //Have to use Seg_valx because can't pass 2D array
    SetSegments D3({3'b000, Count[3]},Seg_val3);
//    assign Sarray [3] = Seg_val3;
    SetSegments D4(Count[3:0],Seg_val4);
//    assign Sarray [4] = Seg_val4;
    //finish up by doing the 2 for the digits #4 and #5 and make sure you complement the digits
    //Now we turn off the indicators we are not using by putting FF in the 2D array for each indicator.
//    assign Sarray [5] = 8'hFF; //MUST USE FF for blanking the digit
//    assign Sarray [6] = 8'hFF;
//    assign Sarray [7] = 8'hFF;
    
    always @(State) begin
        if(State == 0) begin
            Sarray[0] <= 8'hFF;
            Sarray[1] <= 8'hFF;
            Sarray[2] <= 8'hFF;
            Sarray[3] <= 8'hFF;
            Sarray[4] <= 8'hFF;
            Sarray[5] <= 8'hFF;
            Sarray[6] <= 8'hFF;
            Sarray[7] <= 8'hFF;
        end
        else if( (State >= 1) && (State <= 8) ) begin
            Sarray[0] <= Seg_val0;
            Sarray[1] <= Seg_val1;
            Sarray[2] <= Seg_val2;
            Sarray[3] <= Seg_val3;
            Sarray[4] <= Seg_val4;
            Sarray[5] <= 8'hFF;
            Sarray[6] <= 8'hFF;
            Sarray[7] <= 8'hFF;
        end
        else if(State == 9) begin
            Sarray[0] <= ~(8'b01111001); // xE
            Sarray[1] <= ~(8'b01111100); // xB
            Sarray[2] <= ~(8'b01100110); // x4
            Sarray[3] <= ~(8'b01011110); // xD
            Sarray[4] <= ~(8'b01110111); // xA
            Sarray[5] <= ~(8'b01110001); // xF
            Sarray[6] <= ~(8'b00000111); // x7
            Sarray[7] <= ~(8'b01100111); // x9
        end
    end
    
    //Linerize the Sarray
    assign Pass_Array = {Sarray[0],Sarray[1],Sarray[2],Sarray[3],Sarray[4],Sarray[5],Sarray[6],Sarray[7]};
    Display_Digit In6 (Pass_Array, Clk_Multi, SEG, AN); //Make sure you understand this line!
    
//    initial begin
//        State <= 0;
//        NextState <= 0;
//    end
    
    always @(State) begin
        NextState = 0;
        case(State)
            4'b0000: begin
                if(BTNC) begin
                    NextState <= 1;
                end
            end
            4'b0001: begin
                NextState <= 2;
                Count <= 4'b1001;
            end
            4'b0010: begin
                Count <= 4'b0111;
                NextState <= 3;
            end
            4'b0011: begin
                Count <= 4'b1111;
                NextState <= 4;
            end
            4'b0100: begin
                Count <= 4'b1010; //0xA
                NextState <= 5;
            end
            4'b0101: begin
                Count <= 4'b1101; // 0xD
                NextState <= 6;
            end
            4'b0110: begin
                Count <= 4'b0100; // 0x4
                NextState <= 7;
            end
            4'b0111: begin
                Count <= 4'b1011; // 0xB
                NextState <= 8;
            end
            4'b1000: begin
                Count <= 4'b1110; // 0xE
                NextState <= 9;
            end
            4'b1001: begin
                if(BTNC) begin
                    NextState <= 1;
                end
                else begin
                    NextState <= 9;
                end
            end
            default: begin
                NextState <= 0;
            end
        endcase
    end
    
    always @(posedge Clk_Slow) begin
        State <= NextState;
    end
    
       
endmodule

module Clk_Divider(
    input CLK,
    output reg CLK_SLOW,
    output reg CLK_MULTI);
    
    parameter multi_divisor = 10000;
    //parameter slow_divisor =  100000000;
    parameter slow_divisor = 50000000;
    
    reg [31:0] counter_slow, counter_multi;
    initial begin
        counter_slow = 0;
        counter_multi = 0;
        CLK_SLOW = 1'b0;
        CLK_MULTI = 1'b0;
    end
    
    always @(posedge CLK) begin
        counter_slow <= counter_slow + 1;
        counter_multi <= counter_multi + 1;
        
        if(counter_multi > multi_divisor) begin
            counter_multi <= 0;
            CLK_MULTI <= ~CLK_MULTI;
        end
        if(counter_slow > slow_divisor) begin
            counter_slow <= 0;
            CLK_SLOW <= ~CLK_SLOW;
        end
    end  
endmodule

module SetSegments(
    input [3:0] Digit,
    output reg [7:0] SEG_CA);
    
    //reg [7:0] SEG_CA;
    
    always @(Digit)begin
        case (Digit)
            4'h0: SEG_CA = ~(8'b00111111); //Note: to lite digit, cathode must = 0
            4'h1: SEG_CA = ~(8'b00000110);
            4'h2: SEG_CA = ~(8'b01011011);
            4'h3: SEG_CA = ~(8'b01001111);
            4'h4: SEG_CA = ~(8'b01100110);
            4'h5: SEG_CA = ~(8'b01101101);
            4'h6: SEG_CA = ~(8'b01111101);
            4'h7: SEG_CA = ~(8'b00000111);
            4'h8: SEG_CA = ~(8'b01111111);
            4'h9: SEG_CA = ~(8'b01100111);
            4'hA: SEG_CA = ~(8'b01110111);
            4'hB: SEG_CA = ~(8'b01111100);
            4'hC: SEG_CA = ~(8'b00111001);
            4'hD: SEG_CA = ~(8'b01011110);
            4'hE: SEG_CA = ~(8'b01111001);
            4'hF: SEG_CA = ~(8'b01110001);
            default: SEG_CA = ~(8'b01001001);
        endcase
    end
endmodule

module Display_Digit (
    input [63:0] Parray,
    input Clk,
    output reg [7:0] Segments,
    output reg [7:0] AN
    );
    wire [7:0] Cath [0:7]; //array of 8, 8 bit cathode values where Seg [0] is Right indicator
    // and Seg[7] is Left most indicator cathods
    reg [3:0] i; // used to count through 16 states to multiplex the 8 displays
    //Now we break out the linerized array
    assign {Cath [0],Cath [1],Cath [2],Cath [3],Cath [4],Cath [5],Cath [6],Cath [7]} = Parray;
    
    initial begin
    i=4'b0000;
    end
    
    always @(posedge Clk)begin
        case (i)
            4'h0:
            begin
            AN = ~(8'b00000000); //All off, set cathodes
            Segments = Cath [0];
            end
            4'h1:AN = ~(8'b00000001); //Display first indicator on R
            4'h2:
            begin
            AN = ~(8'b00000000); //All off set next cath
            Segments = Cath [1];
            end
            4'h3:AN = ~(8'b00000010); //Display 2nd indicator on R
            4'h4:
            begin
            AN = ~(8'b00000000); //All off set next cath
            Segments = Cath [2];
            end
            4'h5:AN = ~(8'b00000100); //Display 3rd indicator on R
            4'h6:
            begin
            AN = ~(8'b00000000); //All off set next cath
            Segments = Cath [3];
            end
            4'h7:AN = ~(8'b00001000); //Display 4th indicator on R
            4'h8:
            begin
            AN = ~(8'b00000000); //All off set next cath
            Segments = Cath [4];
            end
            4'h9:AN = ~(8'b00010000); //Display 5th indicator on R
            4'hA:
            begin
            AN = ~(8'b00000000); //All off set next cath
            Segments = Cath [5];
            end
            4'hB:AN = ~(8'b00100000); //Display 3rd indicator on R
            4'hC:
            begin
            AN = ~(8'b00000000); //All off set next cath
            Segments = Cath [6];
            end
            4'hD:AN = ~(8'b01000000); //Display 3rd indicator on R
            4'hE:
            begin
            AN = ~(8'b00000000); //All off set next cath
            Segments = Cath [7];
            end
            4'hF:AN = ~(8'b10000000); //Display 3rd indicator on R
            default:AN = ~(8'b00000000);
        endcase
        i = i + 4'b0001;
    end
endmodule