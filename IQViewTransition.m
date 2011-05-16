//
//  IQViewTransition.m
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-05-11.
//  Copyright 2011 EvolvIQ. All rights reserved.
//

#import "IQViewTransition.h"

@interface IQViewTransition ()
- (void) stop;
@end

@implementation IQViewTransition

static IQViewTransition* activeTransition;

+ (void) stopTransitions
{
    if(activeTransition) {
        IQViewTransition* trans = activeTransition;
        activeTransition = nil;
        [trans stop];
        [trans release];
    }
}

- (void) doTransitionStart
{
    [from.superview addSubview:transform];
    [transform setTransitionViewsFrom:from to:to];
    [transform presentFrame];
}
+ (void) transitionFrom:(UIView*)fromView to:(UIView*)toView duration:(NSTimeInterval)duration withTransformation:(IQViewTesselationTransformation)transformation completion:(IQTransitionCompletionBlock)complete {
    if(fromView.superview != toView.superview) {
        [NSException raise:@"MustShareSuperview" format:@"Transition between views with different superviews is currently unsupported"];
    }
    IQViewTransition* trans = [[IQViewTransition alloc] init];
    if(trans != nil) {
        trans->from = [fromView retain];
        trans->to = [toView retain];
        trans->transform = [[IQViewTessellation alloc] initWithFrame:fromView.frame withTilesHorizontal:8 vertical:24];
        if(complete) trans->complete = Block_copy(complete);
        trans->transform.transformation = ^(CGPoint pt, CGFloat t) {
            if(t >= duration) {
                [trans stop];
            }
            if(transformation == nil) {
                return IQMakePoint3(pt.x, pt.y, 0);
            } else {
                return transformation(pt, t);
            }
        };
        //toView.hidden = NO;
        [trans performSelectorOnMainThread:@selector(doTransitionStart) withObject:trans waitUntilDone:NO];
    }
}


- (void) dealloc
{
    NSLog(@"dellocing transition");
    if(complete) Block_release(complete);
    complete = nil;
    IQViewTessellation* tf = transform;
    transform = nil;
    tf.transformation = nil;
    [tf release];
    [from release];
    from = nil;
    [to release];
    to = nil;
}

- (void) stop
{
    if(stopped) return;
    stopped = YES;
    if(self == activeTransition) {
        activeTransition = nil;
    }
    if(complete) {
        complete(from, to);
        Block_release(complete);
        complete = nil;
    }
    [transform stopAnimation];
    transform.transformation = nil;
    [transform removeFromSuperview];
    [self release];
}

@end
