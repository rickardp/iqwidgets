//
//  IQNavigationController.h
//  IQWidgets for iOS
//
//  Copyright 2010-2014 Rickard Petzäll
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

#import "IQNavigationController.h"
#import <QuartzCore/QuartzCore.h>

/**
 Retardation due to friction when panning stops.
 */
#define FRICTION_RETARDATION 1500.0f
#define SHADOW_SIZE 10.0f
#define SHADOW_INTENSITY 0.5f
@interface IQNavigationController () <UIGestureRecognizerDelegate> {
    BOOL hasNotifications;
    BOOL hasView;
    UIView* parentView;
    __weak UIBarButtonItem* lastShowSidebarButton;
    UIPanGestureRecognizer* openSidebarPan;
    UIPanGestureRecognizer* closeSidebarPan;
    UITapGestureRecognizer* closeSidebarTap;
    CGFloat rootOverlayOffset;
    UIView* rootOverlayView;
    CALayer* shadowLayer;
    CGFloat panStartX;
    BOOL sidebarDisabled;
}
- (void) _updateTheme;
- (void) _checkThemeChange:(NSNotification*)notification;
- (void) _toggleSidebar;
@end

@implementation IQNavigationController
@synthesize sidebarViewController, sidebarVisible, theme;

- (id) initWithRootViewController:(UIViewController*)rootViewController sidebarViewController:(UIViewController*)viewController
{
    self = [super initWithRootViewController:rootViewController];
    if(self) {
        self.sidebarViewController = viewController;
        rootOverlayOffset = 58.0f;
    }
    return self;
}

- (void) dealloc
{
    if(!hasNotifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kIQThemeNotificationThemeChanged object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kIQThemeNotificationDefaultThemeChanged object:nil];
    }
}

- (void) loadView
{
    [super loadView];
    
    parentView = [[UIView alloc] initWithFrame:super.view.frame];
    UIView* sview = [super view];
    UIView* spar = sview.superview;
    [sview removeFromSuperview];
    [parentView addSubview:sview];
    [spar addSubview:parentView];
    if(!hasNotifications) {
        hasNotifications = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_checkThemeChange:) name:kIQThemeNotificationThemeChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_checkThemeChange:) name:kIQThemeNotificationDefaultThemeChanged object:nil];
    }
    
    openSidebarPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_openPan)];
    openSidebarPan.delegate = self;
    closeSidebarPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_closePan)];
    closeSidebarPan.delegate = self;
    closeSidebarPan.enabled = NO;
    closeSidebarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_closeTap)];
    closeSidebarTap.delegate = self;
    closeSidebarTap.enabled = NO;
    
    [self.view addGestureRecognizer:openSidebarPan];
	hasView = YES;
    rootOverlayView = [[UIView alloc] initWithFrame:sview.bounds];
    [sview addSubview:rootOverlayView];
    rootOverlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
    rootOverlayView.hidden = YES;
    rootOverlayView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [rootOverlayView addGestureRecognizer:closeSidebarTap];
    [rootOverlayView addGestureRecognizer:closeSidebarPan];
    
    shadowLayer = [CALayer new];
    CGRect frame = sview.frame;
    //frame.origin.x = -frame.size.width;
    shadowLayer.frame = frame;
    [sview.layer insertSublayer:shadowLayer atIndex:0];
    //shadowLayer.backgroundColor = [UIColor clearColor].CGColor;
    //shadowLayer.opacity = 0.1f;
    shadowLayer.shadowPath = CGPathCreateWithRect(sview.bounds, nil);
    shadowLayer.shadowOffset = CGSizeMake(-1, 0);
    shadowLayer.shadowRadius = SHADOW_SIZE;
    shadowLayer.shadowOpacity = SHADOW_INTENSITY;
    [self _adjustSidebarPosition:0];
    [self _updateTheme];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [sidebarViewController didReceiveMemoryWarning];
}

#pragma mark - Theming

- (NSString*) themeElementName
{
    return @"nav";
}

- (void) setTheme:(id<IQThemeProvider>)thm
{
    self->theme = thm;
    [self _updateTheme];
}

- (void) _checkThemeChange:(NSNotification*)notification
{
    if(hasView) {
        if([notification.name isEqualToString:kIQThemeNotificationDefaultThemeChanged]) {
            if(theme == nil) {
                [self _updateTheme];
            }
        } else if([notification.name isEqualToString:kIQThemeNotificationThemeChanged]) {
            if((theme != nil && notification.object == theme) || (theme == nil && notification.object == [IQTheme defaultTheme])) {
                [self _updateTheme];
            }
        }
    }
}

- (void) _updateTheme
{
    if(hasView) {
        IQTheme* thm = self.theme;
        if(!thm) thm = [IQTheme defaultTheme];
        
        NSObject<IQThemeable>* navBar = [IQTheme themeableForElement:@"navbar" ofParent:self defaultInherit:YES];
        UIColor* tintColor = [thm backgroundColorFor:navBar];
        self.navigationBar.tintColor = tintColor;
        BOOL nbh = [thm isHidden:navBar] == IQThemeYes;
        if(nbh != self.navigationBarHidden) {
            self.navigationBarHidden = nbh;
        }
    }
}

#pragma mark - Sidebar

- (void) setSidebarVisible:(BOOL)visible animated:(BOOL)animated
{
    // Do not allow sidebar to be revealed if not the top view controller
    if(self.viewControllers.count > 1 && visible) return;
    CGRect frm = super.view.frame;
    if(visible) {
        frm.origin.x = super.view.frame.size.width-rootOverlayOffset;
        [self _adjustSidebarSize];
    } else {
        frm.origin.x = 0;
    }
    BOOL isChange = self->sidebarVisible != visible;
    self->sidebarVisible = visible;
    closeSidebarTap.enabled = visible;
    closeSidebarPan.enabled = visible;
    openSidebarPan.enabled = !visible;
    if(isChange) {
        if(visible && [self.delegate respondsToSelector:@selector(navigationController:willShowSidebar:animated:)]) {
            [(id)self.delegate navigationController:self willShowSidebar:sidebarViewController animated:animated];
        } else if(!visible && [self.delegate respondsToSelector:@selector(navigationController:willHideSidebar:animated:)]) {
            [(id)self.delegate navigationController:self willHideSidebar:sidebarViewController animated:animated];
        }
    }
    if(animated) {
        if(rootOverlayView.hidden) {
            rootOverlayView.alpha = 0;
            rootOverlayView.hidden = NO;
        }
        [UIView animateWithDuration:0.5 animations:^{
            super.view.frame = frm;
            rootOverlayView.alpha = visible ? 1.0f : 0.0f;
            shadowLayer.shadowRadius = visible ? 0 : SHADOW_SIZE;
            shadowLayer.shadowOpacity = visible ? 0 : SHADOW_INTENSITY;
            [self _adjustSidebarPosition:visible?1:0];
        } completion:^(BOOL finished) {
            if(!visible) {
                rootOverlayView.hidden = YES;
            }
            if(isChange) {
                if(visible && [self.delegate respondsToSelector:@selector(navigationController:didShowSidebar:animated:)]) {
                    [(id)self.delegate navigationController:self didShowSidebar:sidebarViewController animated:animated];
                } else if(!visible && [self.delegate respondsToSelector:@selector(navigationController:didHideSidebar:animated:)]) {
                    [(id)self.delegate navigationController:self didHideSidebar:sidebarViewController animated:animated];
                }
                // Reset sidebar if app pushed a view controller during our animation
                if(self.viewControllers.count > 1 && visible) self.sidebarVisible = NO;
            }
        }];
    } else {
        super.view.frame = frm;
        rootOverlayView.hidden = !visible;
        [self _adjustSidebarPosition:visible?1:0];
        if(isChange) {
            if(visible && [self.delegate respondsToSelector:@selector(navigationController:didShowSidebar:animated:)]) {
                [(id)self.delegate navigationController:self didShowSidebar:sidebarViewController animated:animated];
            } else if(!visible && [self.delegate respondsToSelector:@selector(navigationController:didHideSidebar:animated:)]) {
                [(id)self.delegate navigationController:self didHideSidebar:sidebarViewController animated:animated];
            }
        }
    }
}

- (void) setSidebarVisible:(BOOL)visible
{
    [self setSidebarVisible:visible animated:hasView];
}

- (void) _toggleSidebar
{
    [self setSidebarVisible:!sidebarVisible];
}

- (void) _setLeftNavbarButton:(UIBarButtonItem*)button {
    if(self.viewControllers.count > 0) {
        UIViewController* root = [self.viewControllers objectAtIndex:0];
        
        UIBarButtonItem* last = lastShowSidebarButton;
        if(last != nil) {
            NSMutableArray* a = [root.navigationItem.leftBarButtonItems mutableCopy];
            [a removeObject:last];
            root.navigationItem.leftBarButtonItems = a;
        }
        lastShowSidebarButton = button;
        if(button) {
            NSMutableArray* a = [root.navigationItem.leftBarButtonItems mutableCopy];
            if(a) {
                [a insertObject:button atIndex:0];
                root.navigationItem.leftBarButtonItems = a;
            } else {
                root.navigationItem.leftBarButtonItems = @[button];
            }
        }
    }
}

- (void) setSidebarToggleButtonIcon:(UIImage *)sidebarToggleButtonIcon {
    self->_sidebarToggleButtonIcon = sidebarToggleButtonIcon;
    UIBarButtonItem* showSidebarButton = nil;
    if(self->sidebarViewController) {
        if(sidebarToggleButtonIcon == nil) {
            showSidebarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(_toggleSidebar)];
        } else {
            showSidebarButton = [[UIBarButtonItem alloc] initWithImage:self.sidebarToggleButtonIcon style:UIBarButtonItemStylePlain target:self action:@selector(_toggleSidebar)];
        }
    }
    if(!sidebarDisabled) {
        [self _setLeftNavbarButton:showSidebarButton];
    } else {
        [self _setLeftNavbarButton:nil];
    }
}

- (UIView*) view
{
    if(parentView != nil) {
        return parentView;
    }
    return [super view];
}

- (void) setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
    if(self->sidebarVisible) {
        [super setViewControllers:viewControllers animated:NO];
        [self setSidebarVisible:NO animated:animated];
    } else {
        [super setViewControllers:viewControllers animated:animated];
    }
    // Refresh nav bar button
    self.sidebarToggleButtonIcon = self.sidebarToggleButtonIcon;
}

- (void) setSidebarViewController:(UIViewController *)viewController
{
    if(self->sidebarViewController) {
        [self->sidebarViewController.view removeFromSuperview];
    }
    self->sidebarViewController = viewController;
    if(viewController) {
        [parentView insertSubview:viewController.view atIndex:0];
    }
    if(viewController) {
        [self.view insertSubview:sidebarViewController.view atIndex:0];
    }
    self.sidebarViewMode = self.sidebarViewMode;
    self.sidebarToggleButtonIcon = self.sidebarToggleButtonIcon;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(self.sidebarVisible) {
        [self setSidebarVisible:NO animated:NO];
        [self setSidebarVisible:YES animated:NO];
    }
}

- (void) setSidebarEnabled:(BOOL)sidebarEnabled
{
    if(sidebarDisabled == sidebarEnabled) {
        sidebarDisabled = !sidebarEnabled;
        self.sidebarToggleButtonIcon = self.sidebarToggleButtonIcon;
    }
}

- (BOOL) sidebarEnabled
{
    return !sidebarDisabled;
}

#pragma mark - Gestures


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if(sidebarDisabled || !self.topViewController || self.viewControllers.count == 0 || self.topViewController != self.viewControllers[0]) {
        return NO;
    }
    if(gestureRecognizer == openSidebarPan) {
        CGPoint location = [openSidebarPan locationInView:self.view];
        switch(self.panType) {
            case IQNavigationPanTypeAll:
                return YES;
            case IQNavigationPanTypeNone:
                return NO;
            case IQNavigationPanTypeDefault:
                return location.x < 64;
        }
    } else if(gestureRecognizer == closeSidebarTap || gestureRecognizer == closeSidebarPan) {
        //NSLog(@"Checking %d", self.sidebarVisible);
        return self.sidebarVisible;
    }
    return NO;
}

// Move the sidebar view as the revelation progresses
- (void) _adjustSidebarPosition:(CGFloat)progress
{
    CGRect sidebarRect = sidebarViewController.view.frame;
    sidebarRect.origin.x = 0;
    switch(self.revealType) {
        case IQNavigationSidebarRevealTypeSlideUnder:
            sidebarRect.origin.x = -0.5 * (1-progress) * sidebarRect.size.width;
            break;
        case IQNavigationSidebarRevealTypeScroll:
            sidebarRect.origin.x = - (1-progress) * sidebarRect.size.width;
            break;
        default:
            break;
    }
    sidebarViewController.view.frame = sidebarRect;
}

// Pre-adjust the sidebar size according to view settings
- (void) _adjustSidebarSize
{
    if(self.sidebarViewMode == IQNavigationSidebarViewModeResize) {
        CGFloat width = super.view.frame.size.width-rootOverlayOffset;
        CGRect r = sidebarViewController.view.frame;
        //if(r.size.width > width)
        r.size.width = width;
        sidebarViewController.view.frame = r;
    }
}

- (void) _animatePan:(CGFloat)nx
{
    CGRect frm = super.view.frame;
    CGFloat maxValue = frm.size.width-rootOverlayOffset;
    if(nx > maxValue) {
        nx = maxValue;
    } else if(nx < 0) {
        nx = 0;
    }
    frm.origin.x = nx;
    super.view.frame = frm;
    if(rootOverlayView.hidden) rootOverlayView.hidden = NO;
    CGFloat factor = nx / maxValue;
    rootOverlayView.alpha = factor;
    shadowLayer.shadowRadius = (1-factor) * SHADOW_SIZE;
    shadowLayer.shadowOpacity = (1-factor) * SHADOW_INTENSITY;
    [self _adjustSidebarPosition:factor];
}

- (void) _finishPanningWithGestureRecognizer:(UIPanGestureRecognizer*)gestureRecognizer
{
    CGFloat width = super.view.frame.size.width-rootOverlayOffset;
    CGPoint loca = [gestureRecognizer locationInView:super.view];
    CGPoint vel = [gestureRecognizer velocityInView:super.view];
    CGFloat distance = 2 * fabs(vel.x) * vel.x / FRICTION_RETARDATION;;
    CGRect frm = super.view.frame;
    CGFloat nx = distance + loca.x - panStartX;
    if(nx > width) {
        nx = width;
    } else if(nx < 0) {
        nx = 0;
    }
    BOOL vis;
    if(gestureRecognizer == closeSidebarPan) {
        vis = nx > width - 200.0f;
    } else {
        vis = nx > 200.0f;
    }
    CGFloat retardationTime = 10 * fabs((nx - frm.origin.x) / vel.x);
    if(retardationTime > 0.5) retardationTime = 0.5;
    if(retardationTime < 0.1) retardationTime = 0.1;
    frm.origin.x = nx;
    if(vis != self.sidebarVisible) {
        self.sidebarVisible = vis;
    } else {
        [UIView animateWithDuration:retardationTime animations:^{
            [self _animatePan:nx];
        } completion:^(BOOL finished) {
            self.sidebarVisible = vis;
        }];
    }
}

- (void) _openPan
{
    if(openSidebarPan.state == UIGestureRecognizerStateEnded) {
        [self _finishPanningWithGestureRecognizer:openSidebarPan];
    } else if(openSidebarPan.state == UIGestureRecognizerStateBegan) {
        panStartX = [openSidebarPan locationInView:super.view.superview].x;
        [self _adjustSidebarSize];
    } else if(openSidebarPan.state == UIGestureRecognizerStateChanged) {
        CGPoint loca = [openSidebarPan locationInView:super.view.superview];
        [self _animatePan:loca.x - panStartX];
    }
}

- (void) _closePan
{
    if(closeSidebarPan.state == UIGestureRecognizerStateEnded) {
        [self _finishPanningWithGestureRecognizer:closeSidebarPan];
    } else if(closeSidebarPan.state == UIGestureRecognizerStateBegan) {
        CGFloat width = super.view.frame.size.width-rootOverlayOffset;
        panStartX = [closeSidebarPan locationInView:super.view.superview].x - width;
        [self _adjustSidebarSize];
    } else if(closeSidebarPan.state == UIGestureRecognizerStateChanged) {
        CGPoint loca = [closeSidebarPan locationInView:super.view.superview];
        [self _animatePan:loca.x - panStartX];
    }
}

- (void) _closeTap
{
    if(closeSidebarTap.state == UIGestureRecognizerStateEnded) {
        self.sidebarVisible = NO;
    }
}

- (void) setSidebarViewMode:(IQNavigationSidebarViewMode)sidebarViewMode
{
    self->_sidebarViewMode = sidebarViewMode;
    CGRect vr = sidebarViewController.view.frame;
    CGRect ar = super.view.frame;
    if(sidebarViewMode == IQNavigationSidebarViewModeClip) {
        vr.size.width = ar.size.width;
    } else {
        vr.size.width = ar.size.width - rootOverlayOffset;
    }
}

@end
