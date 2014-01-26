//
//  IQTheme.h
//  IQWidgets for iOS
//
//  Copyright 2012 Rickard Petzäll, EvolvIQ
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

#import <UIKit/UIKit.h>

extern NSString* kIQThemeNotificationDefaultThemeChanged;
extern NSString* kIQThemeNotificationThemeChanged;

@class IQTheme;

@protocol IQThemeable
@required
- (NSString*) themeElementName;
@optional
- (NSString*) themeUniqueIdentifier;
- (NSSet*) themeClasses;
- (NSObject<IQThemeable>*) parentThemeable;
@end

@interface IQThemeTextShadow : NSObject
@property (nonatomic) CGPoint offset;
@property (nonatomic) float blur;
@property (nonatomic, retain) UIColor* color;
- (id) initWithCssString:(NSString*)cssString;
@end

/**
 A generalized protocol allowing one object to provide multiple themes based
 on the widget provided. This protocol is implemented by IQTheme, returning itself,
 allowing either a theme or a theme provider to be set as theme for widgets.
 */
@protocol IQThemeProvider <NSObject>
@required
- (IQTheme*) themeForWidget:(NSObject*)widget;
@end

typedef enum IQThemeViewApplyFlags {
    IQThemeViewApplyVisibility = 1,
    IQThemeViewApplyBackgroundStyle = 2,
    IQThemeViewApplyTextStyle = 4,
    IQThemeViewApplyLayerStyle = 8,
    IQThemeViewApplyAllStyles = 0xFFFFFFFF
} IQThemeViewApplyFlags;

typedef enum IQThemeTristate {
    IQThemeNo = 0,
    IQThemeYes = 1,
    IQThemeNotSet = -1
} IQThemeTristate;

/**
 A generic theme interface for UI elements. All IQWidgets elements are themeable using the IQTheme class.
 The IQTheme class provides the default look and feel used if no theme is set, and provides a base implementation
 that can be overridden by subclassing IQTheme.
 
 For an easy, declarative theming using a CSS-style algorithm, look into IQMutableTheme.
 */
@interface IQTheme : NSObject <IQThemeProvider>
+ (IQTheme*) defaultTheme;
+ (void) setDefaultTheme:(IQTheme*)theme;
+ (NSObject<IQThemeable>*) themeableForElement:(NSString*)element ofParent:(NSObject<IQThemeable>*)parent defaultInherit:(BOOL)inherit;

+ (NSSet*) themeClassesFor:(NSObject<IQThemeable>*)themeable;
+ (NSString*) themeUniqueIdentifierFor:(NSObject<IQThemeable>*)themeable;

/**
 Applies theming to the specified view using the specified themeable. The flags control which aspect(s) of the
 view to theme.
 
 Returns YES if any property was changed, NO otherwise.
 */
- (BOOL) applyToView:(UIView*)view for:(NSObject<IQThemeable>*)themeable flags:(IQThemeViewApplyFlags)flags;

- (IQThemeTristate) isHidden:(NSObject<IQThemeable>*)themeable;

- (UIFont*) fontFor:(NSObject<IQThemeable>*)themeable;
- (UITextAlignment) textAlignmentFor:(NSObject<IQThemeable>*)themeable;

- (UIColor*) colorFor:(NSObject<IQThemeable>*)themeable;
- (UIColor*) backgroundColorFor:(NSObject<IQThemeable>*)themeable;
- (UIColor*) borderColorFor:(NSObject<IQThemeable>*)themeable;
- (IQThemeTextShadow*) textShadowFor:(NSObject<IQThemeable>*)themeable;

- (UITableViewStyle) tableViewStyleFor:(NSObject<IQThemeable>*)themeable;
@end

/**
 An implementation of IQTheme that allows the specification of theming using CSS-style selectors. Each themeable element
 can specify a set of classes (similar to CSS classes) and a unique identifier (similar to CSS id). Each themeable property
 is looked up in order so that the most specific selector takes precedence over less specific selectors.
 
 For each settable property, the setter takes an argument that is either a specific themeable object or a CSS-style
 selector (e.g. "menu .myClass" or "calendar #mainCalendar" etc.). Note that currently only a subset of the CSS selector
 syntax is supported. Specifically, child elements ("E > F"), attributes ("E[foo=bar]") and siblings ("E + F") are not
 supported. Supported syntax is element ("E"), parent elements ("E F"), classes ("E.myclass"), ID ("E#myid") and 
 wildcard ("*"), and a combination of these.
 
 Another notable limitation is that compound styles are not supported (for example 'font', 'border'). Use the specific
 styles (i.e. 'font-family', 'font-size') instead.
 
 For color properties, the #xxxxxx (hex) and rgb(n,n,n) styles are supported. Named colors 'transparent' and the 
 16 basic colors are supported.
 */
@interface IQMutableTheme : IQTheme

- (void) setFont:(UIFont*)font for:(NSObject*)themeableOrString;
- (void) setTextAlignment:(UITextAlignment)textAlignment for:(NSObject*)themeableOrString;
- (void) setTableViewStyle:(UITableViewStyle)style for:(NSObject*)themeableOrString;
- (void) setColor:(UIColor*)color for:(NSObject*)themeableOrString;
- (void) setBackgroundColor:(UIColor*)bgcolor for:(NSObject*)themeableOrString;
- (void) setBorderColor:(UIColor*)bdcolor for:(NSObject*)themeableOrString;

- (NSString*) CSSText;

@end
