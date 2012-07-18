//
//  IQDrilldownPanelViewController.m
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

#import "IQDrilldownController.h"
#import <QuartzCore/QuartzCore.h>

@interface _IQDrilldownPanel : UIView {
    __weak IQDrilldownController* parent;
}
- (id) initWithViewController:(UIViewController*)viewController parent:(IQDrilldownController*)parent;
@property (nonatomic, readonly) UIViewController* hostedViewController;
@property (nonatomic) CGPoint origin;
@end

@interface IQDrilldownController () {
	CGFloat panelWidth;
	CGFloat minimizedMargin;
    _IQDrilldownPanel* rootPanel;
	NSMutableArray* panels;
	BOOL activeViewRightAligned;
	BOOL stopAtPartiallyVisibleNext;
	BOOL enableViewShadows;
	int activeIndex;
	id<IQDrilldownControllerDelegate> delegate;
	UISwipeGestureRecognizer* swipeLeft, *swipeRight;
	UIPanGestureRecognizer* pan;
	BOOL inPan;
	CGFloat shadowRadius;
	CGFloat shadowOpacity;
    IQDrilldownRootViewPosition rootViewPosition;
}
    
- (void) _setupDrilldownPanel;
- (void) _setDropShadows:(BOOL)enable forPanel:(_IQDrilldownPanel*)panel;
- (void) doLayout:(BOOL)animated;
- (void) handlePan:(UIPanGestureRecognizer*)gesture;
- (void) handleSwipe:(UISwipeGestureRecognizer*)gesture;
@end

@implementation IQDrilldownController
@synthesize delegate;
@synthesize enableViewShadows;
@synthesize shadowRadius, shadowOpacity;
@synthesize panelWidth;
@synthesize stopAtPartiallyVisibleNext;
@synthesize rootViewController;
@synthesize rootViewPosition, drilldownDirection;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		[self _setupDrilldownPanel];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if(self) {
		[self _setupDrilldownPanel];
	}
    return self;
}

- (id)initWithRootViewController:(UIViewController *)root {
	self = [super init];
	if(self) {
        rootViewController = [root retain];
		[self _setupDrilldownPanel];
	}
    return self;
}

- (id)init {
	self = [super init];
	if(self) {
		[self _setupDrilldownPanel];
	}
    return self;
}

- (void) _setupDrilldownPanel {
	CGRect wb = self.view.bounds;
	if(wb.size.width > 700) {
		minimizedMargin = 72;
		panelWidth = 476;
	} else {
		minimizedMargin = 0;
		panelWidth = wb.size.width - 128;
	}
	activeIndex = -1;
	enableViewShadows = YES;
	panels = [[NSMutableArray alloc] initWithCapacity:2];
	swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
	swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
	pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	pan.delegate = self;
	swipeLeft.delegate = self;
	swipeRight.delegate = self;
	stopAtPartiallyVisibleNext = YES;
	shadowRadius = 50;
	shadowOpacity = 0.3;
    if(rootViewController != nil) {
        CGRect r = rootViewController.view.frame;
        r.size.height = self.view.bounds.size.height;
        rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
        r.origin.x = r.origin.y = 0;
        rootViewController.view.frame = r;
        [self.view addSubview:rootViewController.view];
    }
}

- (void) _setDropShadows:(BOOL)enable forPanel:(_IQDrilldownPanel*)panel {
	CALayer* layer = panel.layer;
    NSLog(@"Layer: %@", layer);
	if(enable) {
		layer.shadowOpacity = shadowOpacity;
		layer.shadowRadius = shadowRadius;
		layer.shadowPath = [UIBezierPath bezierPathWithRect:panel.bounds].CGPath;
	} else {
		layer.shadowOpacity = 0;
		layer.shadowRadius = 0;
		layer.shadowPath = nil;
	}
}

- (void) viewDidAppear:(BOOL)animated {
	[self.view.window addGestureRecognizer:pan];
	[self.view.window addGestureRecognizer:swipeLeft];
	[self.view.window addGestureRecognizer:swipeRight];
}

- (void) viewWillDisappear:(BOOL)animated {
	[self.view.window removeGestureRecognizer:swipeLeft];
	[self.view.window removeGestureRecognizer:swipeRight];
	[self.view.window removeGestureRecognizer:pan];
}

- (void) pushViewController:(UIViewController*)viewController animated:(BOOL)animated {
    if(viewController == nil) return;
    _IQDrilldownPanel* panel = [[[_IQDrilldownPanel alloc] initWithViewController:viewController parent:self] autorelease];
    if(viewController == rootViewController) {
        [NSException raise:@"InvalidArgument" format:@"Cannot push the root view controller to the controller stack"];
    }
	[panels addObject:panel];
	[self addChildViewController:viewController];
    panel.backgroundColor = [UIColor yellowColor];
    if(rootViewPosition == IQDrilldownRootViewPositionAbove) {
        [self.view insertSubview:panel belowSubview:rootViewController.view];
    } else {
        [self.view addSubview:panel];
    }
	activeIndex = panels.count - 1;
	
	CGRect bounds = self.view.bounds;
	CGFloat width = panelWidth;
	if(delegate != nil) {
		width = [delegate drilldown:self widthForViewInController:viewController];
		if(width <= 0) width = panelWidth;
		if(width > bounds.size.width - minimizedMargin) width = bounds.size.width - minimizedMargin;
	}
    panel.frame = CGRectMake(bounds.size.width, 0, width, bounds.size.height);
	activeViewRightAligned = YES;
	if(enableViewShadows) {
		[self _setDropShadows:YES forPanel:panel];
	}
	[self doLayout:animated];
}

- (void) setViewController:(UIViewController*) viewController animated:(BOOL)animated {
	while(panels.count > 0) [self popViewControllerAnimated:animated];
	[self pushViewController:viewController animated:animated];
}

- (void) popViewControllerAnimated:(BOOL)animated {
	if(panels.count == 0) return;
	_IQDrilldownPanel* last = [panels lastObject];
	[panels removeObject:last];
	activeIndex = panels.count - 1;
    if(!animated) {
        [last removeFromSuperview];
        [last.hostedViewController removeFromParentViewController];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            CGRect newFrame = last.frame;
            newFrame.origin.x = self.view.bounds.size.width;
            last.frame = newFrame;
        } completion:^(BOOL finished) {
            [last removeFromSuperview];
            [last.hostedViewController removeFromParentViewController];
        }];
    }
	[self doLayout:animated];
}

#pragma mark Properties

- (void) setRootViewPosition:(IQDrilldownRootViewPosition)newPos
{
    if(panels.count > 0) {
        [NSException raise:@"CannotSetProperty" format:@"Can not set rootViewPosition when there are drilldown controllers"];
    }
    self->rootViewPosition = newPos;
}

- (void) setEnableViewShadows:(BOOL)enable {
	if(enableViewShadows != enable) {
		enableViewShadows = enable;
		for(_IQDrilldownPanel* panel in panels) {
            [self _setDropShadows:enable forPanel:panel];
		}
	}
}

- (void) setActiveIndex:(int)index animated:(BOOL)animated {
	if(activeIndex < 0) index = 0;
	int max = panels.count - 1;
	if(activeIndex > max) index = max;
	activeIndex = index;
	[self doLayout:animated];
}

- (void) setActiveIndex:(int)index {
	[self setActiveIndex:index animated:NO];
}

- (int) activeIndex {
	if(panels.count == 0) return -1;
	return activeIndex;
}

#pragma mark View layouting

- (void) doLayout:(BOOL)animated {
	CGRect bounds = self.view.bounds;
	CGFloat left = minimizedMargin;
	int count = panels.count;
	if(count == 0) return;
	if(activeIndex < 0) activeIndex = 0;
	else if(activeIndex >= count) activeIndex = count - 1;
	
	// We don't allow the background panel to be hidden if there's only one view.
	// If this behavior is changed, the rubber-band effect in the pan gesture should
	// be updated as well.
	if(count == 1) activeViewRightAligned = YES;
	
	CGFloat width = ((_IQDrilldownPanel*)[panels objectAtIndex:activeIndex]).bounds.size.width;
	if(activeViewRightAligned) {
		left = bounds.size.width - width;
	}
	if(animated) {
		[UIView beginAnimations:nil context:nil];
	}
	int idx = 0;
	for(_IQDrilldownPanel* panel in panels) {
		CGFloat cleft;
		if(idx < activeIndex) {
			cleft = minimizedMargin;
		} else if(idx == activeIndex) {
			cleft = left;
		} else {
			cleft = left + width;
			if(idx > activeIndex + 1) cleft += width;
		}
		panel.origin = CGPointMake(cleft, 0);
		panel.frame = CGRectMake(cleft, 0, width, bounds.size.height);
		idx++;
	}
	
	if(animated) {
		[UIView commitAnimations];
	}
}


- (void) moveView:(int)viewToMove to:(CGFloat)x {
	_IQDrilldownPanel* movingView = [panels objectAtIndex:viewToMove];
	if(!movingView) return;
	int count = panels.count;
	CGRect prevViewFrame = movingView.frame;
	if(viewToMove > 0 && viewToMove == count - 1) {
		_IQDrilldownPanel* prev = [panels objectAtIndex:viewToMove-1];
		CGRect f = prev.frame;
		if(x + prevViewFrame.size.width < f.origin.x + f.size.width) {
			x = f.origin.x + f.size.width - prevViewFrame.size.width;
		}
	}
	if(x < minimizedMargin) x = minimizedMargin;
	
	// "viewToMove" is the "grabbed" view, all other views are now tied to this view
	prevViewFrame.origin.x = x;
	movingView.frame = prevViewFrame;
	
	for(int i = viewToMove-1; i >= 0; i--) {
		_IQDrilldownPanel* cpl = [panels objectAtIndex:i];
		CGRect curViewFrame = cpl.frame;
		CGRect oldFrame = curViewFrame;
		curViewFrame.origin.x = cpl.origin.x;
		if(curViewFrame.origin.x + curViewFrame.size.width < prevViewFrame.origin.x) {
			curViewFrame.origin.x = prevViewFrame.origin.x - curViewFrame.size.width;
		}
		if(curViewFrame.origin.x != oldFrame.origin.x) {
			cpl.frame = curViewFrame;
		}
		prevViewFrame = curViewFrame;
	}
	prevViewFrame = movingView.frame;
    CGFloat x0 = x;
	for(int i = viewToMove+1; i < count; i++) {
		_IQDrilldownPanel* cpl = [panels objectAtIndex:i];
		CGRect curViewFrame = cpl.frame;
		CGRect oldFrame = curViewFrame;
		x = curViewFrame.origin.x = cpl.origin.x;
		if(curViewFrame.origin.x > prevViewFrame.origin.x + prevViewFrame.size.width) {
			curViewFrame.origin.x = prevViewFrame.origin.x + prevViewFrame.size.width;
		} else if (curViewFrame.origin.x - prevViewFrame.origin.x < x - x0) {
			curViewFrame.origin.x = prevViewFrame.origin.x + x - x0;
		}
		if(curViewFrame.origin.x != oldFrame.origin.x) {
			cpl.frame = curViewFrame;
		}
		prevViewFrame = curViewFrame;
        x0 = x;
	}
}

- (void) goLeftAnimated:(BOOL)animated {
	if(activeViewRightAligned && activeIndex > 0) {
		activeIndex--;
		activeViewRightAligned = NO;
		[self doLayout:animated];
	} else {
		if(activeIndex == 0) {
			activeViewRightAligned = YES;
			[self doLayout:animated];
		} else {
			if(!activeViewRightAligned) {
				if(stopAtPartiallyVisibleNext) {
					activeViewRightAligned = YES;
					[self doLayout:animated];
				} else {
					[self setActiveIndex:activeIndex-1 animated:animated];
				}
			} else {
				[self setActiveIndex:activeIndex-1 animated:animated];
			}
		}
	}
}

- (void) goRightAnimated:(BOOL)animated {
	if(panels.count == 0) return;
	if(activeIndex == 0 && activeViewRightAligned) {
		activeViewRightAligned = NO;
		[self doLayout:animated];
	} else {
		int newActiveIndex = activeIndex + 1;
		if(newActiveIndex >= panels.count) newActiveIndex = panels.count - 1;
		if(stopAtPartiallyVisibleNext && activeViewRightAligned && activeIndex < panels.count - 1) {
			activeViewRightAligned = NO;
			[self doLayout:animated];
		} else {
			activeViewRightAligned = YES;
			[self setActiveIndex:newActiveIndex animated:animated];
		}
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[panels release];
	[swipeLeft release];
	[swipeRight release];
	[pan release];
    [super dealloc];
}

#pragma mark Gestures


- (void)handlePan:(UIPanGestureRecognizer*)gesture {
	CGPoint pt = [gesture translationInView:self.view];
	if(!inPan && pt.x < 10 && pt.x > -10) return;
	inPan = YES;
	CGPoint v = [gesture velocityInView:self.view];
	BOOL left = pt.x < 0;
	BOOL locked = NO;
	BOOL enableRubberBand = NO;
	int viewToMove = activeIndex;
	int count = panels.count;
	if(count == 0) return;
	if(count == 1) {
		enableRubberBand = YES;
	}
	
	if(left && viewToMove < count - 1 && !activeViewRightAligned) {
		viewToMove++;
	}
	
	if(viewToMove < 0 || viewToMove >= count) [NSException raise:@"OutOfBounds" format:@"View index %d out of bounds (0,%d(", viewToMove, count];
	
	CGSize viewSize = self.view.bounds.size;
	if(!locked) {
		_IQDrilldownPanel* panelToMove = [panels objectAtIndex:viewToMove];
		
		CGRect viewFrame = panelToMove.frame;
		
		if(viewToMove == count - 1 && left && activeViewRightAligned) {
			enableRubberBand = YES;
		} else if(viewToMove == 0 && !left && activeViewRightAligned) {
			enableRubberBand = YES;
		}
		
		CGFloat moveScale = 1.0f;
		if(enableRubberBand) {
			if(left) moveScale = (panelToMove.origin.x - minimizedMargin) / viewSize.width;
			else moveScale = (viewFrame.size.width*.5) / viewSize.width;
		}
		CGFloat x = panelToMove.origin.x + pt.x * moveScale;
		if(x < minimizedMargin && left && !(activeIndex >= count - 2)) {
			BOOL doAlignRight = NO;
			if(!activeViewRightAligned) {
				doAlignRight = YES;
			}
			[self goRightAnimated:NO];
			if(doAlignRight) {
				activeViewRightAligned = NO;
				[self doLayout:NO];
			}
			[gesture setTranslation:CGPointMake(0, 0) inView:self.view];
		} else if (viewToMove == count - 1 && !activeViewRightAligned && left && x + viewFrame.size.width < viewSize.width) {
			[self goRightAnimated:NO];
			[gesture setTranslation:CGPointMake(0, 0) inView:self.view];
		}
		[self moveView:viewToMove to:x];
	}
	if(gesture.state == UIGestureRecognizerStateEnded) {
		inPan = NO;
		CGFloat delta = pt.x + v.x*0.1;
		NSLog(@"Delta = %f = %f + %f", delta, pt.x, v.x);
		if(delta < -viewSize.width*.2) {
			[self goRightAnimated:YES];
		} else if(delta > viewSize.width*.2) {
			[self goLeftAnimated:YES];
		}
		else [self doLayout:YES];
	}
}


- (IBAction) debugAction1:(id)sender {
	activeViewRightAligned = NO;
	[self doLayout:YES];
}
- (IBAction) debugAction2:(id)sender {
	activeViewRightAligned = YES;
	[self doLayout:YES];
}

- (void)handleSwipe:(UISwipeGestureRecognizer*)swipe {
	/*if(swipe == swipeLeft) {
	 NSLog(@"<<<<<----");
	 [self goRight];
	 } else if(swipe == swipeRight) {
	 NSLog(@"---->>>>>");
	 [self goLeft];
	 
	 }*/
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

@end

@implementation _IQDrilldownPanel
@synthesize hostedViewController, origin;

- (id) initWithViewController:(UIViewController*)viewController parent:(IQDrilldownController*)parentViewController
{
    self = [super initWithFrame:viewController.view.frame];
    if(self) {
        parent = parentViewController;
        hostedViewController = viewController;
        hostedViewController.view.frame = hostedViewController.view.bounds;
        hostedViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self addSubview:viewController.view];
    }
    return self;
}

- (void) dealloc
{
    [hostedViewController release];
    [super dealloc];
}

@end