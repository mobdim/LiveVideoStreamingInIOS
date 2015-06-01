    
//  Rtmp.m
//  RtmpClient

#import "Rtmp.h"
#import "Amf.h"
#include "Capture.h"
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libavdevice/avdevice.h"
#include "libavfilter/avfilter.h"
#import "RtmpClientAppDelegate.h"

unsigned char *temp;
int chunksize = 128, avflag = 0, setchunksize = 0;
void hexToBinary (unsigned char hex, int binary[4], int index);
int binaryToDecimal (int binary[10], int sindex, int limit);
int HexToDecimal(unsigned char binary[10], int sindex, int limit);
void DecimalToHex(int decimal, unsigned char hexdata[4],int index);

@implementation Rtmp

- (id)init
{
        self = [super init];
        if (self) {
                // Initialization code here.
        }
        
        return self;
}
			
-(void) startThread :(NSArray *)input
{
        NSThread *rthread = [[NSThread alloc] initWithTarget:self selector:@selector(rtmpConnect:) object:input];
        [rthread start];
}

-(void) HandShake :(int) sock
{
        int BUFSIZE = 1536;
        unsigned char array[BUFSIZE + 1];
        int i;
        unsigned char array1[3073],array2[BUFSIZE];
        memset(array1, 3, 3073);
        memset(array, 0, 1537);
        array[0] = 0x03; 
                
        write(sock, array, sizeof(array));                          //client sends 1536 bytes followed by 0x03 
        size_t s = 0;
        unsigned char *tempH = array1;
        int start = sizeof(array1);
        do                      
        {
                s=read(sock,tempH,start);                              
                start -= s;
                tempH += s;
        }while (s > 0);                                              //client receives 3073 bytes from server   
        
        for (i=1;i<1537;i++)
        {
                array2[i-1] = array1[i];
        }
        write(sock,array2,sizeof(array2));                         //client sends 1536 bytes to server (Server generated i.e 1st 1536 bytes)
}

-(void) rtmpConnect :(NSArray *)input                               //input array contains the user input
{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        unsigned char *buffer = malloc(400);
        unsigned char *sendbytes = malloc(400);
        unsigned char hexData[3];
        int c = 0,i,j,count = 0,sock;
        NSString *app,*flashver,*swfurl,*pageurl,*tcurl;
        
        
        NSNumber *sockid = [input objectAtIndex:0];
        sock = [sockid intValue];
        app = [input objectAtIndex:1];
        flashver = [input objectAtIndex:2];
        swfurl = [input objectAtIndex:3];
        tcurl = [input objectAtIndex:4];
        pageurl = [input objectAtIndex:5];
        
        Amf *amfObj = [[Amf alloc] init];
        
        memset(sendbytes, 0, 345);
        
               
        temp = sendbytes;                                                       //sendbytes contains the AMF bytes of connect property which is pointed by temp
        
        *temp = 0x02; temp++; c++;
        c = [amfObj amfSerialization:@"connect" andB:temp andC:c];
        
        c = [amfObj amfSerialization:@"1" andB:temp andC:c];
        
        *temp = 0x03; temp++; c++;
        
        c = [amfObj amfSerialization:@"app" andB:temp andC:c];
        *temp = 0x02; temp++; c++;
        c = [amfObj amfSerialization:app andB:temp andC:c];
        
        c = [amfObj amfSerialization:@"flashVer" andB:temp andC:c];
        *temp = 0x02; temp++; c++;
        c = [amfObj amfSerialization:flashver andB:temp andC:c];
        
        c = [amfObj amfSerialization:@"swfUrl" andB:temp andC:c];
        *temp = 0x02; temp++; c++;
        c = [amfObj amfSerialization:swfurl andB:temp andC:c];
        
        c = [amfObj amfSerialization:@"tcUrl" andB:temp andC:c];
        *temp = 0x02; temp++; c++;
        c = [amfObj amfSerialization:tcurl andB:temp andC:c];
      
        c = [amfObj amfSerialization:@"fpad" andB:temp andC:c];
        *temp = 0x01; temp++; c++; //amf type boolean
        *temp = 0x00; temp++; c++;
        
        c = [amfObj amfSerialization:@"capabilities" andB:temp andC:c];
        c = [amfObj amfSerialization:@"239" andB:temp andC:c];
        
        c = [amfObj amfSerialization:@"audioCodecs" andB:temp andC:c];
        c = [amfObj amfSerialization:@"3575" andB:temp andC:c];
        
        c = [amfObj amfSerialization:@"videoCodecs" andB:temp andC:c];
        c = [amfObj amfSerialization:@"252" andB:temp andC:c];
        
        c = [amfObj amfSerialization:@"videoFunction" andB:temp andC:c];
        c = [amfObj amfSerialization:@"1" andB:temp andC:c];
        
        c = [amfObj amfSerialization:@"pageUrl" andB:temp andC:c];
        *temp = 0x02; temp++; c++;
        c = [amfObj amfSerialization:pageurl andB:temp andC:c];
        
        *temp = 0x00; temp++; c++; 
        *temp = 0x00; temp++; c++;
        *temp = 0x09; temp++; c++;
        
        DecimalToHex(c, hexData,6);
        printf("\n\nHex Data : %d %x %x %x",c-1,hexData[0],hexData[1],hexData[2]);
        
        buffer[0] = 0x03; count++; 
        buffer[1] = 0x00; count++; 
        buffer[2] = 0x00; count++; 
        buffer[3] = 0x00; count++; 
        buffer[4] = hexData[0]; count++; 
        buffer[5] = hexData[1]; count++; 
        buffer[6] = hexData[2]; count++; 
        buffer[7] = 0x14; count++; 
        buffer[8] = 0x00; count++; 
        buffer[9] = 0x00; count++; 
        buffer[10] = 0x00; count++; 
        buffer[11] = 0x00; count++;
        

        
        for (i = count,j = 0; j <= c; j++,i++)
        {
                if( j % 128 == 0 && j != 0)
                {
                        buffer[i] = 0xc3;
                        i++;
                        count++;
                }
                buffer[i] = sendbytes[j];
                count++;
        }
        
        
        write(sock,buffer,count - 1);
        
        free(sendbytes);
        //[Amf initAudio];
        [Amf initVideo];   
        

        [Rtmp createStream:sock];
        
        if(choice == 1)
        {
                [Rtmp publish: sock];
                /* add a sub view to the main window */

                RtmpClientAppDelegate *delegate = (RtmpClientAppDelegate *)[UIApplication sharedApplication].delegate;
                
                Capture *captureObj = [[Capture alloc] init];
                [captureObj captureVideo];
                
                [delegate.window addSubview:captureObj.view];
        }
        else if (choice == 2 ) 
                [Rtmp play:sock];
        else if (choice == 3)
        {
                for ( int i = 0; i < 25 ;i++)
                {
                        buffer[i] = '\0';
                }
                buffer[0] = 0x42;
                buffer[1] = 0x00;
                buffer[2] = 0x00;
                buffer[3] = 0x00;
                buffer[4] = 0x00;
                buffer[5] = 0x00;
                buffer[6] = 0x0a;
                buffer[7] = 0x04;
                buffer[8] = 0x00;
                buffer[9] = 0x03;
                buffer[10] = 0x00;
                buffer[11] = 0x00;
                buffer[12] = 0x00;
                buffer[13] = 0x00;
                buffer[14] = 0x00;
                buffer[15] = 0x00;
                buffer[16] = 0x13;
                buffer[17] = 0x88;
                
                write(sock, buffer, 18);
                
                [Rtmp playStream:sock];
                
                for ( int i = 0; i < 25 ;i++)
                {
                        buffer[i] = '\0';
                }
                buffer[0] = 0xc2;
                buffer[1] = 0x00;
                buffer[2] = 0x03;
                buffer[3] = 0x00;
                buffer[4] = 0x00;
                buffer[5] = 0x00;
                buffer[6] = 0x01;
                buffer[7] = 0x00;
                buffer[8] = 0x00;
                buffer[9] = 0x13;
                buffer[10] = 0x88;
                
                write(sock, buffer, 11);
                

        }
        free(buffer);
        [amfObj release];
        [pool release];
}



-(void) extractPacket:(int)sock andF:(unsigned char *)fbyte
{
        int bin[8],i ,s, hlen, j = 0, k, c = 0, ignore = 0, packetsize;
        unsigned char hsize, oid, ctype, quo, mod, header[12], bsize[6], tstamp[6],pingResponse[50],flvPacketHeader[11], flvPacketFooter[4], hexdata[4];
        unsigned int bodysize, time;
        NSString  *sid = @"", *tempstr;//*timestamp = @"",
        Amf *amfObj = [[Amf alloc] init];
        Rtmp *rtmpObj = [[Rtmp alloc] init];
        
        for (i=0; i <8; i++)
        {      
                bin[i] = 0;
        }
        oid = fbyte[0] % 0x10;
        hsize = fbyte[0] / 0x10;
        hexToBinary(hsize, bin, 0);
        hexToBinary(oid, bin, 4);
        printf("\nFirst Byte: ");
        
        
        if (bin[0] == 0 && bin[1] == 0) 
        {
                printf("\n\n-----------------------------------------12 byte header--------------------------------------------\n");
                
                hlen = 12;
                s = read(sock, header, hlen - 1);
                printf("\nHeader: ");
                for (i = 0; i < s; i++)
                {
                        printf(" %x", header[i]);
                }
                
                for (i = 0, k = 0; i < 3; i++ )
                {
                        quo = header[i] / 0x10;
                        mod = header[i] % 0x10;
                        tstamp[k] = quo;
                        k++;
                        tstamp[k] = mod;
                        k++;
                }
                time = HexToDecimal(tstamp, 0, 6);
                
                for (i = 3, k = 0;i < 6; i++)
                {
                        quo = header[i] / 0x10;
                        mod = header[i] % 0x10;
                        bsize[k] = quo;
                        k++;
                        bsize[k] = mod;
                        k++;
                }
                bodysize = HexToDecimal(bsize, 0, 6);
                printf("\nbodysize: %d",bodysize);
                
                
                ctype = header[6];
                printf("\nCTYPE: %x",ctype);
                
                
                
                sid = [sid stringByAppendingFormat:@"%x", header[7]];         
                sid = [sid stringByAppendingFormat:@"%x", header[8]];
                sid = [sid stringByAppendingFormat:@"%x", header[9]];
                sid = [sid stringByAppendingFormat:@"%x", header[10]];
                
                NSLog(@"\nStreamID: %@", sid);
                printf("\n(DELTA) TimeStamp Audio %d \nTimestamp Video %d\n", timestamp[0][0], timestamp[1][0]);
                printf("\n(CALCULATED) TimeStamp Audio %d \nTimestamp Video %d\n", timestamp[0][1], timestamp[1][1]);
                
            
                
                ignore = [rtmpObj contentType:ctype andB:bin andS:bodysize andTs:time andH:hlen];
        }
        else if (bin[0] == 0 && bin[1] == 1) 
        {
                printf("\n\n----------------------------------------8 byte header--------------------------------------------\n");
                
                hlen = 8;
                s = read(sock, header, hlen - 1);
                 printf("\nHeader: ");
                for (i = 0; i < s; i++)
                {
                        printf(" %x", header[i]);
                }
                
                for (i = 0, k = 0; i < 3; i++ )
                {
                        quo = header[i] / 0x10;
                        mod = header[i] % 0x10;
                        tstamp[k] = quo;
                        k++;
                        tstamp[k] = mod;
                        k++;
                }
                time = HexToDecimal(tstamp, 0, 6);
                
                for (i = 3, k = 0;i < 6; i++)
                {
                        quo = header[i] / 0x10;
                        mod = header[i] % 0x10;
                        bsize[k] = quo;
                        k++;
                        bsize[k] = mod;
                        k++;
                }
                bodysize = HexToDecimal(bsize, 0, 6);
                printf("\nbodysize: %d",bodysize);
                
                
                ctype = header[6];
                printf("\nCTYPE: %x",ctype);
                
                printf("\n(DELTA) TimeStamp Audio %d \nTimestamp Video %d\n", timestamp[0][0], timestamp[1][0]);
                printf("\n(CALCULATED) TimeStamp Audio %d \nTimestamp Video %d\n", timestamp[0][1], timestamp[1][1]);
                               
                ignore = [rtmpObj contentType:ctype andB:bin andS:bodysize andTs:time andH:hlen];
        }
        else if(bin[0] == 1 && bin[1] == 0)
        {
                printf("\n--------------------------------------4 byte header-------------------------------------------------");
                hlen = 4;
                
                s = read(sock, header, hlen - 1);
                
                printf("\nHeader: ");
                for (i = 0; i < s; i++)
                {
                        printf(" %x", header[i]);
                }
                

                for (i = 0, k = 0;i < 3; i++)
                {
                        quo = header[i] / 0x10;
                        mod = header[i] % 0x10;
                        tstamp[k] = quo;
                        k++;
                        tstamp[k] = mod;
                        k++;
                }
                time = HexToDecimal(tstamp, 0, 6);
                
                 
                 NSString *b1 = @"";
                 b1 = [NSString stringWithFormat:@"%x",fbyte[0]];
                 NSLog(@"\nb1:::::%@",b1);
                 
                 
                 if ([b1 compare:[fourByteheader objectAtIndex:4]] == 0) 
                 {
                         ignore = 1;
                         bodysize = [[setbodysize objectAtIndex:4] intValue];
                         ctype = 0x04;
                 }
                 else if ([b1 compare:[fourByteheader objectAtIndex:8]] == 0) 
                 {
                         ignore = 0;
                         bodysize = [[setbodysize objectAtIndex:8] intValue];
                         timestamp[0][0] = time;    //assigning timestamp for AUDIO packet in globol array
                         timestamp[0][1] = timestamp[0][1] + time;
                         ctype = 0x08;
                 }
                 else if ([b1 compare:[fourByteheader objectAtIndex:9]] == 0) 
                 {
                         ignore = 0;
                         bodysize = [[setbodysize objectAtIndex:9] intValue];
                         timestamp[1][0] = time;    //assigning timestamp for VIDEO packet in globol array
                         timestamp[1][1] = timestamp[1][1] + time;
                         ctype = 0x09;
                 }
                 else
                 {
                         ignore = 0;
                 }
                 printf("\n(DELTA) TimeStamp Audio %d \nTimestamp Video %d\n", timestamp[0][0], timestamp[1][0]);
                 printf("\n(CALCULATED) TimeStamp Audio %d \nTimestamp Video %d\n", timestamp[0][1], timestamp[1][1]);
              
        }
        
        else if(bin[0] == 1 && bin[1] == 1)
        {
                printf("\n\n---------------------------------------1 byte header-----------------------------------------------");
                
                hlen = 1;
        
                NSString *b1 = @"";
                b1 = [NSString stringWithFormat:@"%x",fbyte[0]];
                NSLog(@"\nb1:::::%@",b1);
                
                
                if ([b1 compare:[oneByteheader objectAtIndex:4]] == 0) 
                {
                        ignore = 1;
                        bodysize = [[setbodysize objectAtIndex:4] intValue];
                        ctype = 0x04;
                }
                else if ([b1 compare:[oneByteheader objectAtIndex:8]] == 0) 
                {
                        ignore = 0;
                        bodysize = [[setbodysize objectAtIndex:8] intValue];
                        timestamp[0][1] = timestamp[0][1] + timestamp[0][0];
                        ctype = 0x08;
                }
                else if ([b1 compare:[oneByteheader objectAtIndex:9]] == 0) 
                {
                        ignore = 0;
                        bodysize = [[setbodysize objectAtIndex:9] intValue];
                        timestamp[1][1] = timestamp[1][1] + timestamp[1][0];
                        ctype = 0x09;
                }
                else
                {
                        ignore = 0;                                
                }
                printf("\n(DELTA) TimeStamp Audio %d \nTimestamp Video %d\n", timestamp[0][0], timestamp[1][0]);
                printf("\n(CALCULATED) TimeStamp Audio %d \nTimestamp Video %d\n", timestamp[0][1], timestamp[1][1]);
                
               
        }
        else
        {
                printf("\n");
        }
        
               
        c = 0;
        c = bodysize / chunksize;
        packetsize = bodysize + c;
        
        unsigned char *recev = malloc(sizeof(unsigned char) * packetsize);
        unsigned char *packetdata = malloc(sizeof(unsigned char) * bodysize); 

        s = read(sock, recev, packetsize);
        
        
        if(setchunksize == 1)
        {
                unsigned char hexdata[10], quo, mod;
                printf("\nSet chunk Size");
                for (i = 0; i < 10; i++)
                {
                        hexdata[i] = '\0';
                }
                for (i = 0, k = 0;i < bodysize; i++, j++)
                {
                        quo = recev[i] / 0x10;
                        mod = recev[i] % 0x10;
                        hexdata[k] = quo;
                        k++;
                        hexdata[k] = mod;
                        k++;
                }
                chunksize = HexToDecimal(hexdata, 0, 8);
                setchunksize = 0;
        }
        
        if (hlen == 4 || hlen == 1)          //avflag is set to separate audio and video packet from other packets with header of 4 and 1 byte.
        {
                tempstr = [NSString stringWithFormat:@"%x",fbyte[0]];
                if(([tempstr compare: [oneByteheader objectAtIndex:8]] == 0) || ([tempstr compare: [oneByteheader objectAtIndex:9]] == 0) || ([tempstr compare: [fourByteheader objectAtIndex:8]] == 0) || ([tempstr compare: [fourByteheader objectAtIndex:9]] == 0))
                        
                {       
                        avflag = 1;
                }
                else
                {
                        avflag = 0;
                }
        }
        
        for (i = 0; i < bodysize; i++) 
        {
                packetdata[i] = '\0';
        }

        for (i = 0,j=0; i < packetsize; i++,j++)
        {
                if( j % chunksize == 0 && j != 0)
                {
                        i++;
                }
                packetdata[j] = recev[i];
        }
        
        if (ignore == 0) 
        {
                if (avflag == 1)
                {
                        flvPacketHeader[0] = ctype;
                        DecimalToHex(bodysize, hexdata,8);
                        int p = 1;
                        for ( int q = 1 ; q < 4; q++)
                        {
                                flvPacketHeader[p] = hexdata[q];
                                p++;
                        }
                        if (ctype == 0x12)
                        {       
                                DecimalToHex(0, hexdata,8);
                        }
                        else if(ctype == 0x09)
                        {
                                DecimalToHex(timestamp[1][1], hexdata,8);
                        }
                        else if(ctype == 0x08)
                        {
                                DecimalToHex(timestamp[0][1], hexdata,8);
                        }
                        for ( int q = 1 ; q < 4; q++)
                        {
                                flvPacketHeader[p] = hexdata[q];
                                p++;
                        }
                        flvPacketHeader[p] = 0x00; p++;
                        flvPacketHeader[p] = 0x00; p++;
                        flvPacketHeader[p] = 0x00; p++;
                        flvPacketHeader[p] = 0x00; p++;
                
                
                
                        DecimalToHex(bodysize + 11, hexdata,8);
                        for (int q = 0; q < 4; q++) 
                        {
                                flvPacketFooter[q] = hexdata[q];
                        }

                }
                [amfObj amfDeSerialization: packetdata andX: bodysize andF: avflag andH:flvPacketHeader andT:flvPacketFooter];
        }
        else if (ignore == 1)
        {
                
                if( packetdata[0] == 0x00 && packetdata[1] == 0x06)
                {
                        pingResponse[0] = 0x42;                                 //PING RESPONSE :need to check for other video packets
                        pingResponse[1] = 0x00;
                        pingResponse[2] = 0x00;
                        pingResponse[3] = 0x00;
                        pingResponse[4] = 0x00;
                        pingResponse[5] = 0x00;
                        pingResponse[6] = 0x06;
                        pingResponse[7] = 0x04;
                        pingResponse[8] = 0x00;
                        pingResponse[9] = 0x07;
                        pingResponse[10] = packetdata[2];
                        pingResponse[11] = packetdata[3];
                        pingResponse[12] = packetdata[4];
                        pingResponse[13] = packetdata[5];
                        
                        write(sock, pingResponse, 14);
                        
                        printf("\n Ping Response Sent:::::");
                }
                else
                        printf("\n Ignore deserialization");
        }
        else
        {
                printf("\n ACK Ignore deserialization");
        }
        avflag = 0;

}

+(void) publish: (int) sock;
{
        unsigned char buffer[200], sendbytes[200];
        int c = 0, count = 0, i, j;
        Amf *amfObj = [[Amf alloc] init];
        
        buffer[0] = 0x08; c++;
        buffer[1] = 0x00; c++;
        buffer[2] = 0x00; c++;
        buffer[3] = 0x71; c++;
        buffer[4] = 0x00; c++;
        buffer[5] = 0x00; c++;
        buffer[6] = 0x2c; c++;
        buffer[7] = 0x14; c++;
        buffer[8] = 0x01; c++;
        buffer[9] = 0x00; c++;
        buffer[10] = 0x00; c++;
        buffer[11] = 0x00; c++;
        
        temp = sendbytes;
        *temp  = 0x02; count++; temp++;
        count = [amfObj amfSerialization:@"publish" andB:temp andC:count];
        count = [amfObj amfSerialization:@"0" andB:temp andC:count];
        *temp = 0x05; count++; temp++;  
        
        *temp  = 0x02; count++; temp++;
        count = [amfObj amfSerialization:@"red5StreamDemo" andB:temp andC:count]; //Resource name to which the string is to be attached
        *temp  = 0x02; count++; temp++;
        count = [amfObj amfSerialization:@"live" andB:temp andC:count];
        count++; temp++;
        
        for (i = c,j = 0; j <= count; j++,i++)
        {
                if( j % 128 == 0 && j != 0)
                {
                        buffer[i] = 0xc3;
                        i++;
                        c++;
                }
                buffer[i] = sendbytes[j];
                c++;
        }
        
        
         write(sock,buffer,c-2);
         [amfObj release];

}

+(void) createStream: (int) sock
{
       // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        unsigned char buffer[200], sendbytes[200];
        int count = 0, c = 0, i, j;
        Amf *amfObj = [[Amf alloc] init];
        
        buffer[0] = 0x03; c++;
        buffer[1] = 0x00; c++;
        buffer[2] = 0x00; c++;
        buffer[3] = 0x59; c++;
        buffer[4] = 0x00; c++;
        buffer[5] = 0x00; c++;
        buffer[6] = 0x19; c++;
        buffer[7] = 0x14; c++;
        buffer[8] = 0x00; c++;
        buffer[9] = 0x00; c++;
        buffer[10] = 0x00; c++;
        buffer[11] = 0x00; c++;

        temp = sendbytes;
        *temp  = 0x02; count++; temp++;
        count = [amfObj amfSerialization:@"createStream" andB:temp andC:count];
        
        if( choice == 2 || choice == 1)
                count = [amfObj amfSerialization:@"2" andB:temp andC:count];
        else if(choice == 3)
                count = [amfObj amfSerialization:@"3" andB:temp andC:count];

        *temp = 0x05; count++; temp++;                                              //0x05 indicates AMF type for null marker
        
        for (i = c,j = 0; j <= count; j++,i++)
        {
                if( j % 128 == 0 && j != 0)
                {
                        buffer[i] = 0xc3;
                        i++;
                        c++;
                }
                buffer[i] = sendbytes[j];
                c++;
        }
        
        
        write(sock,buffer,c-1);
        
        [amfObj release];
       //[pool release];

}

+(void) play: (int) sock
{
        unsigned char buffer[200], sendbytes[200];
        int count = 0, c = 0, i, j;
        Amf *amfObj = [[Amf alloc] init];
        
        buffer[0] = 0x08; c++;
        buffer[1] = 0x00; c++;
        buffer[2] = 0x00; c++;
        buffer[3] = 0x27; c++;
        buffer[4] = 0x00; c++;
        buffer[5] = 0x00; c++;
        buffer[6] = 0x2b; c++;
        buffer[7] = 0x14; c++;
        buffer[8] = 0x01; c++;
        buffer[9] = 0x00; c++;
        buffer[10] = 0x00; c++;
        buffer[11] = 0x00; c++;
        
        
        temp = sendbytes;
        *temp  = 0x02; count++; temp++;
        count = [amfObj amfSerialization:@"play" andB:temp andC:count];
        count = [amfObj amfSerialization:@"0" andB:temp andC:count];
        *temp = 0x05; count++; temp++;      //0x05 indicates AMF type for null marker
        
        
        *temp  = 0x02; count++; temp++;
        count = [amfObj amfSerialization:@"red5StreamDemo" andB:temp andC:count];
        count = [amfObj amfSerialization:@"-1000" andB:temp andC:count];
        
        
        for (i = c,j = 0; j <= count; j++,i++)
        {
                if( j % 128 == 0 && j != 0)
                {
                        buffer[i] = 0xc3;
                        i++;
                        c++;
                }
                buffer[i] = sendbytes[j];
                c++;
        }
        
        
        printf("\n\nbuffer in play::::::::\n");
        for (i=0;i<c-1;i++)
        {
                if((i + 1) % 16 == 1 && i != 1)
                        printf("\n");
                printf("%X\t",buffer[i]);
        }
        
        int len = write(sock,buffer,c-1);
        printf("\n\n Len in Play:: %d",len);
        [amfObj release];
        
}

+(void) playStream: (int) sock
{
        unsigned char buffer[200], sendbytes[200];
        int c = 0, count = 0, i, j;
        Amf *amfObj = [[Amf alloc] init];
        
        buffer[0] = 0x08; c++;
        buffer[1] = 0x00; c++;
        buffer[2] = 0x0f; c++;
        buffer[3] = 0x9a; c++;
        buffer[4] = 0x00; c++;
        buffer[5] = 0x00; c++;
        buffer[6] = 0x1e; c++;
        buffer[7] = 0x14; c++;
        buffer[8] = 0x01; c++;
        buffer[9] = 0x00; c++;
        buffer[10] = 0x00; c++;
        buffer[11] = 0x00; c++;
        
        temp = sendbytes;
        *temp  = 0x02; count++; temp++;
        count = [amfObj amfSerialization:@"play" andB:temp andC:count];
        count = [amfObj amfSerialization:@"0" andB:temp andC:count];
        *temp = 0x05; count++; temp++;  
        
        *temp  = 0x02; count++; temp++;
        count = [amfObj amfSerialization:@"avatar.flv" andB:temp andC:count];
        count++; temp++;
        
        for (i = c,j = 0; j <= count; j++,i++)
        {
                if( j % 128 == 0 && j != 0)
                {
                        buffer[i] = 0xc3;
                        i++;
                        c++;
                }
                buffer[i] = sendbytes[j];
                c++;
        }
       
        write(sock,buffer,c-2);
        [amfObj release];
}


-(int) contentType: (unsigned char) cType andB :(int [])bin andS :(int)bodysize andTs:(int)time andH:(int)hlen
{
        int i, ignore = 0 , temp[8], h1 = 0, h2 = 0;
        NSString *head1  = @"", *head4 = @"";
        NSNumber *bsize;
        
        switch(cType) 
        {
                case 0x01:
                        setchunksize = 1;
                        printf("\nSet Chunk size");
                        break;
                        
                case 0x03:
                        printf("\nAcknowledgement3481");
                        ignore = 999;
                        break;
                        
                case 0x04:
                        printf("\nPing Packet");
                        head1 = @"";
                        head4 = @"";
                        ignore = 1;
                        
                        temp[0] = 1;                                                    // for one byte header
                        temp[1] = 1;
                        for (i = 2; i < 8; i++) 
                        {
                                temp[i] = bin[i];
                        }
                        h1 = binaryToDecimal(temp, 0, 4);
                        h2 = binaryToDecimal(temp, 4, 4);
                        head1 = [head1 stringByAppendingFormat:@"%x", h1];
                        head1 = [head1 stringByAppendingFormat:@"%x", h2];
                        NSLog(@"\nheader1:::::%@",head1);
                        [oneByteheader replaceObjectAtIndex:4 withObject:head1];
                        
                        
                        
                        temp[0] = 1;                                                    // for four byte header
                        temp[1] = 0;
                        h1 = binaryToDecimal(temp, 0, 4);
                        h2 = binaryToDecimal(temp, 4, 4);
                        head4 = [head4 stringByAppendingFormat:@"%x", h1];
                        head4 = [head4 stringByAppendingFormat:@"%x", h2];
                        NSLog(@"\nheader4:::::%@",head4);
                        [fourByteheader replaceObjectAtIndex:4 withObject:head4];
                        
                        
                        
                        bsize = [NSNumber numberWithInt:bodysize];                      // it will be used for both one byte header and four byte header
                        [setbodysize replaceObjectAtIndex:4 withObject:bsize];
                       
                        break; 
                        
                case 0x08:
                        printf("\n--------------Audio Packet--------------");
                        head1 = @"";
                        head4 = @"";
                        ignore = 0;
                        avflag = 1;
                        
                        temp[0] = 1;                                                    // for one byte header
                        temp[1] = 1;
                        for (i = 2; i<8; i++) 
                        {
                                temp[i] = bin[i];
                        }
                        h1 = binaryToDecimal(temp, 0, 4);
                        h2 = binaryToDecimal(temp, 4, 4);
                        head1 = [head1 stringByAppendingFormat:@"%x", h1];
                        head1 = [head1 stringByAppendingFormat:@"%x", h2];
                        [oneByteheader replaceObjectAtIndex:8 withObject:head1];
                        
                        temp[0] = 1;                                                    // for four byte header
                        temp[1] = 0;
                        h1 = binaryToDecimal(temp, 0, 4);
                        h2 = binaryToDecimal(temp, 4, 4);
                        head4 = [head4 stringByAppendingFormat:@"%x", h1];
                        head4 = [head4 stringByAppendingFormat:@"%x", h2];
                        [fourByteheader replaceObjectAtIndex:8 withObject:head4];
                        
                        
                        bsize = [NSNumber numberWithInt:bodysize];                       // it will be used for both one byte header and four byte header
                        [setbodysize replaceObjectAtIndex:8 withObject:bsize];
                        /*if(hlen == 12)
                        {
                                timestamp[0][0] = time;                   //assigning timestamp delta for AUDIO packet in globol array
                                timestamp[0][1] = time;  
                        }
                        else 
                        {*/
                                timestamp[0][0] = time;                   //assigning timestamp delta for AUDIO packet in globol array
                                timestamp[0][1] = timestamp[0][1] + time;
                        //}
                        break;
                        
                case 0x09:
                        printf("\n-----------------Video Packet------------------");
                        head1 = @"";
                        head4 = @"";
                        ignore = 0;
                        avflag = 1;
                        
                        temp[0] = 1;                                                    // for one byte header
                        temp[1] = 1;
                        for (i = 2; i<8; i++) 
                        {
                                temp[i] = bin[i];
                        }
                        h1 = binaryToDecimal(temp, 0, 4);
                        h2 = binaryToDecimal(temp, 4, 4);
                        head1 = [head1 stringByAppendingFormat:@"%x", h1];
                        head1 = [head1 stringByAppendingFormat:@"%x", h2];
                        [oneByteheader replaceObjectAtIndex:9 withObject:head1];
                        
                        temp[0] = 1;                                                    // for four byte header
                        temp[1] = 0;
                        h1 = binaryToDecimal(temp, 0, 4);
                        h2 = binaryToDecimal(temp, 4, 4);
                        head4  = [head4 stringByAppendingFormat:@"%x", h1];
                        head4  = [head4  stringByAppendingFormat:@"%x", h2];
                        [fourByteheader replaceObjectAtIndex:9 withObject:head4];
                        
                        
                        
                        bsize = [NSNumber numberWithInt:bodysize];                      // it will be used for both one byte header and four byte header
                        [setbodysize replaceObjectAtIndex:9 withObject:bsize];
                        /*if(hlen == 12)
                        {
                                timestamp[1][0] = time;                   //assigning timestamp delta for VIDEO packet in globol array
                                timestamp[1][1] = time;
                        }
                        else
                        {*/
                                timestamp[1][0] = time;                   //assigning timestamp delta for VIDEO packet in globol array
                                timestamp[1][1] = timestamp[1][1] + time;
                        //}
                        break;
                        
                case 0x12:
                        printf("\n0x12 AMF type");
                        //avflag = 1;
                        
                        break;
                        
                case 0x14:
                        printf("\nRemote Procedure Call");
                        ignore = 0;
                        break;
                        
                default:
                        break;
        }
        return ignore;
}

void hexToBinary(unsigned char hex, int binary[4], int index)
{
        int i = index + 3, number;
        number = hex;
        while (number > 0) 
        {
                binary[i] = number  % 2;
                number = number / 2;
                i--;
        }
}

int binaryToDecimal(int binary[10], int sindex, int limit)
{
        int i, j, deci = 0;
        for (i = sindex + limit - 1,j = 0; i >= sindex ; i--,j++) 
        {
                deci = deci + binary[i] * pow(2, j);
        }                          
        return deci;
}

int HexToDecimal(unsigned char hexdata[10], int sindex, int limit)
{
        int i, j, deci = 0;
        for (i = sindex + limit - 1,j = 0; i >= sindex ; i--,j++) 
        {
                deci = deci + hexdata[i] * pow(16, j);
        }   
        return deci;
}

void DecimalToHex(int decimal, unsigned char hexdata[4], int index)
{
        int i = index - 1,j = 0;
        unsigned char rem[index];
        while (decimal > 0) 
        {
                rem[i] = decimal  % 16;
                decimal = decimal / 16;
                
                i--;
        }  
        for(j = i ;j >=0 ;j--)
        {
                rem[j] = 0x00;
        }
        j = 0;
        for ( i = 0;i < index ;i = i + 2)
        {
                hexdata[j] = (rem[i] * 0x10) + rem[i + 1];
                j++;
        }
        
}
@end
