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
- (UIView*) cornerViewWithFrame:(CGRect)frame; // default implementation returns nil
- (UIView<IQGanttHeaderDelegate>*) timeHeaderViewWithFrame:(CGRect)frame; // default implementation returns a IQGanttHeaderView
- (UIView*) rowHeaderViewWithFrame:(CGRect)frame; // default implementation returns nil

- (UIView<IQGanttRowDelegate>*) viewForRow:(id<IQCalendarDataSource>)row withFrame:(CGRect)frame; // default implementation returns a IQGanttRowView

// Override this method to define a custom view creation. Detfault is to create a themeable simple view.
- (UIView*) createViewForActivityWithFrame:(CGRect)frame text:(NSString*)text;

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
    NSCalendar* cal;
    NSDateFormatter* monthNameFormatter;
}

@property (nonatomic, retain) UIColor* tintColor;
@property (nonatomic, readonly) NSDateFormatter* monthNameFormatter;
@end

typedef struct _IQGridDash {
    CGFloat a,b;
} IQGridDash;

static IQGridDash IQMakeGridDash(CGFloat a, CGFloat b) {
    IQGridDash ret;
    ret.a = a;
    ret.b = b;
    return ret;
}

@interface IQGanttRowView : UIView <IQGanttRowDelegate> {
@private
    NSCalendar* cal;
    IQGanttViewTimeWindow scaleWindow;
    NSCalendarUnit primaryLineUnits;
    NSCalendarUnit secondaryLineUnits;
    NSCalendarUnit tertaryLineUnits;
}

@property (nonatomic, retain) id<IQCalendarDataSource> dataSource;
@property (nonatomic, retain) UIColor* primaryGridColor;
@property (nonatomic, retain) UIColor* secondaryGridColor;
@property (nonatomic, retain) UIColor* tertaryGridColor;
@property (nonatomic) IQGridDash primaryGridDash;
@property (nonatomic) IQGridDash secondaryGridDash;
@property (nonatomic) IQGridDash tertaryGridDash;

// Overridable. Called to create and manage the subviews.
- (void) layoutItems:(IQGanttView*)gantt;
@end
