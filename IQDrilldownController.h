//
//  IQDrilldownPanelViewController.h
//  IQWidgets for iOS
//
//  Copyright 2010 EvolvIQ
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>

@class IQDrilldownController;

@protocol IQDrilldownControllerDelegate
@optional
- (CGFloat) drilldown:(IQDrilldownController*)drilldown widthForViewInController:(UIViewController*)viewController;
- (BOOL) drilldown:(IQDrilldownController*)drilldown stopAtPartiallyVisibleController:(UIViewController*)viewController;
@end

// The maximum depth of the drilldown controller.
#define MAX_VIEWS 8

@interface IQDrilldownController : UIViewController<UIGestureRecognizerDelegate> {
	CGFloat panelWidth;
	CGFloat minimizedMargin;
    UIViewController* rootViewController;
	NSMutableArray* viewControllers;
	BOOL activeViewRightAligned;
	BOOL stopAtPartiallyVisibleNext;
	BOOL enableViewShadows;
	int activeIndex;
	CGPoint origin[MAX_VIEWS];
	id<IQDrilldownControllerDelegate> delegate;
	UISwipeGestureRecognizer* swipeLeft, *swipeRight;
	UIPanGestureRecognizer* pan;
	BOOL inPan;
	CGFloat shadowRadius;
	CGFloat shadowOpacity;
}

/**
 Initializer specifying a root view controller. A root view controller is controlling
 the (immovable) root view. Use of a root view is optional, and this argument can be nil.
 */
- (id) initWithRootViewController:(UIViewController*)rootViewController;

// Pushes a view controller to the top of the view stack as the outermost view controller.
- (void) pushViewController:(UIViewController*)viewController animated:(BOOL)animated;
// Replaces the entire view controller stack with the specified view controller
- (void) setViewController:(UIViewController*) viewController animated:(BOOL)animated;

- (void) popViewControllerAnimated:(BOOL)animated;

- (void) setActiveIndex:(int)index animated:(BOOL)animated;

- (void) goLeftAnimated:(BOOL)animated;
- (void) goRightAnimated:(BOOL)animated;

- (IBAction) debugAction1:(id)sender;
- (IBAction) debugAction2:(id)sender;

@property (nonatomic) int activeIndex;
@property (nonatomic, retain) IBOutlet id<IQDrilldownControllerDelegate> delegate;
/**
 If YES, manages the view shadows of the drilldown pages automatically.
 Default is YES.
 */
@property (nonatomic) BOOL enableViewShadows;
@property (nonatomic) CGFloat shadowRadius;
@property (nonatomic) CGFloat shadowOpacity;
@property (nonatomic) CGFloat panelWidth;
@property (nonatomic) BOOL stopAtPartiallyVisibleNext;

@property (nonatomic, readonly) UIViewController* rootViewController;

@end

@interface UIViewController (DrilldownExtensions)
- (IQDrilldownController*) drilldownController;
@end