//
//  IQViewTransition.h
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-05-11.
//  Copyright 2011 EvolvIQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IQViewTessellation.h"

typedef void (^IQTransitionCompletionBlock)(UIView* from, UIView *to);

@interface IQViewTransition : NSObject {
    UIView* from, *to;
    IQViewTessellation* transform;
    IQTransitionCompletionBlock complete;
    BOOL stopped;
}

+ (void) stopTransitions;
+ (void) transitionFrom:(UIView*)fromView to:(UIView*)toView duration:(NSTimeInterval)duration withTransformation:(IQViewTesselationTransformation)transformation completion:(IQTransitionCompletionBlock)complete;

@end
