//
//  IQGanttView.h
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
#import "IQScrollView.h"

@protocol IQGanttHeaderDelegate;
@protocol IQGanttRowDelegate;
@protocol IQCalendarDataSource;
@class IQGanttView;

typedef UIView* (^IQGanttBlockViewCreationCallback)(IQGanttView* gantt, UIView* rowView, id item, CGRect frame);
typedef NSInteger (^IQGanttRowHeightCallback)(IQGanttView* gantt, UIView* rowView, id<IQCalendarDataSource> rowData);

typedef struct _IQGanttViewTimeWindow {
    NSTimeInterval windowStart, windowEnd;
    NSTimeInterval viewStart, viewSize;
} IQGanttViewTimeWindow;

@interface IQGanttView : IQScrollView {
@private
    NSInteger defaultRowHeight;
    NSMutableArray* rows;
    NSMutableArray* rowViews;
    IQGanttViewTimeWindow scaleWindow;
    NSCalendarUnit displayCalendarUnits;
    IQGanttBlockViewCreationCallback createBlock;
    IQGanttRowHeightCallback rowHeight;
    NSCalendar* calendar;
}

@property (nonatomic) IQGanttViewTimeWindow scaleWindow;
@property (nonatomic) NSCalendarUnit displayCalendarUnits;
@property (nonatomic) NSInteger defaultRowHeight;
@property (nonatomic, retain) NSCalendar* calendar;

- (void)removeAllRows;
- (void)addRow:(id<IQCalendarDataSource>)row;

// Overridable methods. Subclass IQGanttView and override the below methods
// to achieve further customization of the user interface.
- (UIView*) createCornerViewWithFrame:(CGRect)frame; // default implementation returns nil
- (UIView<IQGanttHeaderDelegate>*) createTimeHeaderViewWithFrame:(CGRect)frame; // default implementation returns a IQGanttHeaderView
- (UIView*) createRowHeaderViewWithFrame:(CGRect)frame; // default implementation returns nil

- (UIView<IQGanttRowDelegate>*) createViewForRow:(id<IQCalendarDataSource>)row withFrame:(CGRect)frame; // default implementation returns a IQGanttRowView 

@end

// This category uses blocks for defining a call-back interface. This
// option performs better with large data sets and allows for more
// customization than the simple interface.

@interface IQGanttView (CallbackInterface)
- (void) setBlockCreationCallback:(IQGanttBlockViewCreationCallback)callback;
- (void) setRowHeightCallback:(IQGanttRowHeightCallback)callback;
@end


@protocol IQGanttHeaderDelegate
@optional
- (void)ganttView:(IQGanttView*)view didScaleWindow:(IQGanttViewTimeWindow)win;
- (void)ganttView:(IQGanttView*)view didMoveWindow:(IQGanttViewTimeWindow)win;
- (void)ganttView:(IQGanttView*)view shouldDisplayCalendarUnits:(NSCalendarUnit) displayCalendarUnits;
- (void)ganttView:(IQGanttView*)view didChangeCalendar:(NSCalendar*)calendar;
@end

@protocol IQGanttRowDelegate
@optional
- (void)ganttView:(IQGanttView*)view didChangeDataSource:(id<IQCalendarDataSource>)dataSource;
- (void)ganttView:(IQGanttView*)view didChangeCalendar:(NSCalendar*)calendar;
- (void)ganttView:(IQGanttView*)view didScaleWindow:(IQGanttViewTimeWindow)win;
- (void)ganttView:(IQGanttView*)view didMoveWindow:(IQGanttViewTimeWindow)win;
@end

@interface IQGanttHeaderView : UIView <IQGanttHeaderDelegate> {
@private
    IQGanttViewTimeWindow scaleWindow;
    CGFloat offset;
    UIColor* tintColor;
    CGGradientRef grad;
    CGColorRef border;
    NSCalendarUnit displayCalendarUnits;
    NSMutableArray* floatingLabels;
    char weekdayLetters[8];
    char weekPrefixChar;
    NSCalendar* cal;
    NSDateFormatter* monthNameFormatter;
}

@property (nonatomic, retain) UIColor* tintColor;
@property (nonatomic, readonly) NSDateFormatter* monthNameFormatter;
@end

@interface IQGanttRowView : UIView <IQGanttRowDelegate> {
@private
    NSCalendar* cal;
    UIColor* gridColor;
    IQGanttViewTimeWindow scaleWindow;
    NSCalendarUnit primaryLineUnits;
    NSCalendarUnit secondaryLineUnits;
    NSCalendarUnit tertaryLineUnits;
}

@property (nonatomic, retain) id<IQCalendarDataSource> dataSource;
@property (nonatomic, retain) UIColor* gridColor;

// Overridable. Called to create and manage the subviews.
- (void) layoutItems;
@end
