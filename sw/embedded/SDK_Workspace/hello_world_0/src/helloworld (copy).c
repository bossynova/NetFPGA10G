/*******************************************************************************
 *
 *  NetFPGA-10G http://www.netfpga.org
 *
 *  File:
 *        helloworld.c
 *
 *  Project:
 *        reference_nic_1g
 *
 *  Author:
 *        James Hongyi Zeng
 *
 *  Description:
 *        Example C file to initialize AEL2005 to 1G mode through
 *        MDIO and dump PHY chip status
 *
 *        Currently SGMII is supported. The PHY type (1000BASE-T
 *        or 1000BASE-X) depends on the SFP module plugged in.
 *
 *  Copyright notice:
 *        Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
 *                                 Junior University
 *
 *  Licence:
 *        This file is part of the NetFPGA 10G development base package.
 *
 *        This file is free code: you can redistribute it and/or modify it under
 *        the terms of the GNU Lesser General Public License version 2.1 as
 *        published by the Free Software Foundation.
 *
 *        This package is distributed in the hope that it will be useful, but
 *        WITHOUT ANY WARRANTY; without even the implied warranty of
 *        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *        Lesser General Public License for more details.
 *
 *        You should have received a copy of the GNU Lesser General Public
 *        License along with the NetFPGA source package.  If not, see
 *        http://www.gnu.org/licenses/.
 *
 */

#include <stdio.h>
#include "platform.h"
#include "xwdttb.h"
#include "xemaclite.h"
#include "xemaclite_l.h"

#define PACKET_REG_0	0x78200000
#define PACKET_REG_1	0x78200001
#define COUNTER_REG_0	0x78200002
#define COUNTER_REG_1	0x78200003
#define TIMER_REG_0 	0x78200004
#define TIMER_REG_1	0x78200005
#define RESET_REG	0x78200010

#define HASH_REG_0	0x78200006
#define HASH_REG_1	0x78200007
#define HASH_REG_2	0x78200008
#define HASH_REG_3	0x78200009


int main (void) {

	init_platform();
   
	unsigned int *reset = RESET_REG;
   
	*reset = 1;
	*reset = 0;
   
	unsigned int i  = 0;	

	unsigned int *timer_0 = TIMER_REG_0;	
	unsigned int *timer_1 = TIMER_REG_1;
	unsigned int *count_0 = COUNTER_REG_0;	
	unsigned int *count_1 = COUNTER_REG_1;
	unsigned int *packet_0 = PACKET_REG_0;	
	unsigned int *packet_1 = PACKET_REG_1;
	
	unsigned int *hash_0 = HASH_REG_0;
	unsigned int *hash_1 = HASH_REG_1;
	unsigned int *hash_2 = HASH_REG_2;
	unsigned int *hash_3 = HASH_REG_3;
	
	while(1){
		xil_printf("Press 'g' to read registers, 'r' to reset registers' value");
		char t = inbyte();
		if (t == 'g') {
			xil_printf("\nTimer 0:    %d\n", *timer_0);
			xil_printf("Timer 1:    %d\n", *timer_1);
			xil_printf("Counter 0:  %d\n", *count_0);
			xil_printf("Counter 1:  %d\n", *count_1);
			xil_printf("Packet 0:   %d\n", *packet_0);
			xil_printf("Packet 1:   %d\n", *packet_1);
			xil_printf("Hash: %x %x %x %x\n", *hash_0, *hash_1, *hash_2, *hash_3);
			xil_printf("\n\n");
		}else if (t == 'r') {
			*reset = 1;
			*reset = 0;
		}		
	}

	cleanup_platform();
	return 0;

}


