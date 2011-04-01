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
extern CGImageRef UIGetScreenImage();

@interface IQScreenRecorder (PrivateMethods)
- (void) startCapturing;
- (void) stopCapturing;
@end

@implementation UIView (FindAndResignFirstResponder)
- (BOOL)findAndResignFirstResponder
{
    if (self.isFirstResponder) {
        NSLog(@"I am first responder: %@", self);
        [self resignFirstResponder];
        return YES;     
    }
    for (UIView *subView in self.subviews) {
        if ([subView findAndResignFirstResponder])
            return YES;
    }
    return NO;
}
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
    input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, [NSNumber numberWithInt:screenSize.width], AVVideoWidthKey, [NSNumber numberWithInt:screenSize.height], AVVideoHeightKey, [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:100*1024*1024],AVVideoAverageBitRateKey,nil], AVVideoCompressionPropertiesKey, nil]];
    
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
    if(screenSharing == nil && !screenMirroringEnabled) {
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
    rfbScreenInfoPtr rfbScreen = rfbGetScreen(NULL, NULL, screenSize.width, screenSize.height, 8, 3, 4);
    NSLog(@"Sharing screen at %p", rfbScreen);
    if(rfbScreen == nil) return;
    screenSharing = rfbScreen;
    rfbScreen->desktopName = "IQWidgets DemoEnabler iOS";
    rfbScreen->frameBuffer = calloc(screenSize.width*screenSize.height, 4);
    rfbScreen->alwaysShared = YES;
    rfbInitServer(rfbScreen);
    rfbRunEventLoop(rfbScreen,-1,TRUE);
    [self startCapturing];
}

- (void) stopSharingScreen
{
    if(assetWriter == nil && !screenMirroringEnabled) {
        [self stopCapturing];
    }
    if(screenSharing != nil) {
        
    }
}

- (void) _tryStartCreateMirror
{
    UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
    NSLog(@"Window is %@", keyWindow);
    NSLog(@"Windows are %@", [[UIApplication sharedApplication] windows]);
    if (keyWindow == nil) return;
    // Hack: iPhone 3GS and earlier does not support the TV out API
    if(NO && keyWindow.bounds.size.width <= 320) {
        /*NSLog(@"Doing iPhone 3GS hack");
         CGRect rect = keyWindow.bounds;
         MPVideoView *vidView = [[MPVideoView alloc] initWithFrame:rect];
         MPTVOutWindow *tvWindow = [[MPTVOutWindow alloc] initWithVideoView:vidView];
         screenMirroringWindow = tvWindow;
         screenMirroringView = [[UIImageView alloc] initWithFrame:rect];
         [screenMirroringWindow addSubview:screenMirroringView];
         screenMirroringView.contentMode = UIViewContentModeScaleAspectFit;
         screenMirroringWindow.backgroundColor = [UIColor darkGrayColor];
         */
    } else {
        NSLog(@"Screens: %@", [UIScreen screens]);
        if([UIScreen screens].count > 1) {
            UIScreen *external = [[UIScreen screens] objectAtIndex: 1];
            NSLog(@"I have a new screen: %@", external);
            CGSize max = CGSizeMake(0, 0);
            UIScreenMode *maxScreenMode = nil;
            
            for(UIScreenMode* mode in [external availableModes]) {
                if (mode.size.width > max.width) {
                    max = mode.size;
                    maxScreenMode = mode;
                }
            }
            external.currentMode = maxScreenMode;
            if(screenMirroringWindow == nil) {
                //[keyWindow findAndResignFirstResponder];
                
                screenMirroringWindow = [[UIWindow alloc] initWithFrame: CGRectMake(0,0, max.width, max.height)];
                screenMirroringWindow.userInteractionEnabled = NO;
                screenMirroringWindow.screen = external;
                
                //[[[[UIAlertView alloc] initWithTitle:@"Monitor plugged in" message:[NSString stringWithFormat:@"Resolution: %fx%f",max.width,max.height] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease] show];
                
                screenMirroringView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, max.width, max.height)];
                [screenMirroringWindow addSubview:screenMirroringView];
                screenMirroringView.contentMode = UIViewContentModeScaleAspectFit;
                //screenMirroringView.contentMode = UIViewContentModeCenter;
                screenMirroringView.image = [UIImage imageNamed:@"panel-no.png"];
                screenMirroringView.backgroundColor = [UIColor blackColor];
            } else {
                NSLog(@"I already have the window");
                screenMirroringWindow.screen = external;
            }
            //[screenMirroringWindow makeKeyAndVisible];
            screenMirroringWindow.hidden = NO;
            
            //[keyWindow makeKeyAndVisible];        
        } else {
            NSLog(@"I am not doing anything until you plug in the external monitor");
        }
    }
}
- (void)tryStartCreateMirror
{
    @synchronized(self) {
        [self performSelectorOnMainThread:@selector(_tryStartCreateMirror) withObject:nil waitUntilDone:YES];
    }
}

-(void) screenDidConnectNotification: (NSNotification*) notification
{
	NSLog(@"Screen connected: %@", [notification object]);
	[self tryStartCreateMirror];
    //[[[[UIAlertView alloc] initWithTitle:@"Monitor plugged in" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease] show];
}

-(void) screenDidDisconnectNotification: (NSNotification*) notification
{
	NSLog(@"Screen disconnected: %@", [notification object]);
    if(!screenMirroringEnabled) return;
    if(screenMirroringWindow == nil) return;
    UIWindow* win = screenMirroringWindow;
    UIImageView* view = screenMirroringView;
    screenMirroringWindow.hidden = YES;
    screenMirroringWindow = nil;
    screenMirroringView = nil;
    [win release];
    [view release];
}

-(void) screenModeDidChangeNotification: (NSNotification*) notification
{
	NSLog(@"Screen mode changed: %@", [notification object]);
    //if(!screenMirroringEnabled) return;
	//[self tryStartCreateMirror];
}

- (void) _startMirroringScreen
{
    NSLog(@"Will start mirroring the screen");
    //dispatch_
    screenMirroringEnabled = YES;
    [self tryStartCreateMirror];
    [self startCapturing];
}
- (void) startMirroringScreen
{
    [self performSelector:@selector(_startMirroringScreen) withObject:nil afterDelay:1.0];
}

- (void) stopMirroringScreen
{
    NSLog(@"Will stop mirroring the screen");
    if(assetWriter == nil && screenSharing != nil) {
        [self stopCapturing];
    }
    screenMirroringEnabled = NO;
    screenMirroringWindow.hidden = YES;
    [screenMirroringView removeFromSuperview];
    [screenMirroringView release];
    [screenMirroringWindow release];
}
@end

@implementation IQScreenRecorder (PrivateMethods)

- (void)updateImage:(UIImage*)image
{
    static int i = 0;
    i++;
    /*if(i&1) {
     screenMirroringView.backgroundColor = [UIColor blueColor];
     } else {
     screenMirroringView.backgroundColor = [UIColor yellowColor];
     }*/
    screenMirroringView.image = image;
    //[screenMirroringView setNeedsDisplay];
    //NSLog(@"Done setting image %p %@", image, screenMirroringView);
    //CGImageRelease(image);
}

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
    if(isSharing == NO && isRecording == NO && screenMirroringEnabled == NO) return;
    UIApplication* app = [UIApplication sharedApplication];
    if(app != nil) {     
        UIWindow* win = app.keyWindow;
        if(win != nil) { 
            CVPixelBufferRef pixbuf = NULL;
            if(isSharing || isRecording) {
                CVPixelBufferCreate(kCFAllocatorDefault, screenSize.width, screenSize.height, kCVPixelFormatType_32ARGB, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil], &pixbuf);
                if(!pixbuf) {
                    NSLog(@"Unable to create pixbuf");
                }
            }
            CGContextRef context = NULL;
            void *pixels = NULL;
            CGColorSpaceRef rgbColorSpace = NULL;
            if(pixbuf) {
                CVPixelBufferLockBaseAddress(pixbuf, 0);
                rgbColorSpace = CGColorSpaceCreateDeviceRGB();
                pixels = CVPixelBufferGetBaseAddress(pixbuf);
                context = CGBitmapContextCreate(pixels, screenSize.width, screenSize.height, 8, 4*screenSize.width, rgbColorSpace, kCGImageAlphaNoneSkipFirst);
            }
#if !TARGET_IPHONE_SIMULATOR
            // NOTE: This uses "forbidden" API functions. Using this in your app could have it rejected
            // by Apple when submitting to the App Store.
            CGImageRef image = UIGetScreenImage();
            if(context) {
                CGContextDrawImage(context, CGRectMake(0, 0, screenSize.width, screenSize.height), image);
            }
            //CGImageRetain(image);
            if(screenMirroringView != nil) {
                //NSLog(@"Setting image");
                UIImage* img = [[UIImage imageWithCGImage:image] retain];
                //[self performSelectorOnMainThread:@selector(updateImage:) withObject:img waitUntilDone:YES];
                [self updateImage:img];
                [img release];
            }
            CGImageRelease(image);
#define MAPPED_Y y
#else
            if(context != nil) {
                [[win.layer presentationLayer] renderInContext:context];
            }
#define MAPPED_Y (screenSize.height-1-y)
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
                } else if(pixels) {
                    //unsigned int* buf = malloc(320*480*4);
                    unsigned int* buf = (unsigned int*)rfbScreen->frameBuffer;
                    unsigned int* ibuf = (unsigned int*)pixels;
                    int cls = screenSize.height, cle = 0, ccs = screenSize.width, cce = 0;
                    for(int y=0;y<screenSize.height;y++) {
                        for(int x=0; x<screenSize.width; x++) {
                            register unsigned int t = ibuf[MAPPED_Y*screenSize.width+x];
                            t = (t&0xFF0000)>>8 | (t&0xFF00)>>8 | (t&0xFF000000)>>8;
                            if(t != buf[y*screenSize.width+x]) {
                                buf[y*screenSize.width+x] = t;
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
            if(context) CGContextRelease(context);
            if(rgbColorSpace) CGColorSpaceRelease(rgbColorSpace);
            if(pixbuf) {
                CVPixelBufferUnlockBaseAddress(pixbuf, 0);
                CVPixelBufferRelease(pixbuf);   
            }
        }
    } else {
        NSLog(@"No window yet");
    }
}

- (void) startCapturing
{
    if(displayLink == nil) {
        displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(captureFrame)] retain];
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
    NSLog(@"Will now stop capturing");
    [displayLink invalidate];
    displayLink = nil;
}

- (id) init {
    self = [super init];
    if(self) {
        CGSize size = [[UIScreen mainScreen] currentMode].size;
        screenSize.width = size.width;
        screenSize.height = size.height;
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(screenDidConnectNotification:) name: UIScreenDidConnectNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(screenDidDisconnectNotification:) name: UIScreenDidDisconnectNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(screenModeDidChangeNotification:) name: UIScreenModeDidChangeNotification object: nil];
    }
    return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}
@end