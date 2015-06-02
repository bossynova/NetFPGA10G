/*
 ============================================================================
 Name        : send_unit_test.c
 Author      : Chien Do Minh
 Version     : 1.0
 Copyright   : Your copyright notice
 Description : Hello World in C, Ansi-style
 ============================================================================
 */
#ifndef NULL
#define NULL   ((void *) 0)
#endif
typedef enum { FALSE, TRUE } bool;
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/stat.h>
#define PR_FILE_0				"pr_core0.bit"
#define PR_FILE_1				"pr_core1.bit"
#define DMA_PKT_LEN 			64
#define BUFFER_LEN_DEFAULT 		8000
#define BUFFER_HALF_LEN_DEFAULT	(BUFFER_LEN_DEFAULT/2)
#define	DMA_PKT_MAGIC_NUMBER_0	0xfe
#define DMA_PKT_MAGIC_NUMBER_1	0xca
#define DMA_PKT_MAGIC_NUMBER_2	0xae
#define DMA_BUF_SIZE 			(DMA_PKT_LEN + 1)
#define MIN_DMA_PKT_LEN 		60
#define DMA_BUFF_INFO 			24
#define CORE_0 					0x0
#define CORE_1 					0x1
int main(void) {
	char buffer[BUFFER_LEN_DEFAULT];
	int pos = 0,
		file_size = 0,
		buffer_size = BUFFER_LEN_DEFAULT;
	FILE *fin = fopen("testfile_tiny_tiny.txt","r");
	if(!fin){
		printf("Can't open the file %s\n", "testfile_tiny.txt");
	}
	fseek(fin, 0, SEEK_END);
	file_size = ftell(fin);
	printf("Size of read file: %ld\n",file_size);
	rewind(fin);
	printf("Size of  sending buffer: %ld\n",(sizeof(buffer)/sizeof(char)));
	while(pos!=file_size){
		if(file_size - pos < BUFFER_LEN_DEFAULT){
			buffer_size = file_size - pos;
			pos += fread(buffer, 1, buffer_size, fin);
		}
		else
			pos += fread(buffer, 1, buffer_size, fin);
		/*printf("Positon: %d\n",pos);
		printf("Buffer Size: %d\n",buffer_size);*/

		/*if(file_exist(PR_FILE_0)){
		 	static FILE* fp = fopen(PR_FILE_0,"r");
			cli_bbf_static_scanbuff(buffer, buffer_size, NULL,
				NULL, NULL, 0, NULL, NULL, NULL,fp, CORE_0);
		}
		else if(file_exist(PR_FILE_1)){
		 	static FILE* fp = fopen(PR_FILE_1,"r");
			cli_bbf_static_scanbuff(buffer, buffer_size, NULL,
				NULL, NULL, 0, NULL, NULL, NULL,fp, CORE_1);
		}
		else*/
			cli_bbf_static_scanbuff(buffer, buffer_size, NULL, NULL, NULL, 0, NULL, NULL, NULL, 0, 0);
	}

	return 0;
}
int cli_bbf_static_scanbuff(const unsigned char *buffer, uint32_t length, const char **virname,
        const struct cli_bm_patt **patt, const struct cli_matcher *root,
        uint32_t offset, const struct cli_target_info *info, struct cli_bm_off *offdata,
        uint32_t *viroffset, int sock_send, int sock_rec)
{

	//  struct timespec start, end, packet_time_start, packet_time_end;
	//  printf("bufferID is %d\n",buffer_ID);

	    struct packet_header
	    {
	        char magic[3];
	        char type;
	        char bufferID[3];
	        char status;
	    };
	    typedef struct packet_header HEADER; // 3 + 1 + 3 + 1 = 8 (bytes)

	    struct send_packet
	    {
	        HEADER header; // 8
	        char info[DMA_BUFF_INFO]; // 24
	        int length; //length of data: 4
	        char data[DMA_BUF_SIZE]; // 1471 : de danh 1 byte NULL cho STRING
	    };
	    typedef struct send_packet PACKET; // 8 + 24 + 4 + 1472 = 1508

	    struct send_buffer
	    {
	        int length; // 4
	        char buffer[DMA_BUF_SIZE]; // 1473
	    };
	    typedef struct send_buffer BUFFER; // 4 + 1476 = 1480
	    PACKET sendPacket_0, sendPacket_1;
	    BUFFER sendBuffer_0, sendBuffer_1;

	    /*Divide the buffer into two equal size buffers.
	    *There are two special cases that need to be concerned
	    *1. The Buffer is empty
	    *2. The Core 1 have more packet than Core 0.
	    *(ie. 2nd buffer have more one byte than 1st buffer, and this byte is the beginning of a new packet).
	    */

	    /*Buffer pointer*/
	    int pos_0 = 0;			//begin of left-half-part buffer (ie. core_0)
	    int pos_1 = length/2;	//begin of right-half-part buffer (ie. core_1)

	    char first = TRUE;
	    char last_0 = FALSE;
	    char last_1 = FALSE;
	    memset(sendPacket_0.info, '\xFF', DMA_BUFF_INFO);
	    memset(sendPacket_1.info, '\xFF', DMA_BUFF_INFO);

	    // Prepare packet
	    int cli_send_DMA_result = 0;
	    int packet_count = 0;
		bzero(sendPacket_0.data,DMA_BUF_SIZE);
	    bzero(sendPacket_1.data,DMA_BUF_SIZE);
		bzero(sendBuffer_0.buffer,DMA_BUF_SIZE);
	    bzero(sendBuffer_1.buffer,DMA_BUF_SIZE);

	    while(!(last_0 && last_1))
	    {
	        //packet_count++ ;
	        cli_send_DMA_result = 0;
	        /* Clear all sending buffer */
	        sendPacket_0.length = 0;
	        sendPacket_1.length = 0;
	        bzero(sendPacket_0.data,DMA_BUF_SIZE);
	        bzero(sendPacket_1.data,DMA_BUF_SIZE);
	        sendBuffer_0.length = 0;
	        sendBuffer_1.length = 0;
	        bzero(sendBuffer_0.buffer,DMA_BUF_SIZE);
	        bzero(sendBuffer_1.buffer,DMA_BUF_SIZE);

	        int dataSize_0;
	        int dataSize_1;

	        if(first) // first packet
	        {
	            dataSize_0 = DMA_PKT_LEN - sizeof(HEADER) - sizeof(sendPacket_0.info);
	            dataSize_1 = DMA_PKT_LEN - sizeof(HEADER) - sizeof(sendPacket_1.info);
	        }
	        else
	        {
	            dataSize_0 = DMA_PKT_LEN - sizeof(HEADER);
	            dataSize_1 = DMA_PKT_LEN - sizeof(HEADER);
	        }
	        //last packet
	        last_0 = (dataSize_0<(length/2 - pos_0))?FALSE:TRUE;
	        last_1 = (dataSize_1<(length - pos_1))?FALSE:TRUE;
	        dataSize_0 = last_0?(length/2-pos_0):dataSize_0;
	        dataSize_1 = last_1?(length-pos_1):dataSize_1;

	        //calculate packet length
	        int packetSize_0, packetSize_1;
	        packetSize_0 = dataSize_0 + sizeof(HEADER) +(first?sizeof(sendPacket_0.info):0);
	        packetSize_1 = dataSize_1 + sizeof(HEADER) +(first?sizeof(sendPacket_1.info):0);
	        /* Configure packet Header */
	        sendPacket_0.header.magic[0] = DMA_PKT_MAGIC_NUMBER_0;
	        sendPacket_0.header.magic[1] = DMA_PKT_MAGIC_NUMBER_1;
	        sendPacket_0.header.magic[2] = DMA_PKT_MAGIC_NUMBER_2;

	        sendPacket_1.header.magic[0] = DMA_PKT_MAGIC_NUMBER_0;
	        sendPacket_1.header.magic[1] = DMA_PKT_MAGIC_NUMBER_1;
	        sendPacket_1.header.magic[2] = DMA_PKT_MAGIC_NUMBER_2;

	        sendPacket_0.header.bufferID[0] = 0xFF;
	        sendPacket_0.header.bufferID[1] = 0xFF;
	        sendPacket_0.header.bufferID[2] = 0xFF;

	        sendPacket_1.header.bufferID[0] = 0xFF;
	        sendPacket_1.header.bufferID[1] = 0xFF;
	        sendPacket_1.header.bufferID[2] = 0xFF;

	        // Configure packet status
	        if(packetSize_0 >= MIN_DMA_PKT_LEN){
	            sendPacket_0.header.status &= 0x00; // set the 6bit MSB = 0.
	        }
	        else
	        {
	            sendPacket_0.header.status = 0xFC & (packetSize_0 << 2); // set 6bit MSB = packetsize;
	        }

	        if(packetSize_1 >= MIN_DMA_PKT_LEN){
	            sendPacket_1.header.status &= 0x00; // set the 6bit MSB = 0.
	        }
	        else
	        {
	            sendPacket_1.header.status = 0xFC & (packetSize_1 << 2); // set 6bit MSB = packetsize;
	        }

	        sendPacket_0.header.status = (first)?(sendPacket_0.header.status|0x02):(sendPacket_0.header.status & 0xFD); //if first set status[1] to 1.
	        sendPacket_0.header.status = (last_0)?(sendPacket_0.header.status|0x01):(sendPacket_0.header.status & 0xFE); //if last set status[0] to 1.
	        sendPacket_1.header.status = (first)?(sendPacket_1.header.status|0x02):(sendPacket_1.header.status & 0xFD); //if first set status[1] to 1.
	        sendPacket_1.header.status = (last_1)?(sendPacket_1.header.status|0x01):(sendPacket_1.header.status & 0xFE); //if last set status[0] to 1.
	        /* Configure Buffer Info */
	        if(first)
	        {
	            //setting extra data for current data bufer at the first packet
	        }

	        /* Configure packet data */
	        sendPacket_0.length = dataSize_0;
	        sendBuffer_0.length = packetSize_0;
	        sendPacket_1.length = dataSize_1;
	        sendBuffer_1.length = packetSize_1;
	        /* Copy packet to sending buffer */
	        //copy header

	        //copy buffer info and data to send
	        if(first)
	        {
	            first = FALSE;
	            //core 0
	            sendPacket_0.header.type = CORE_0; //packet type
	            memcpy(sendBuffer_0.buffer,&sendPacket_0.header,sizeof(HEADER));
	            //memcpy(sendPacket.data,buffer + pos_0,dataSize);
	            //copy buffer info
	            memcpy(sendBuffer_0.buffer+sizeof(HEADER),sendPacket_0.info,DMA_BUFF_INFO);
	            //copy buffer data.
	            //memcpy(sendBuffer.buffer+sizeof(HEADER)+DMA_BUFF_INFO,sendPacket.data,sendPacket.length);
			    memcpy(sendBuffer_0.buffer+sizeof(HEADER)+DMA_BUFF_INFO,buffer + pos_0,dataSize_0);

	            if(sendPacket_0.length > 0){
	                /*int written_bytes = write(sock_send,sendBuffer_0.buffer,sendBuffer_0.length);
	                if (written_bytes <= 0)
	                {
	                    printf("\nWrite data error!\n");
	                }*/
	                if(last_0){
	                    packet_count++;
	                }
	            	print_hex(sendBuffer_0.buffer, sendBuffer_0.length, packet_count, CORE_0);
	            }
	            //core 1
	            sendPacket_1.header.type = CORE_1; //packet type
	            memcpy(sendBuffer_1.buffer,&sendPacket_1.header,sizeof(HEADER));
	            //memcpy(sendPacket.data,buffer + pos_1,dataSize);
	            //copy buffer info
	            memcpy(sendBuffer_1.buffer+sizeof(HEADER),sendPacket_1.info,DMA_BUFF_INFO);
	            //copy buffer data.
	            //memcpy(sendBuffer.buffer+sizeof(HEADER)+DMA_BUFF_INFO,sendPacket.data,sendPacket.length);
			    memcpy(sendBuffer_1.buffer+sizeof(HEADER)+DMA_BUFF_INFO,buffer + pos_1,dataSize_1);
	            if(sendPacket_1.length > 0){
	                /*int written_bytes = write(sock_send,sendBuffer_1.buffer,sendBuffer_1.length);
	                if (written_bytes <= 0)
	                {
	                    printf("\nWrite data error!\n");
	                }*/
	                if(last_1){
	                    packet_count++;
	                }
	                print_hex(sendBuffer_1.buffer, sendBuffer_1.length, packet_count, CORE_1);
	            }

	        }
	        else
	        {
	            //core 0
	            sendPacket_0.header.type = CORE_0; //packet type
	            memcpy(sendBuffer_0.buffer,&sendPacket_0.header,sizeof(HEADER));
	            //memcpy(sendPacket.data,buffer + pos_0,dataSize);
	            //copy buffer info
	            //memcpy(sendBuffer.buffer+sizeof(HEADER),sendPacket.data,sendPacket.length);
			    memcpy(sendBuffer_0.buffer+sizeof(HEADER),buffer + pos_0,dataSize_0);
	            if(sendPacket_0.length > 0){
	                /*int written_bytes = write(sock_send,sendBuffer_0.buffer,sendBuffer_0.length);
	                if (written_bytes <= 0)
	                {
	                    printf("\nWrite data error!\n");
	                }*/
	                if(last_0){
	                    packet_count++;
	                }
	                print_hex(sendBuffer_0.buffer, sendBuffer_0.length, packet_count, CORE_0);
	            }

	            sendPacket_1.header.type = CORE_1; //packet type
	            memcpy(sendBuffer_1.buffer,&sendPacket_1.header,sizeof(HEADER));
	            //memcpy(sendPacket.data,buffer + pos_1,dataSize);
	            //copy buffer info
	            //memcpy(sendBuffer.buffer+sizeof(HEADER),sendPacket.data,sendPacket.length);
			    memcpy(sendBuffer_1.buffer+sizeof(HEADER),buffer + pos_1,dataSize_1);
	            if(sendPacket_1.length > 0){
	                /*int written_bytes = write(sock_send,sendBuffer_1.buffer,sendBuffer_1.length);
	                if (written_bytes <= 0)
	                {
	                    printf("\nWrite data error!\n");
	                }*/
	                if(last_1){
	                    packet_count++;
	                }
	                print_hex(sendBuffer_1.buffer, sendBuffer_1.length, packet_count, CORE_1);
	            }
	        }

	        /*increase buffer pointer*/
	            pos_0 += dataSize_0;
	            pos_1 += dataSize_1;

	    } // end while(!last)

	    /*struct receive_packet // 8 bytes
	        {
	            char magic[8];
	            char buf_info[24];
	            char sig_no[4];
	            char sig_ID[4];
	            char sig_offset[4];
	        };
	    char recvbuff[64];
	    memset(recvbuff, 0, 64);
	    for(k = 0; k < packet_count; k++){
	        while ((DMA_PKT_MAGIC_NUMBER_0 != recvbuff[0]) | (DMA_PKT_MAGIC_NUMBER_1 != recvbuff[1]) | (DMA_PKT_MAGIC_NUMBER_2 != recvbuff[2])) {
	           int n = recvfrom(sock_rec,recvbuff,64,0,NULL,NULL);
	           if (n < 0) perror("ERROR reading from socket: ");
	        }

	        struct receive_packet *netfpga_header;
	        netfpga_header = (struct packet_header *)recvbuff;

	        char sig_no_str[4];
	        char sig_ID_str[4];
	        char sig_offset_str[4];
	        char sig_no_little[4];
	        char sig_ID_little[4];
	        int sig_no;
	        int sig_ID;
	        int sig_offset;
	        //if (strncmp(netfpga_header->magic,"\xFE\xCA\xAE\x01\xFF\xFF\xFF\x03",8) == 0)
	        if (strncmp(netfpga_header->magic,"\xFE\xCA\xAE\x01",4) == 0)
	        {
	            //PrintInHex("receive byte: ",recvbuff,n);
	            memcpy(sig_no_str,netfpga_header->sig_no,4);
	            memcpy(sig_ID_str,netfpga_header->sig_ID,4);
	            memcpy(sig_offset_str,netfpga_header->sig_offset,4);

	            ((char*)&sig_no_little)[0] = ((char*)&sig_no_str)[3];
	            ((char*)&sig_no_little)[1] = ((char*)&sig_no_str)[2];
	            ((char*)&sig_no_little)[2] = ((char*)&sig_no_str)[1];
	            ((char*)&sig_no_little)[3] = ((char*)&sig_no_str)[0];

	            ((char*)&sig_ID_little)[0] = ((char*)&sig_ID_str)[3];
	            ((char*)&sig_ID_little)[1] = ((char*)&sig_ID_str)[2];
	            ((char*)&sig_ID_little)[2] = ((char*)&sig_ID_str)[1];
	            ((char*)&sig_ID_little)[3] = ((char*)&sig_ID_str)[0];

	            sig_no = sig_no_little[3];
	            sig_no |= sig_no_little[2] << 8;
	            sig_no |= sig_no_little[1] << 16;
	            sig_no |= sig_no_little[0] << 24;

	            sig_ID = sig_ID_little[3];
	            sig_ID |= sig_ID_little[2] << 8;
	            sig_ID |= sig_ID_little[1] << 16;
	            sig_ID |= sig_ID_little[0] << 24;

	            //printf("sig_no = %d\n",sig_no);
	            if(sig_no == 1)
	            {
	                    char line[256];
	                    int virus_id;
	                    char const* const fileName = "/home/netfpga/thainguyen/database/store/db.map";
	                    FILE* file = fopen(fileName, "r");
	                    char *virus_name;
	                    while (fgets(line, sizeof(line), file) != NULL)
	                    {
	                        char *pos;
	                        if ((pos=strchr(line, '\n')) != NULL) *pos = '\0';
	                        strtok_r (line, ":", &virus_name);
	                        virus_id = atoi(line);
	                        if(virus_id == sig_ID ) break;
	                    }
	                    fclose(file);
	                    //printf("virus_name = %s\n",virus_name);
	                    *virname = virus_name;
	            }

	        }
	        return sig_no;

	    }//end for*/

}

void print_hex(unsigned char* buf, int count, int packet, char core)
{
	int i;
	printf("Core %d - packet #%d, size:%d \n",core,packet, count);
	for(i = 0; i < count; i++)
	{
		printf("%x ", buf[i]);
		if((i&0x1F) == 31) printf("\n");
	}
	printf("\n");
}

int file_exist (char *filename)
{
  struct stat   buffer;
  return (stat (filename, &buffer) == 0);
}
