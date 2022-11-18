module count_60(
    input wire rst,
    input wire clk,
    input wire en,
    output wire [7:0]cont,
    output wire co
);
    wire co10,co6,co10_1;
    wire [3:0] cont10,cont6;
    
    count_10 u_count_10(
    	.rst   (rst   ),
        .clk   (clk   ),
        .en    (en    ),
        .count (cont10 ),
        .co    (co10_1    )
    );
    
    //and u1(co10,en,co10_1);
    assign co10 = en & co10_1;      //when en equal 1 and co10_1 equal 1,co10(the enable signal of count6) can equal 1
    //co10 = en & co10_1; 
    
    count_6 u_count_6(
    	.rst   (rst   ),
        .clk   (clk   ),
        .en    (co10    ),
        .count (cont6 ),
        .co    (co6    )
    );
    
    //and u2(co,co10,co6);
    assign co = co10 & co6;         // as before said,when co10 and co6 both equal 1,co can equal 1(count60 enable signal)
    
    assign cont = {cont6,cont10};  //stitching the two result(example:(3,9)->39) 
    
endmodule

module count_6(
    input wire rst,
    input wire clk,
    input wire en,
    output reg [3:0] count,
    output reg co
);
    always @ (posedge clk) begin
        if (rst) begin
            count <= 4'b0;
            co <= 1'b0;
            //assign co = 1'b0;
        end
        else if (en) begin
            if (count == 4'd5) begin
                count <=4'b0;
                co <= 1'b0;
                //assign co = 1'b0;
            end
            else if(count == 4'd4) begin
                count <= count + 1'b1;
                co <= 1'b1;
                //assign co = 1'b1;
            end
            else begin
                count <= count + 1'b1;
                co <= 1'b0;
                //assign co = 1'b0;
            end
        end
    end    
endmodule

module count_10(
    input wire rst,
    input wire clk,
    input wire en,
    output reg [3:0] count,
    output reg co
);
    always @ (posedge clk) begin
        if (rst) begin
            count <= 4'b0;
            co <= 1'b0;
            //assign co = 1'b0;
        end
        else if (en) begin
            if (count == 4'd9) begin
                count <=4'b0;
                co <= 1'b0;
                //assign co = 1'b0;
            end
            else if(count == 4'd8) begin
                count <= count + 1'b1;
                co <= 1'b1;
                //assign co = 1'b1;
            end
            else begin
                count <= count + 1'b1;
                co <= 1'b0;
                //assign co = 1'b0;
            end
        end
    end
endmodule