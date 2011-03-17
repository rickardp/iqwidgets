//
//  IQScheduleView.h
//  IQWidgets for iOS
//
//  Copyright 2011 EvolvIQ
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

@protocol IQCalendarDataSource;

@class IQScheduleBlockView;
@class IQScheduleViewDay;
@class IQScheduleView;


typedef UIView* (^IQScheduleBlockViewCreationCallback)(IQScheduleView* parent, id item, CGRect frame);

@interface IQScheduleView : UIView {
    id<IQCalendarDataSource> dataSource;
    NSDate* startDate;
    int numDays;
    UILabel* cornerHeader;
    UIScrollView* calendarArea;
    NSMutableArray* days;
    NSMutableSet* timeLabels;
    UIView* nowTimeIndicator;
    NSCalendar* calendar;
    BOOL dirty;
    NSDateFormatter* cornerFormatter, *headerFormatter, *tightHeaderFormatter;
    IQScheduleBlockViewCreationCallback createBlock;
    NSSet* items;
}

@property (nonatomic, retain) id<IQCalendarDataSource> dataSource;
@property (nonatomic, retain) NSCalendar* calendar;

@property (nonatomic, readonly) NSDate* startDate;
@property (nonatomic, readonly) NSDate* endDate;
@property (nonatomic, readonly) int numberOfDays;
@property (nonatomic) NSRange zoom;

@property (nonatomic, retain) UIColor* tintColor;
@property (nonatomic, retain) UIColor* darkLineColor;
@property (nonatomic, retain) UIColor* lightLineColor;

- (void) setStartDate:(NSDate*)startDate numberOfDays:(int)numberOfDays;

/**
 Sets the scale to show the specified time interval, including the whole days
 of both endpoints.
 */
- (void) setStartDate:(NSDate*)startDate endDate:(NSDate*)endDate;

- (void) setWeekWithDate:(NSDate*)dayInWeek workdays:(BOOL)workdays;

- (void) reloadData;

@end

// This category uses blocks for defining a call-back interface. This
// option performs better with large data sets and allows for more
// customization than the simple interface.

@interface IQScheduleView (CallbackInterface)
- (void) setBlockCreationCallback:(IQScheduleBlockViewCreationCallback)callback;
@end

@interface IQScheduleDayView : UIView {
@private
}
@property (nonatomic, retain) UIColor* tintColor;
@property (nonatomic, retain) UIColor* darkLineColor;
@property (nonatomic, retain) UIColor* lightLineColor;
@end

@interface IQScheduleBlockView : UIView {
@private
    UILabel* textLabel;
}

@property (nonatomic, readonly) UILabel* textLabel;
@property (nonatomic, retain) NSString* text;
@end
