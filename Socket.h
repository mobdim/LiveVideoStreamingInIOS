//
//  Socket.h
//  RtmpClient


#import <Foundation/Foundation.h>

@interface Socket : NSObject
extern int gSock;

-(int) SocketConnection :(char *)IpAddress;
-(void) socketStartThread :(NSNumber *)sock;
-(void) socketRead :(NSNumber *)sock;
-(void) readPacket :(int) sock andF: (unsigned char)fbyte;
@end
