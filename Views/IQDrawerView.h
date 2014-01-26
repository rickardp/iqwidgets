//
//  IQDrawerView.h
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-10-01.
//  Copyright (c) 2011 EvolvIQ. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _IQDrawerViewStyle {
    IQDrawerViewStylePlain,
    IQDrawerViewStyleBarDefault,
    IQDrawerViewStyleBarBlack
} IQDrawerViewStyle;

typedef enum _IQDrawerViewAlign {
    IQDrawerViewAlignTop,
    IQDrawerViewAlignBottom
} IQDrawerViewAlign;

@class IQDrawerHeaderView, IQDrawerView;

@protocol IQDrawerViewDelegate
@optional
- (void) drawer:(IQDrawerView*)drawer willChangeState:(BOOL)expanded;
- (void) drawer:(IQDrawerView*)drawer didChangeState:(BOOL)expanded;
@end

@interface IQDrawerView : UIView {
    IQDrawerViewStyle style;
    CGFloat contentHeight;
    BOOL bottom;
    BOOL expanded;
    IQDrawerHeaderView* header;
    UIView* backgroundView;
    UIView* contentView;
    BOOL backgroundViewIsImage;
}

- (id) initWithStyle:(IQDrawerViewStyle)style align:(IQDrawerViewAlign)align;
- (void) setExpanded:(BOOL)expanded animated:(BOOL)animated;
- (void) toggleExpanded;

// The background image for the drawer inside. If set, any previous backgroundView or backgroundImage is
// removed.
@property (nonatomic, retain) UIImage* backgroundImage;
// The background image for the drawer inside. If set, any previous backgroundView or backgroundImage is
// removed.
@property (nonatomic, retain) UIColor* backgroundColor;
// The view used to display the background of the drawer inside. If backgroundColor or backgroundImage is set,
// it is automatically created to be a UIImageView. If not set, it is nil. An application can set this to any
// view.
@property (nonatomic, retain) UIView* backgroundView;
// The content view used for the drawer inside. If not set, it is created as a transparent UIView on first access.
// The height of this view controls the height of the drawer.
@property (nonatomic, retain) UIView* contentView;

@property (nonatomic, retain) id<IQDrawerViewDelegate> drawerDelegate;

// The expanded (open) state. If set, equivalent to [... setExpanded:expanded animated:YES]
@property (nonatomic) BOOL expanded;

// The shadow opacity
@property (nonatomic) CGFloat shadowOpacity;
// The shadow offset. Default depends on the alignment
@property (nonatomic) CGSize shadowOffset;
// The shadow radius.
@property (nonatomic) CGFloat shadowRadius;
@property (nonatomic, retain) UIColor* shadowColor;

@end
