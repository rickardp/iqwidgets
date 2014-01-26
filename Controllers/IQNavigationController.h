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

#import <UIKit/UIKit.h>

#import "IQTheme.h"

typedef enum IQNavigationPanType {
    /**
     Allow the user to show the sidebar by swiping the finger from the far side of the screen towards the center.
     */
    IQNavigationPanTypeDefault = 0,
    /**
     Do not allow the user to show the sidebar by swiping.
     */
    IQNavigationPanTypeNone = 1,
    /**
     Allow the user to show the sidebar by swiping anywhere on the screen.
     */
    IQNavigationPanTypeAll = 2
} IQNavigationPanType;

typedef enum IQNavigationSidebarRevealType {
    IQNavigationSidebarRevealTypeSlideUnder = 0,
    IQNavigationSidebarRevealTypeStaticUnder = 1,
    IQNavigationSidebarRevealTypeScroll = 2
} IQNavigationSidebarRevealType;

typedef enum IQNavigationSidebarViewMode {
    IQNavigationSidebarViewModeResize = 0,
    IQNavigationSidebarViewModeClip = 1
} IQNavigationSidebarViewMode;

@class IQNavigationController;

@protocol IQNavigationControllerDelegate < UINavigationControllerDelegate >
@optional
- (void) navigationController:(IQNavigationController *)navigationController willShowSidebar:(UIViewController *)sidebarController animated:(BOOL)animated;
- (void) navigationController:(IQNavigationController *)navigationController didShowSidebar:(UIViewController *)sidebarController animated:(BOOL)animated;
- (void) navigationController:(IQNavigationController *)navigationController willHideSidebar:(UIViewController *)sidebarController animated:(BOOL)animated;
- (void) navigationController:(IQNavigationController *)navigationController didHideSidebar:(UIViewController *)sidebarController animated:(BOOL)animated;
@end

/**
 An extended UINavigationController that adds support for theming and a revealable sidebar as used in many popular iOS applications (such as the Facebook app).
 
 A lot of effort has been put into this class to make it a drop-in replacement for the `UINavigationController` to easily add the sidebar functionality to 
 existing applications.
 */
@interface IQNavigationController : UINavigationController <IQThemeable>
/**
 Convenience initialization method that takes the root view controller and the sidebar view controller.
 */
- (id) initWithRootViewController:(UIViewController*)rootViewController sidebarViewController:(UIViewController*)sidebarViewController;

#pragma mark - Sidebar
/**
 The sidebar view controller. Not changeable once the view controller is constructed.
 */
@property (nonatomic, retain) IBOutlet UIViewController* sidebarViewController;
/**
 Hides or reveals the sidebar, optionally using a slide animation.
 */
- (void) setSidebarVisible:(BOOL)visible animated:(BOOL)animated;
/**
 The revealed status of the sidebar. Will use animation if set.
 */
@property (nonatomic) BOOL sidebarVisible;
/**
 The icon used for the sidebar toggle image. If set, the view controller will set the toggle icon on the root navigation item. If set to nil,
 the default icon (a schematic item list) will be used.
 */
@property (nonatomic, retain) UIImage* sidebarToggleButtonIcon;
/**
 If YES, allows the user to toggle the sidebar display. If NO, the gestures to change the sidebar status will be disabled, and the nav bar button
 will be hidden, but the sidebar can still be shown programmatically by using the `sidebarVisible` property. Default is YES.
 */
@property (nonatomic) BOOL sidebarEnabled;

#pragma mark - Appearance
@property (nonatomic, retain) id<IQThemeProvider> theme;
@property (nonatomic, retain) NSString* themeUniqueIdentifier;
@property (nonatomic, retain) NSSet* themeClasses;
@property (nonatomic) IQNavigationPanType panType;
@property (nonatomic) IQNavigationSidebarRevealType revealType;
@property (nonatomic) IQNavigationSidebarViewMode sidebarViewMode;

@end
