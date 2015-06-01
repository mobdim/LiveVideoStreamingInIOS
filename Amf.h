//
//  Amf.h
//  RtmpClient
	

#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioQueue.h>
#include <AudioToolbox/AudioFile.h>
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libavutil/avutil.h"
#include "libavdevice/avdevice.h"
#include "libswscale/swscale.h"
#include "zlib.h"



@interface Amf : NSObject

        
        extern struct SwsContext *img_convert_ctx;
        extern AVCodecContext *pCodecCtx, *aCodecCtx, *ctx;
        extern AVFrame *pFrame;
        extern AVPicture picture;
        extern AVCodec *pCodec,*aCodec1,*codec;
//extern short *outBuf;
extern int out_size;

    


+(int) amfString :(const char *)temp1 andC :(int) count;
+(int) amfNumber :(double)num andC :(int) count;
-(int) amfSerialization :(NSString *) property andB :(unsigned char *)temp andC :(int) count; 
-(void) amfDeSerialization :(unsigned char[])recev andX :(int) x andF :(int) vflag andH :(unsigned char []) flvPacketHeader andT :(unsigned char [])flvPacketFooter;
-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height;
+(void) initVideo;
+(void) initAudio;
-(void)setupScaler;
//-(void) AudioPlay;

@end
