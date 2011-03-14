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
@protocol IQGanttRowDelegate
@end
@protocol IQCalendarDataSource;

typedef struct _IQGanttViewTimeWindow {
    NSTimeInterval windowStart, windowEnd;
    NSTimeInterval viewStart, viewEnd;
} IQGanttViewTimeWindow;

@interface IQGanttView : UIView<UIScrollViewDelegate> {
@private
    UIView<IQGanttHeaderDelegate>* headerView;
    UIScrollView* contentView;
    UIView* contentPanel;
    NSMutableArray* rows;
    NSMutableArray* rowViews;
    UIColor* backgroundColor;
    IQGanttViewTimeWindow scaleWindow;
}

@property (nonatomic, retain) UIView<IQGanttHeaderDelegate>* headerView;
@property (nonatomic, getter=isDirectionalLockEnabled) BOOL directionalLockEnabled;
@property (nonatomic, retain) UIColor* backgroundColor;
@property (nonatomic) IQGanttViewTimeWindow scaleWindow;

- (void)removeAllRows;
- (void)addRow:(id<IQCalendarDataSource>)row;

@end


@protocol IQGanttHeaderDelegate
@optional
- (void)ganttView:(IQGanttView*)view didUpdateWindow:(IQGanttViewTimeWindow)win;
@end

@interface IQGanttHeaderView : UIView <IQGanttHeaderDelegate> {
@private
    IQGanttViewTimeWindow scaleWindow;
}
@end

@interface IQGanttRowView : UIView <IQGanttRowDelegate> {
@private
}
@end
