//
//  Rtmp.h
//  RtmpClient


#import <Foundation/Foundation.h>
#include <AVFoundation/AVFoundation.h>
#include <inttypes.h>

@interface Rtmp : NSObject

extern int timestamp[2][2];                //1st column - for timestamp DELTA 2nd column - for timestamp CALCULATED                                            
extern NSMutableArray *oneByteheader;
extern NSMutableArray *fourByteheader;
extern NSMutableArray *setbodysize;
extern int x;



-(void) HandShake :(int) sock;
-(void) rtmpConnect :(NSArray *)input;
-(void) startThread :(NSArray *)input;

+(void) createStream: (int) sock;
-(void) extractPacket :(int) sock andF: (unsigned char *)fbyte;
-(int) contentType: (unsigned char) cType andB :(int [])bin andS :(int)bodysize andTs :(int)time andH:(int) hlen;
+(void) publish: (int) sock;
+(void) play: (int) sock;
+(void) playStream: (int) sock;


@end
