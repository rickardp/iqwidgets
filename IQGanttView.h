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

typedef struct _IQGanttViewTimeWindow {
    NSTimeInterval windowStart, windowEnd;
    NSTimeInterval viewStart, viewSize;
} IQGanttViewTimeWindow;

@interface IQGanttView : IQScrollView {
@private
    NSMutableArray* rows;
    NSMutableArray* rowViews;
    IQGanttViewTimeWindow scaleWindow;
    NSCalendarUnit displayCalendarUnits;
}

@property (nonatomic) IQGanttViewTimeWindow scaleWindow;
@property (nonatomic) NSCalendarUnit displayCalendarUnits;

- (void)removeAllRows;
- (void)addRow:(id<IQCalendarDataSource>)row;

// Overridable methods. Subclass IQGanttView and override the below methods
// to achieve further customization of the user interface.
- (UIView*) createCornerViewWithFrame:(CGRect)frame; // default implementation returns nil
- (UIView<IQGanttHeaderDelegate>*) createTimeHeaderViewWithFrame:(CGRect)frame; // default implementation returns a IQGanttHeaderView
- (UIView*) createRowHeaderViewWithFrame:(CGRect)frame; // default implementation returns nil

@end


@protocol IQGanttHeaderDelegate
@optional
- (void)ganttView:(IQGanttView*)view didScaleWindow:(IQGanttViewTimeWindow)win;
- (void)ganttView:(IQGanttView*)view didMoveWindow:(IQGanttViewTimeWindow)win;
- (void)ganttView:(IQGanttView*)view shouldDisplayCalendarUnits:(NSCalendarUnit) displayCalendarUnits;
@end

@protocol IQGanttRowDelegate
@optional
@end

@interface IQGanttHeaderView : UIView <IQGanttHeaderDelegate> {
@private
    IQGanttViewTimeWindow scaleWindow;
    UIColor* tintColor;
    CGGradientRef grad;
    CGColorRef border;
    NSCalendarUnit displayCalendarUnits;
    UILabel* firstLineLabel;
    UILabel* secondLineLabel;
    CGFloat offset;
}

@property (nonatomic, retain) UIColor* tintColor;
@end

@interface IQGanttRowView : UIView <IQGanttRowDelegate> {
@private
}
@end
