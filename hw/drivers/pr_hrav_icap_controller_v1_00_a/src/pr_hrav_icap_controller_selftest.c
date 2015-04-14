/*****************************************************************************
* Filename:          /media/dung/anhqvn/FPGA11/contrib-projects/hrav_framework_b_finall3/hw/drivers/pr_hrav_icap_controller_v1_00_a/src/pr_hrav_icap_controller_selftest.c
* Version:           1.00.a
* Description:       
* Date:              Sun Feb  8 16:10:53 2015 (by Create and Import Peripheral Wizard)
*****************************************************************************/

#include "xparameters.h"
#include "pr_hrav_icap_controller.h"

/* IMPORTANT:
*  Slot ID is hard coded in this example to 0. Modify it if needs to connected to different slot.
*/
#define input_slot_id   0
#define output_slot_id  0

XStatus PR_HRAV_ICAP_CONTROLLER_SelfTest()
{
	 unsigned int input_0[256];     
	 unsigned int output_0[256];     

	 //Initialize your input data over here: 
	 input_0[0] = 12345;     
	 input_0[1] = 24690;     
	 input_0[2] = 37035;     
	 input_0[3] = 49380;     
	 input_0[4] = 61725;     
	 input_0[5] = 74070;     
	 input_0[6] = 86415;     
	 input_0[7] = 98760;     
	 input_0[8] = 111105;     
	 input_0[9] = 123450;     
	 input_0[10] = 135795;     
	 input_0[11] = 148140;     
	 input_0[12] = 160485;     
	 input_0[13] = 172830;     
	 input_0[14] = 185175;     
	 input_0[15] = 197520;     
	 input_0[16] = 209865;     
	 input_0[17] = 222210;     
	 input_0[18] = 234555;     
	 input_0[19] = 246900;     
	 input_0[20] = 259245;     
	 input_0[21] = 271590;     
	 input_0[22] = 283935;     
	 input_0[23] = 296280;     
	 input_0[24] = 308625;     
	 input_0[25] = 320970;     
	 input_0[26] = 333315;     
	 input_0[27] = 345660;     
	 input_0[28] = 358005;     
	 input_0[29] = 370350;     
	 input_0[30] = 382695;     
	 input_0[31] = 395040;     
	 input_0[32] = 407385;     
	 input_0[33] = 419730;     
	 input_0[34] = 432075;     
	 input_0[35] = 444420;     
	 input_0[36] = 456765;     
	 input_0[37] = 469110;     
	 input_0[38] = 481455;     
	 input_0[39] = 493800;     
	 input_0[40] = 506145;     
	 input_0[41] = 518490;     
	 input_0[42] = 530835;     
	 input_0[43] = 543180;     
	 input_0[44] = 555525;     
	 input_0[45] = 567870;     
	 input_0[46] = 580215;     
	 input_0[47] = 592560;     
	 input_0[48] = 604905;     
	 input_0[49] = 617250;     
	 input_0[50] = 629595;     
	 input_0[51] = 641940;     
	 input_0[52] = 654285;     
	 input_0[53] = 666630;     
	 input_0[54] = 678975;     
	 input_0[55] = 691320;     
	 input_0[56] = 703665;     
	 input_0[57] = 716010;     
	 input_0[58] = 728355;     
	 input_0[59] = 740700;     
	 input_0[60] = 753045;     
	 input_0[61] = 765390;     
	 input_0[62] = 777735;     
	 input_0[63] = 790080;     
	 input_0[64] = 802425;     
	 input_0[65] = 814770;     
	 input_0[66] = 827115;     
	 input_0[67] = 839460;     
	 input_0[68] = 851805;     
	 input_0[69] = 864150;     
	 input_0[70] = 876495;     
	 input_0[71] = 888840;     
	 input_0[72] = 901185;     
	 input_0[73] = 913530;     
	 input_0[74] = 925875;     
	 input_0[75] = 938220;     
	 input_0[76] = 950565;     
	 input_0[77] = 962910;     
	 input_0[78] = 975255;     
	 input_0[79] = 987600;     
	 input_0[80] = 999945;     
	 input_0[81] = 1012290;     
	 input_0[82] = 1024635;     
	 input_0[83] = 1036980;     
	 input_0[84] = 1049325;     
	 input_0[85] = 1061670;     
	 input_0[86] = 1074015;     
	 input_0[87] = 1086360;     
	 input_0[88] = 1098705;     
	 input_0[89] = 1111050;     
	 input_0[90] = 1123395;     
	 input_0[91] = 1135740;     
	 input_0[92] = 1148085;     
	 input_0[93] = 1160430;     
	 input_0[94] = 1172775;     
	 input_0[95] = 1185120;     
	 input_0[96] = 1197465;     
	 input_0[97] = 1209810;     
	 input_0[98] = 1222155;     
	 input_0[99] = 1234500;     
	 input_0[100] = 1246845;     
	 input_0[101] = 1259190;     
	 input_0[102] = 1271535;     
	 input_0[103] = 1283880;     
	 input_0[104] = 1296225;     
	 input_0[105] = 1308570;     
	 input_0[106] = 1320915;     
	 input_0[107] = 1333260;     
	 input_0[108] = 1345605;     
	 input_0[109] = 1357950;     
	 input_0[110] = 1370295;     
	 input_0[111] = 1382640;     
	 input_0[112] = 1394985;     
	 input_0[113] = 1407330;     
	 input_0[114] = 1419675;     
	 input_0[115] = 1432020;     
	 input_0[116] = 1444365;     
	 input_0[117] = 1456710;     
	 input_0[118] = 1469055;     
	 input_0[119] = 1481400;     
	 input_0[120] = 1493745;     
	 input_0[121] = 1506090;     
	 input_0[122] = 1518435;     
	 input_0[123] = 1530780;     
	 input_0[124] = 1543125;     
	 input_0[125] = 1555470;     
	 input_0[126] = 1567815;     
	 input_0[127] = 1580160;     
	 input_0[128] = 1592505;     
	 input_0[129] = 1604850;     
	 input_0[130] = 1617195;     
	 input_0[131] = 1629540;     
	 input_0[132] = 1641885;     
	 input_0[133] = 1654230;     
	 input_0[134] = 1666575;     
	 input_0[135] = 1678920;     
	 input_0[136] = 1691265;     
	 input_0[137] = 1703610;     
	 input_0[138] = 1715955;     
	 input_0[139] = 1728300;     
	 input_0[140] = 1740645;     
	 input_0[141] = 1752990;     
	 input_0[142] = 1765335;     
	 input_0[143] = 1777680;     
	 input_0[144] = 1790025;     
	 input_0[145] = 1802370;     
	 input_0[146] = 1814715;     
	 input_0[147] = 1827060;     
	 input_0[148] = 1839405;     
	 input_0[149] = 1851750;     
	 input_0[150] = 1864095;     
	 input_0[151] = 1876440;     
	 input_0[152] = 1888785;     
	 input_0[153] = 1901130;     
	 input_0[154] = 1913475;     
	 input_0[155] = 1925820;     
	 input_0[156] = 1938165;     
	 input_0[157] = 1950510;     
	 input_0[158] = 1962855;     
	 input_0[159] = 1975200;     
	 input_0[160] = 1987545;     
	 input_0[161] = 1999890;     
	 input_0[162] = 2012235;     
	 input_0[163] = 2024580;     
	 input_0[164] = 2036925;     
	 input_0[165] = 2049270;     
	 input_0[166] = 2061615;     
	 input_0[167] = 2073960;     
	 input_0[168] = 2086305;     
	 input_0[169] = 2098650;     
	 input_0[170] = 2110995;     
	 input_0[171] = 2123340;     
	 input_0[172] = 2135685;     
	 input_0[173] = 2148030;     
	 input_0[174] = 2160375;     
	 input_0[175] = 2172720;     
	 input_0[176] = 2185065;     
	 input_0[177] = 2197410;     
	 input_0[178] = 2209755;     
	 input_0[179] = 2222100;     
	 input_0[180] = 2234445;     
	 input_0[181] = 2246790;     
	 input_0[182] = 2259135;     
	 input_0[183] = 2271480;     
	 input_0[184] = 2283825;     
	 input_0[185] = 2296170;     
	 input_0[186] = 2308515;     
	 input_0[187] = 2320860;     
	 input_0[188] = 2333205;     
	 input_0[189] = 2345550;     
	 input_0[190] = 2357895;     
	 input_0[191] = 2370240;     
	 input_0[192] = 2382585;     
	 input_0[193] = 2394930;     
	 input_0[194] = 2407275;     
	 input_0[195] = 2419620;     
	 input_0[196] = 2431965;     
	 input_0[197] = 2444310;     
	 input_0[198] = 2456655;     
	 input_0[199] = 2469000;     
	 input_0[200] = 2481345;     
	 input_0[201] = 2493690;     
	 input_0[202] = 2506035;     
	 input_0[203] = 2518380;     
	 input_0[204] = 2530725;     
	 input_0[205] = 2543070;     
	 input_0[206] = 2555415;     
	 input_0[207] = 2567760;     
	 input_0[208] = 2580105;     
	 input_0[209] = 2592450;     
	 input_0[210] = 2604795;     
	 input_0[211] = 2617140;     
	 input_0[212] = 2629485;     
	 input_0[213] = 2641830;     
	 input_0[214] = 2654175;     
	 input_0[215] = 2666520;     
	 input_0[216] = 2678865;     
	 input_0[217] = 2691210;     
	 input_0[218] = 2703555;     
	 input_0[219] = 2715900;     
	 input_0[220] = 2728245;     
	 input_0[221] = 2740590;     
	 input_0[222] = 2752935;     
	 input_0[223] = 2765280;     
	 input_0[224] = 2777625;     
	 input_0[225] = 2789970;     
	 input_0[226] = 2802315;     
	 input_0[227] = 2814660;     
	 input_0[228] = 2827005;     
	 input_0[229] = 2839350;     
	 input_0[230] = 2851695;     
	 input_0[231] = 2864040;     
	 input_0[232] = 2876385;     
	 input_0[233] = 2888730;     
	 input_0[234] = 2901075;     
	 input_0[235] = 2913420;     
	 input_0[236] = 2925765;     
	 input_0[237] = 2938110;     
	 input_0[238] = 2950455;     
	 input_0[239] = 2962800;     
	 input_0[240] = 2975145;     
	 input_0[241] = 2987490;     
	 input_0[242] = 2999835;     
	 input_0[243] = 3012180;     
	 input_0[244] = 3024525;     
	 input_0[245] = 3036870;     
	 input_0[246] = 3049215;     
	 input_0[247] = 3061560;     
	 input_0[248] = 3073905;     
	 input_0[249] = 3086250;     
	 input_0[250] = 3098595;     
	 input_0[251] = 3110940;     
	 input_0[252] = 3123285;     
	 input_0[253] = 3135630;     
	 input_0[254] = 3147975;     
	 input_0[255] = 3160320;     

	 //Call the macro with instance specific slot IDs
	 pr_hrav_icap_controller(
		 input_slot_id,
		 output_slot_id,
		 input_0,      
		 output_0       
		 );

	 if (output_0[0] != 406101120)
		 return XST_FAILURE;
	 if (output_0[255] != 406101120)
		 return XST_FAILURE;

	 return XST_SUCCESS;
}
