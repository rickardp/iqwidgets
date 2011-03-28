//
//  IQScreenRecorder.m
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-03-25.
//  Please be aware that this class is dependent on GPL-licensed code in Contrib/
//

#import "IQScreenRecorder.h"
#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>
#import <rfb/rfb.h>

static IQScreenRecorder* _default_IQScreenRecorder = nil;

@interface IQScreenRecorder (PrivateMethods)
- (void) startCapturing;
- (void) stopCapturing;
@end

@implementation IQScreenRecorder

+ (IQScreenRecorder*) screenRecorder
{
    if(_default_IQScreenRecorder == nil) {
        _default_IQScreenRecorder = [[IQScreenRecorder alloc] init];
    }
    return _default_IQScreenRecorder;
}
- (NSString*) startRecording
{
    if(assetWriter != nil) [self stopRecording];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    NSString* path = nil;
    NSDateFormatter* fmt = [[[NSDateFormatter alloc] init] autorelease];
    [fmt setDateFormat:@"YYYYMMdd"];
    for(int i=1; ; i++) {
        path = [documentsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Capture_%@_%d.mov", [fmt stringFromDate:[NSDate date]], i]];
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]) break;
    }
    if(path == nil) {
        NSLog(@"Failed to find output path");
        return nil;
    } else {
        NSLog(@"Will write file %@", path);
    }
    NSError* err = nil;
    assetWriter = [[AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie error:&err] retain];
    if(err != nil || assetWriter == nil) {
        NSLog(@"Error: %@", err);
        [assetWriter release];
        assetWriter = nil;
        return nil;
    }
    input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, [NSNumber numberWithInt:320], AVVideoWidthKey, [NSNumber numberWithInt:480], AVVideoHeightKey, [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1024*1024],AVVideoAverageBitRateKey,nil], AVVideoCompressionPropertiesKey, nil]];
    
    inputAdaptor = [[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:input sourcePixelBufferAttributes:nil] retain];
    input.expectsMediaDataInRealTime = YES;
    [assetWriter addInput:input];
    NSLog(@"I am starting: %@", inputAdaptor);
    startedWriting = NO;
    if(![assetWriter startWriting]) {
        NSLog(@"I could not start writing!");
        [self stopRecording];
        return nil;
    } else {
        [self startCapturing];
    }
    return path;
}

- (void) stopRecording
{
    NSLog(@"Will now stop capturing");
    if(screenSharing == nil) {
        [self stopCapturing];
    }
    if(assetWriter != nil) {
        AVAssetWriter* oldWriter = assetWriter;
        assetWriter = nil;
        [input markAsFinished];
        [oldWriter finishWriting];
        [oldWriter release];
    }
    [inputAdaptor release];
    inputAdaptor = nil;
}

- (void) startSharingScreenWithPort:(int)port password:(NSString*)password
{
    if(screenSharing != nil) return;
    rfbScreenInfoPtr rfbScreen = rfbGetScreen(NULL, NULL, 320, 480, 8, 3, 4);
    NSLog(@"Sharing screen at %p", screenSharing);
    if(rfbScreen == nil) return;
    screenSharing = rfbScreen;
    rfbScreen->desktopName = "IQWidgets DemoEnabler iOS";
    rfbScreen->frameBuffer = calloc(320*480, 4);
    rfbScreen->alwaysShared = YES;
    rfbInitServer(rfbScreen);
    rfbRunEventLoop(rfbScreen,-1,TRUE);
    [self startCapturing];
}

- (void) stopSharingScreen
{
    if(assetWriter == nil) {
        [self stopCapturing];
    }
    if(screenSharing != nil) {
        
    }
}
@end


@implementation IQScreenRecorder (PrivateMethods)


- (void) captureFrame
{
    BOOL isRecording = YES, isSharing = YES;
    if(assetWriter == nil || assetWriter.status != AVAssetWriterStatusWriting) {
        if(assetWriter.status == AVAssetWriterStatusFailed) {
            NSLog(@"I have failed miserably with %@", assetWriter.error);
        }
        isRecording = NO;
    }
    if(screenSharing == nil) {
        isSharing = NO;
    }
    if(isSharing == NO && isRecording == NO) return;
    UIApplication* app = [UIApplication sharedApplication];
    if(app != nil) {     
        UIWindow* win = app.keyWindow;
        if(win != nil) {
            CVPixelBufferRef pixbuf;
            CVPixelBufferCreate(kCFAllocatorDefault, 320, 480, kCVPixelFormatType_32ARGB, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil], &pixbuf);
            if(!pixbuf) {
                NSLog(@"Unable to create pixbuf");
            } else {
                CVPixelBufferLockBaseAddress(pixbuf, 0);
                CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
                void *pixels = CVPixelBufferGetBaseAddress(pixbuf);
                CGContextRef context = CGBitmapContextCreate(pixels, 320, 480, 8, 4*320, rgbColorSpace, kCGImageAlphaNoneSkipFirst);
#if !TARGET_IPHONE_SIMULATOR
                // NOTE: This uses "forbidden" API functions. Using this in your app could have it rejected
                // by Apple when submitting to the App Store.
                CGImageRef image = UIGetScreenImage();
                CGContextDrawImage(context, CGRectMake(0, 0, 320, 480), image);
                CGImageRelease(image);
#define MAPPED_Y y
#else
                
                [[win.layer presentationLayer] renderInContext:context];
#define MAPPED_Y (479-y)
#endif
                if(isRecording) {
                    CMTime tim = CMTimeMake(1000.0*displayLink.timestamp, 1000);
                    if(!startedWriting) {
                        startedWriting = YES;
                        NSLog(@"Starting capture session");
                        [assetWriter startSessionAtSourceTime:tim];
                    }
                    if(inputAdaptor.assetWriterInput.readyForMoreMediaData) {
                        if([inputAdaptor appendPixelBuffer:pixbuf withPresentationTime:tim] == NO) {
                            NSLog(@"I have stopped writing");
                            [self stopRecording];
                        }
                    } else {
                        printf("I am choked \n");
                    }
                }
                if(isSharing) {
                    rfbScreenInfoPtr rfbScreen = (rfbScreenInfoPtr)screenSharing;
                    if(!rfbIsActive(rfbScreen)) {
                        [self stopSharingScreen];
                    } else {
                        //unsigned int* buf = malloc(320*480*4);
                        unsigned int* buf = (unsigned int*)rfbScreen->frameBuffer;
                        unsigned int* ibuf = (unsigned int*)pixels;
                        int cls = 480, cle = 0, ccs = 320, cce = 0;
                        for(int y=0;y<480;y++) {
                            for(int x=0; x<320; x++) {
                                register unsigned int t = ibuf[MAPPED_Y*320+x];
                                t = (t&0xFF0000)>>8 | (t&0xFF00)>>8 | (t&0xFF000000)>>8;
                                if(t != buf[y*320+x]) {
                                    buf[y*320+x] = t;
                                    if(ccs > x) ccs = x;
                                    if(cce < x) cce = x;
                                    if(cls > y) cls = y;
                                    if(cle < y) cle = y;
                                }
                            }
                        }
                        if(cce >= ccs && cle >= cls) {
                            printf("%d,%d,%d,%d\n", cls, cle, ccs, cce);
                            //void* oldfb = rfbScreen->frameBuffer;
                            rfbMarkRectAsModified(rfbScreen, ccs, cls, cce+1, cle+1);
                            //rfbMarkRectAsModified(rfbScreen, 0, 0, 320, 480);
                            //rfbNewFramebuffer(rfbScreen, (char*)buf, 320, 480, 8, 3, 4);
                            //free(oldfb);
                            //rfbProcessEvents(rfbScreen, 10000);
                        }
                    }
                }
                CGContextRelease(context);
                CGColorSpaceRelease(rgbColorSpace);
                CVPixelBufferUnlockBaseAddress(pixbuf, 0);
                CVPixelBufferRelease(pixbuf);
            }
        } else {
            NSLog(@"No window yet");
        }
    }
}

- (void) startCapturing
{
    if(displayLink == nil) {
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(captureFrame)];
        displayLink.frameInterval = 1;
        
        dispatch_queue_t q = dispatch_queue_create("Capture", NULL);
        dispatch_async(q, ^{
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] run];
        });
    }
}

- (void) stopCapturing
{
    [displayLink invalidate];
    displayLink = nil;
}
@end