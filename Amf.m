
//  Amf.m
//  RtmpClient
    
#import "Amf.h"
#import "Rtmp.h"
#import <CoreFoundation/CoreFoundation.h>
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libavutil/avutil.h"
#include "libavdevice/avdevice.h"
#include "libswscale/swscale.h"
#include "zlib.h"
#include<sys/types.h>
#include<netinet/in.h>
#include<sys/socket.h>
#include<sys/stat.h>
#include<unistd.h>
#include<time.h>
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include <AVFoundation/AVPlayer.h>
#include <AudioToolbox/AudioToolbox.h>
#import "RtmpClientAppDelegate.h"
#include <AudioToolbox/AudioQueue.h>
#include <AudioToolbox/AudioFileStream.h>

#define AUDIO_BUFFERS 3
#define BYTES_PER_SAMPLE 2
#define SAMPLE_RATE 11025


typedef unsigned short sampleFrame;

typedef struct AQCallbackStruct {
        AudioQueueRef mQueue;
        UInt32 frameCount;
        AudioQueueBufferRef mBuffers[AUDIO_BUFFERS];
        AudioStreamBasicDescription mDataFormat;
        int sBodysize;
        UInt32 playPtr;
        UInt32 sampleLen;
        sampleFrame *pcmBuffer;
} AQCallbackStruct;
AQCallbackStruct aqc;
OSStatus err;

unsigned char *temp;
int frame = 0, frame1 = 0, count1 = 0, total = 0,audioPacket = 0, videoPacket = 0, count = 0;
char *outfilename = "/Users/Sweta/Documents/Final Year Project/temp/test%d.jpg";

//void AQBufferCallback1(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inCompleteAQBuffer);

@implementation Amf

- (id)init
{
        self = [super init];
        if (self) {
                NSLog(@"AMF Initialize");
        }
        
        return self;
}
-(int) amfSerialization :(NSString *)property andB:(unsigned char *)temp andC:(int)count
{
        double num;
        char c;
        const char *temp1;
                
        c=[property characterAtIndex:0];
        
        if((c >= 97 && c <= 122) || (c>=65 && c<=90))
        {
                
                temp1 = [property UTF8String];
                count = [Amf amfString:temp1 andC:count];
        }
        else if ((c >= 48 && c <= 57)||c=='-')
        {
                
                num = [property doubleValue];
                count = [Amf amfNumber:num andC:count];
        }
                
        return count;
}


+(int) amfString :(const char *)temp1 andC :(int) count                                //AMF Serialization for String. 
{
        int i;
        size_t length;

        length = strlen(temp1);
        
        
        *temp = 0x00; temp++; count++;
        
        *temp = length; temp++; count++;
        for (i=0; i<length; i++)
        {
                
                *temp = *temp1;
                temp1++;
                temp++;
                count++;
                
        }
        
        return count;
}


+(int) amfNumber :(double)num andC :(int) count                                         //AMF Serialization for Number.
{
        void *pointer = &num;
        *temp = 0x00; temp++; count++;
        
        for(int i = 7; i >= 0; i--)
        {
                *temp = ((unsigned char *)pointer)[i]; 
                temp++;
                count++;
        }
        return count;
}


+(void) initVideo
{
        
        printf("\n\n In INIT VIDEO");
        avcodec_init();
        avcodec_register_all();
        av_register_all();
        avformat_alloc_context();
        pCodec=avcodec_find_decoder(CODEC_ID_FLV1);
        if(pCodec==NULL)
                printf("\nCodec not found video");
        
        aCodec1 = avcodec_find_decoder(CODEC_ID_MP3);
        if(aCodec1 == NULL)
                printf("\n Codec not found for audio");

    
        pCodecCtx = avcodec_alloc_context();
        aCodecCtx = avcodec_alloc_context();
        ctx = avcodec_alloc_context();

        
        pCodecCtx -> height = 240;
        pCodecCtx -> width = 320;
        pCodecCtx -> codec_id = CODEC_ID_FLV1;
        pCodecCtx -> codec_type = CODEC_TYPE_VIDEO;
        pCodecCtx -> time_base.den = 1000;
        pCodecCtx -> time_base.num = 23976;
        //pCodecCtx -> sample_rate = 11025;
        //pCodecCtx -> channels = 0;
        
        aCodecCtx -> sample_rate = 11025;
        aCodecCtx -> channels = 0;
        aCodecCtx -> codec_id = CODEC_ID_MP3;
        aCodecCtx -> codec_type = CODEC_TYPE_AUDIO;
        aCodecCtx -> time_base.den = 1000;
        aCodecCtx -> time_base.num = 23976;
        
        ctx -> bit_rate = 128000;
        ctx -> width = 320;
        ctx -> height = 240;
        ctx -> sample_rate = 11025;
        //ctx -> time_base.den = 1000;
        //ctx -> time_base.num = 23976;
        ctx -> codec_id = CODEC_ID_FLV1;
        ctx -> codec_type = CODEC_TYPE_VIDEO;
        ctx->time_base= (AVRational){1,24};
        //ctx->gop_size = 1; 
        //ctx->max_b_frames=1;
        ctx->pix_fmt = PIX_FMT_YUV420P;
        //ctx -> mb_decision = 2;
        
        // Find the decoder for the video stream
        codec = avcodec_find_encoder(CODEC_ID_FLV1);
        if (!codec) {
                fprintf(stderr, "codec not found\n");
        }
        if (avcodec_open(ctx, codec) < 0) {
                fprintf(stderr, "could not open codec\n");
        }

        
        
    	if(pCodec -> capabilities & CODEC_CAP_TRUNCATED)
                pCodecCtx -> flags |= CODEC_FLAG_TRUNCATED;
        
        // Open codec
        if(avcodec_open(pCodecCtx, pCodec)<0)
                printf("\nCould not open codec for video");
        
        if(avcodec_open(aCodecCtx, aCodec1)<0)
                printf("\nCould not open codec for audio");
        

        
        

}



-(void) amfDeSerialization :(unsigned char *)packetdata andX :(int)bodysize andF:(int)avflag andH:(unsigned char *)flvPacketHeader andT:(unsigned char *)flvPacketFooter
{
        printf("\n::::::::deserialization::::::: \n");
        int i;
        uint8_t *currentOutBuf;
        int got_picture = 0, len = 0;
        FILE *file1;
        AVPacket packet;
        av_init_packet(&packet);
        
        
        i = 0;
        
       
        if(avflag == 1)
        {
                                
                total = total + bodysize;
                
        
                if(packetdata[0] == 0x22 || packetdata[0] == 0x12) 
                {
                        if(packetdata[0] == 0x12)
                        {
                            packet.flags = PKT_FLAG_KEY;
                        
                        }
                        videoPacket = videoPacket + 1;                        
                
                        packet.data = packetdata + 1;
                        packet.size = bodysize - 1;
                        packet.pts = timestamp[1][1];
                        packet.dts = timestamp[1][1];
                        packet.duration = 0;
                        packet.pos = -1;
                        pFrame = avcodec_alloc_frame();
                        
                        
                        printf("\n width:::%d",pCodecCtx->width);
                        
                        [self setupScaler];

                        
                        while(packet.size > 0)
                        {
                            
                                len = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, &packet);
                
                                if(len < 0)
                                {
                                        printf("\nerror");
                                }
                                if(got_picture)
                                {
                                        printf("saving frame %3d\n", frame);
                                        fflush(stdout);
                                        
                                                                        
                                        if(!pFrame -> data[0])
                                        {
                                                printf("\n\n pframe null");
                                        }
                                        else
                                        {
                                                sws_scale(img_convert_ctx, pFrame -> data, pFrame -> linesize, 0, pCodecCtx -> height, picture.data, picture.linesize);
                                                
                                                RtmpClientAppDelegate *del = (RtmpClientAppDelegate *)[UIApplication sharedApplication].delegate;
                                                UIImage *img = [self imageFromAVPicture:picture width:pCodecCtx -> width height:pCodecCtx-> height];
                                                if(img && [img isKindOfClass:[UIImage class]])
                                                {
                                                        NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%d.jpg", frame]];
                                                        [UIImageJPEGRepresentation(img, 1) writeToFile:filePath atomically:YES];
                                                        
                                                        [del.imageView performSelectorOnMainThread:@selector(setImage:) withObject:img waitUntilDone:YES];
                                                }
                                                else
                                                {
                                                        NSLog(@"Setting Image Failed...");
                                                }
                                                
                                        }
                                         frame++;
                                        av_free_packet(&packet);
                                }
                                packet.size = packet.size - len;
                                packet.data = packet.data + len;
                                
                        }
                
                }
                avflag = 0;
                                        
        }
        else 
        {
                NSLog(@"else ");
        }
              
        
}

-(void)setupScaler
{
        
	// Release old picture and scaler
	avpicture_free(&picture);
	sws_freeContext(img_convert_ctx);	
	
	// Allocate RGB picture
	avpicture_alloc(&picture, PIX_FMT_RGB24, pCodecCtx -> width, pCodecCtx -> height);
	
	// Setup scaler
	static int sws_flags =  SWS_FAST_BILINEAR;
	img_convert_ctx = sws_getContext(pCodecCtx->width, 
                                         pCodecCtx->height,
                                         pCodecCtx->pix_fmt,
                                         pCodecCtx -> width, 
                                         pCodecCtx -> height,
                                         PIX_FMT_RGB24,
                                         sws_flags, NULL, NULL, NULL);
	
}

-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height {
        
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(width, 
                                           height, 
                                           8, 
                                           24, 
                                           pict.linesize[0], 
                                           colorSpace, 
                                           bitmapInfo, 
                                           provider, 
                                           NULL, 
                                           NO, 
                                           kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
	UIImage *image = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	CGDataProviderRelease(provider);
	CFRelease(data);
	return image;
}

@end






