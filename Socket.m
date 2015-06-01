//
//  Socket.m
//  RtmpClient

#import "Socket.h"
#import "Rtmp.h"
#import <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#import "Amf.h"

unsigned char *temp;


@implementation Socket

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(int) SocketConnection :(char *)IpAddress
{
        
        struct sockaddr_in sad;
	int sock;
	sock=socket(AF_INET,SOCK_STREAM,0);
	bzero(&sad,sizeof(sad));
	sad.sin_family=AF_INET;
	sad.sin_port=htons(atoi("1935"));
        inet_pton(AF_INET,IpAddress,&sad.sin_addr);
	connect(sock,(struct sockaddr *)&sad,sizeof(sad));
        //[Socket socketRead];
        return sock;
         
}

-(void) socketStartThread :(NSNumber *)sockid
{
        NSThread *rthread = [[NSThread alloc] initWithTarget:self selector:@selector(socketRead:) object:sockid];
        [rthread start];
}

-(void) socketRead :(NSNumber *)sockid
{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        int sock = [sockid intValue],s = 0, i;
        unsigned char *header = malloc(1);
        Rtmp *rtmpObj = [[Rtmp alloc] init];
        gSock = sock;
        printf("\nsocketread:::Receiving from server(Set Peer Bandwidth)");
        for (; ;) 
        {
                s=read(sock, header, 1);
                printf("\nFirst Byte %x",header[0]);
                [rtmpObj extractPacket:sock andF:header];
                
                
        }
        [rtmpObj release];
        [pool release];
}
@end
