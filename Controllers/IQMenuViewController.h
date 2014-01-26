//
//  IQMenuViewController.h
//  DrilldownTest
//
//  Created by Rickard Petzäll on 2012-09-29.
//  Copyright (c) 2012 EvolvIQ. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IQTheme.h"

@class IQMenuItem;
@class IQMenuSection;

@interface IQMenuViewController : UIViewController <IQThemeable>

#pragma mark - Contents
- (void) addSection:(IQMenuSection*)section animated:(BOOL)animated;
- (void) removeSection:(IQMenuSection*)section animated:(BOOL)animated;
- (void) removeAllSections;
- (NSInteger) count;
- (IQMenuSection*) sectionAtIndex:(NSInteger)index;

#pragma mark - Appearance
@property (nonatomic, retain) id<IQThemeProvider> theme;
@property (nonatomic, retain) NSString* themeUniqueIdentifier;
@property (nonatomic, retain) NSSet* themeClasses;

#pragma mark - View hierarchy
@property (nonatomic, readonly) UITableView* tableView;
@end

@interface IQMenuSection : NSObject  <IQThemeable>

+ (IQMenuSection*) sectionWithTitle:(NSString*)headerTitle;

- (void) addItem:(IQMenuItem*)item animated:(BOOL)animated;
- (void) removeItem:(IQMenuItem*)item animated:(BOOL)animated;
- (void) removeAllItemsAnimated:(BOOL)animated;
- (NSInteger) count;
- (IQMenuSection*) itemAtIndex:(NSInteger)index;

- (IQMenuViewController*) menuViewController;

@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* footerText;
@property (nonatomic) BOOL hidden;
- (void) setHidden:(BOOL)hidden animated:(BOOL)animated;
@property (nonatomic) BOOL hideIfEmpty; /* Default is NO */

#pragma mark - Appearance
@property (nonatomic, retain) id<IQThemeProvider> theme;
@property (nonatomic, retain) NSString* themeUniqueIdentifier;
@property (nonatomic, retain) NSSet* themeClasses;
@end

@interface IQMenuItem : NSObject
+ (IQMenuItem*) itemWithTitle:(NSString*)title action:(void (^)())action;

/**
 Invoked when the item is activated. Overridable. Default calles the item's action block if set, otherwise
 does nothing.
 */
- (void) itemActivated;

- (IQMenuItem*) section;
- (IQMenuViewController*) menuViewController;

@property (nonatomic, retain) NSString* title;
@property (nonatomic) BOOL hidden;
- (void) setHidden:(BOOL)hidden animated:(BOOL)animated;
@end

