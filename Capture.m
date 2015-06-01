//  Capture.m
//  RtmpClient
//

#import "Capture.h"
#import "Amf.h"
#import "Socket.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libavdevice/avdevice.h"
#include "libavfilter/avfilter.h"
void DecimalToHex1(int decimal, unsigned char hexdata[4]);
int timestamp1 = 0;
@implementation Capture

@synthesize captureSession = _captureSession;
@synthesize imageView = _imageView;
@synthesize customLayer = _customLayer;
@synthesize prevLayer = _prevLayer;

-(void) captureVideo
{

        /*UILabel *myLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, 200, 100)];
        myLabel.text = str;
        [self.view addSubview:myLabel];*/

        
        AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
                                              deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] 
                                              error:nil];
	/*We setupt the output*/
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	/*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
	 If you don't want this behaviour set the property to NO */
	captureOutput.alwaysDiscardsLateVideoFrames = YES; 
	/*We specify a minimum duration for each frame (play with this settings to avoid having too many frames waiting
	 in the queue because it can cause memory issues). It is similar to the inverse of the maximum framerate.
	 In this example we set a min frame duration of 1/10 seconds so a maximum framerate of 10fps. We say that
	 we are not able to process more than 10 frames per second.*/
	//captureOutput.minFrameDuration = CMTimeMake(1, 10);
	
	/*We create a serial queue to handle the processing of our frames*/
	dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
	// Set the video output to store frame in BGRA (It is supposed to be faster)
	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey; 
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key]; 
	[captureOutput setVideoSettings:videoSettings]; 
	/*And we create a capture session*/
	self.captureSession = [[AVCaptureSession alloc] init];
	/*We add input and output*/
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:captureOutput];
        /*We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
        [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
	/*We add the Custom Layer (We need to change the orientation of the layer so that the video is displayed correctly)*/
	self.customLayer = [CALayer layer];
	self.customLayer.frame = self.view.bounds;
	self.customLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0f, 0, 0, 1);
	self.customLayer.contentsGravity = kCAGravityResizeAspectFill;
	[self.view.layer addSublayer:self.customLayer];
	/*We add the imageView*/
	//self.imageView = [[UIImageView alloc] init];
	//self.imageView.frame = CGRectMake(0, 0, 200, 200);
        //NSLog(@"::::::::%@",self.imageView.frame);
        //[self.view addSubview:self.imageView];
	/*We add the preview layer*/
	//self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
	//self.prevLayer.frame = CGRectMake(50, 50, 200, 200);
	//self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	//[self.view.layer addSublayer: self.prevLayer];
	/*We start the capture*/
	[self.captureSession startRunning];
        
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
fromConnection:(AVCaptureConnection *)connection 
{ 
        
        /*label = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, 200, 100)];
        label.text = @"ABCDEFG";
        [self.view addSubview:label];*/

        unsigned char *imageData = malloc(500000);
        unsigned char hexData[3];
        unsigned char timestampHex[3];
	/*We create an autorelease pool because as we are not in the main_queue our code is
	 not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
	//printf("\n hello");
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0); 
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
        size_t width = CVPixelBufferGetWidth(imageBuffer); 
        size_t height = CVPixelBufferGetHeight(imageBuffer);  
        
                
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        
        CGImageRef newImage = CGBitmapContextCreateImage(newContext); 
	
        /*We release some components*/
        CGContextRelease(newContext); 
        CGColorSpaceRelease(colorSpace);
        
        /*We display the result on the custom layer. All the display stuff must be done in the main thread because
	 UIKit is no thread safe, and as we are not in the main thread (remember we didn't use the main_queue)
	 we use performSelectorOnMainThread to call our CALayer and tell it to display the CGImage.*/
	[self.customLayer performSelectorOnMainThread:@selector(setContents:) withObject: (id) newImage waitUntilDone:YES];
	
	/*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
	 Same thing as for the CALayer we are not in the main thread so ...*/
	UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
        
        
        int outbuf_size = 500000;
        unsigned char *picBuf = malloc(outbuf_size);
        //int size = ctx->width * ctx->height;
        AVFrame *picture = avcodec_alloc_frame();
        AVFrame *pFrame12 = avcodec_alloc_frame();
        int nbytes = avpicture_get_size(PIX_FMT_YUV420P, ctx->width, ctx->height);
        
        uint8_t* outbuffer = (uint8_t*)av_malloc(nbytes);
        
        fflush(stdout);
        //1
        int numBytes = avpicture_get_size(PIX_FMT_RGB48BE, ctx->width, ctx->height);
        
        CGImageRef newCgImage = [image CGImage];
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(newCgImage);
        CFDataRef bitmapData = CGDataProviderCopyData(dataProvider);
        long dataLength = CFDataGetLength(bitmapData);
        
        uint8_t *buffer = (uint8_t *)av_malloc(numBytes*sizeof(uint8_t));

        buffer = (uint8_t *)CFDataGetBytePtr(bitmapData);
        
        //CFDataGetBytes(bitmapData, CFRangeMake(0, dataLength), buffer);
        
        pFrame12 -> pts = timestamp1;
        //1
        avpicture_fill((AVPicture*)picture, buffer, PIX_FMT_RGB48BE, ctx->width, ctx->height);
        
        avpicture_fill((AVPicture*)pFrame12, outbuffer, PIX_FMT_YUV420P, ctx->width, ctx->height);
        struct SwsContext* fooContext = sws_getContext(ctx->width, ctx->height, 
                                                       PIX_FMT_RGB48BE, 
                                                       ctx->width, ctx->height, 
                                                       PIX_FMT_YUV420P, 
                                                       SWS_FAST_BILINEAR, NULL, NULL, NULL);
        
        sws_scale(fooContext, picture->data, picture->linesize, 0, ctx->height, pFrame12->data, pFrame12->linesize);
        
        int size = 0;
        size = avcodec_encode_video(ctx, picBuf, outbuf_size, pFrame12);
        
        /*printf("\n\nBuffer::::\n\n");
        for(int i = 0;i < size;i++)
        {
                printf("%x ",picBuf[i]);
        }*/
         
        printf("\n\nSize:::: %d",size);

        DecimalToHex1(timestamp1, timestampHex);
        timestamp1 = timestamp1 + 1;
        DecimalToHex1(size + 1, hexData);
        int count=0;
        imageData[0] = 0x05; count++;
        imageData[1] = timestampHex[0]; count++;
        imageData[2] = timestampHex[1];count++;
        imageData[3] = timestampHex[2];count++;
        imageData[4] = hexData[0];count++;
        imageData[5] = hexData[1];count++;
        imageData[6] = hexData[2];count++;
        imageData[7] = 0x09;count++;
        imageData[8] = 0x01;count++;
        imageData[9] = 0x00;count++;
        imageData[10] = 0x00;count++;
        imageData[11] = 0x00;count++;
        imageData[12] = 0x12;count++;
        /*int j = 13;
        int k = 1;
        for(int i = 0;i < size; i++,j++)
        {
                if( k % 128 == 0 && k != 0)
                {
                        imageData[j] = 0xc5;
                        j++;
                        k++;
                }
                k++;
                imageData[j] = picBuf[i];
        }*/
        int i, j,k = 1;
        for (i = count,j = 0; j <= size; j++,i++,k++)
        {
                if( k % 128 == 0 && k != 0)
                {
                        imageData[i] = 0xc5;
                        i++;
                        count++;
                }
                imageData[i] = picBuf[j];
                count++;
        }
        
        
        int len = write(gSock, imageData, count-1);
        printf("\n\n Len = %d count = %d",len,count);
        //free(pFrame12);
        free(picBuf);
        free(imageData);
        free(buffer);
        free(outbuffer);
        av_free(pFrame12);
	av_free(picture);
        
	/*We relase the CGImageRef*/
	CGImageRelease(newImage);
	
	[self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
	        
	/*We unlock the  image buffer*/
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        //CVBufferRelease(imageBuffer);
	
	[pool drain];
} 

void DecimalToHex1(int decimal, unsigned char hexdata[3])
{
        int i = 5,j = 0;
        unsigned char rem[6];
        while (decimal > 0) 
        {
                rem[i] = decimal  % 16;
                //printf("\n rem[%d] = %x",i,rem[i]);
                decimal = decimal / 16;
                
                i--;
        }  
        for(j = i ;j >=0 ;j--)
        {
                rem[j] = 0x00;
        }
        j = 0;
        for ( i = 0;i < 6 ;i = i + 2)
        {
                hexdata[j] = (rem[i] * 0x10) + rem[i + 1];
                j++;
        }
        
        /*printf("\n\n");
         for (i = 0; i < 3; i++) {
         printf(" %x",hexdata[i]);
         }
         printf("\n\n");*/
}


@end
