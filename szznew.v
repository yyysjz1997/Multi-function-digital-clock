module szznew(LED_Hr,LED_Min,LED_Sec,ALARM,_1kHzIN,
         Adj_Min_key,Adj_Hour_key,Set_Min_key,Set_Hr_key,Ctrl_Bell,Mode,LED_Min1,LED_Min2,LED_Hr1,LED_Hr2,YYY);
       input _1kHzIN;
       input YYY;
       output[7:0]LED_Hr,LED_Min,LED_Sec;
       output[6:0]LED_Min1,LED_Min2,LED_Hr1,LED_Hr2;
       wire[7:0]LED_Hr,LED_Min,LED_Sec;
       wire[6:0]LED_Min1,LED_Min2,LED_Hr1,LED_Hr2;
       supply1 Vdd;
       
       input Adj_Min_key,Adj_Hour_key;
       wire[7:0]Hour,Minute,Second;
       wire MinL_EN,MinH_EN,Hour_EN;
       
       reg ALARM_Radio;
       wire ALARM_Clock;
       output ALARM;
       
       wire [7:0]Set_Hr,Set_Min;
       wire Hr_H_EQU,Hr_L_EQU,Min_H_EQU,Min_L_EQU;

       
       input Set_Hr_key,Set_Min_key;
       input Ctrl_Bell;
       input Mode;
       
       Divier_50MHz_2Hz(Vdd,_1kHzIN,_1Hz);
       //Divided_Frequency U0(_1Hz,_2Hz,_500Hz,Vdd,Vdd,_1kHz);
       
       counter10 U1(Second[3:0],YYY,Vdd,_1Hz);
       counter6 U2(Second[7:4],YYY,(Second[3:0]==4'h9),_1Hz);
       
       assign MinL_EN=Adj_Min_key?Vdd:(Second==8'h59);
       assign MinH_EN=(Adj_Min_key&&(Minute[3:0]==4'h9))||(Minute[3:0]==4'h9)&&(Second==8'h59);
       counter10 U3(Minute[3:0],YYY,MinL_EN,_1Hz);
       counter6 U4(Minute[7:4],YYY,MinH_EN,_1Hz);
       assign Hour_EN=Adj_Hour_key?Vdd:((Minute==8'h59)&&(Second==8'h59));
       counter24 U5(Hour[7:4],Hour[3:0],YYY,Hour_EN,_1Hz);
       
       always@(Minute or Second)
			if(Minute==8'h59)
				case (Second)
				8'h51,
				8'h53,
				8'h55,
			    8'h57,
				8'h59:ALARM_Radio=_1Hz;
				default:ALARM_Radio=1'b0;
				endcase
		    else ALARM_Radio=1'b0;
		    
	   counter10 SU1(Set_Min[3:0],Vdd,Set_Min_key,_1Hz);
	   counter6 SU2(Set_Min[7:4],Vdd,(Set_Min[3:0]==4'h9),_1Hz);
	   counter24 SU3(Set_Hr[7:4],Set_Hr[3:0],Vdd,Set_Hr_key,_1Hz);
	   
	   _4bitComparer SU4(Hr_H_EQU,Set_Hr[7:4],Hour[7:4]);
	   _4bitComparer SU5(Hr_L_EQU,Set_Hr[3:0],Hour[3:0]);
	   _4bitComparer SU6(Min_H_EQU,Set_Min[7:4],Minute[7:4]);
	   _4bitComparer SU7(Min_L_EQU,Set_Min[3:0],Minute[3:0]);
	   
	   assign ALARM_Clock=Ctrl_Bell?(((Hr_H_EQU&&Hr_L_EQU&&Min_H_EQU&&Min_L_EQU))&&
	       (((Second[0]==1'b0)&&_1kHzIN))):1'b0;
	
	   assign ALARM=ALARM_Clock||ALARM_Radio;
	  
	   _2to1MUX MU1(LED_Hr,Mode,Set_Hr,Hour);
	   _2to1MUX MU2(LED_Min,Mode,Set_Min,Minute);
       _2to1MUX MU3(LED_Sec,Mode,8'h00,Second);
       
       Decoder(LED_Min1,LED_Min[3:0]);
       Decoder(LED_Min2,LED_Min[7:4]);
       Decoder(LED_Hr1,LED_Hr[3:0]);
       Decoder(LED_Hr2,LED_Hr[7:4]);
       
endmodule



//******************************************Divier_50MHz_2Hz********************************
module Divier_50MHz_2Hz(
	input CR, CLK_50M,
	output reg CLk_1HzOut);
	
	reg [24:0] Count_Div;
	always @(posedge CLK_50M or negedge CR) 
	begin
		if (!CR) 
			begin
				CLk_1HzOut<=0;
				Count_Div<=0;
			end
		else  
			begin
			//	if(Count_Div<(50000000/(2*100)))	//20Hz	
				if(Count_Div<5)
					Count_Div<=Count_Div+1'b1;
				else 
					begin
						Count_Div<=0;
						CLk_1HzOut<=~CLk_1HzOut;	
					end	
			end
	end
endmodule
//****************************************2-to-1-line multiplexer***************************
module _2to1MUX(OUT,SEL,X,Y);
       input [7:0] X,Y;
       input SEL;
       output [7:0]OUT;
       assign OUT=SEL?X:Y;
endmodule
//****************************************4-bit Comparer************************************
module _4bitComparer(EQU,A,B);
       input [3:0]A,B;
       output EQU;
       assign EQU=(A==B);
endmodule 
//****************************************Divided_Frequency*********************************
module Divided_Frequency(_1HzOut,_2HzOut,_500HzOut,nCR,EN,_1kHzIN);
	   input _1kHzIN,nCR,EN;
       output _1HzOut,_2HzOut,_500HzOut;
       wire [11:0]Q;
       wire EN1,EN2;
       counter10 DU0(Q[3:0],nCR,EN,_1kHzIN);
       counter10 DU1(Q[7:4],nCR,EN1,_1kHzIN);
       counter10 DU2(Q[11:8],nCR,EN2,_1kHzIN);
       assign EN1=(Q[3:0]==4'd9);
       assign EN2=(Q[7:4]==4'd9)&(Q[3:0]==4'd9);
       assign _1HzOut=Q[11];
	   assign _2HzOut=Q[10];
	   assign _500HzOut=Q[0];
endmodule
//****************************************counter10******************************************
module counter10(Q,nCR,EN,CP);
       input CP,nCR,EN;
       output [3:0]   Q;
       reg [3:0]   Q;
       always@(posedge CP or negedge nCR)
       begin
             if(~nCR)  Q<=4'b0000;
             else if(~EN)  Q<=Q;
             else if(Q==4'b1001)  Q<=4'b0000;
             else Q<=Q+1'b1;
       end
endmodule 
//****************************************counter6*********************************************
module counter6(Q,nCR,EN,CP);
       input CP,nCR,EN;
       output [3:0]   Q;
       reg [3:0]   Q;
       always@(posedge CP or negedge nCR)
       begin
             if(~nCR)  Q<=4'b0000;
             else if(~EN)  Q<=Q;
             else if(Q==4'b0101)  Q<=4'b0000;
             else Q<=Q+1'b1;
       end
endmodule 
//****************************************counter24*********************************************
module counter24(CntH,CntL,nCR,EN,CP);
       input CP,nCR,EN;
       output [3:0]CntH,CntL;
       reg [3:0]CntH,CntL;
       always@(posedge CP or negedge nCR)
       begin 
            if(~nCR)   {CntH,CntL}<=8'h00;
       else if(~EN)  {CntH,CntL}<={CntH,CntL};
       else if((CntH>2)||(CntL>9)||((CntH==2)&&(CntL>=3)))
                  {CntH,CntL}<=8'h00;
       else if((CntH==2)&&(CntL<3))
            begin CntH<=CntH;  CntL<=CntL+1'b1; end 
       else if(CntL==9)
            begin CntH<=CntH+1'b1;   CntL<=4'b0000; end
       else 
            begin CntH<=CntH;  CntL<=CntL+1'b1; end 
       end
 endmodule
 //***************************************Decoder****************************************************
module Decoder(segout,segin);
	input [4:0]segin;
	output [6:0] segout;								
	reg [6:0] segout;
	always@(segin)
	case(segin)
		4'b0000:segout <= 7'b1000000;//0 
		4'b0001:segout <= 7'b1111001;//1
		4'b0010:segout <= 7'b0100100;//2 
		4'b0011:segout <= 7'b0110000;//3 
		4'b0100:segout <= 7'b0011001;//4
		4'b0101:segout <= 7'b0010010;//5
		4'b0110:segout <= 7'b0000010;//6
		4'b0111:segout <= 7'b1111000;//7
		4'b1000:segout <= 7'b0000000;//8
		4'b1001:segout <= 7'b0010000;//9
		default:segout <= 7'b0100011;//o
	endcase
endmodule 