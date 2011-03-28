//
//  IQScreenRecorder.h
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-03-25.
//  Please be aware that this class is dependent on GPL-licensed code in Contrib/
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface IQScreenRecorder : NSObject {
    AVAssetWriter* assetWriter;
    CADisplayLink* displayLink;
    AVAssetWriterInput* input;
    AVAssetWriterInputPixelBufferAdaptor* inputAdaptor;
    BOOL startedWriting;
    void* screenSharing;
}

+ (IQScreenRecorder*) screenRecorder;

- (NSString*) startRecording;
- (void) stopRecording;

- (void) startSharingScreenWithPort:(int)port password:(NSString*)password;
- (void) stopSharingScreen;

@end
