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

@class CAGradientLayer;
@class IQScheduleBlockView;
@class IQScheduleViewDay;
@class IQScheduleView;

#import "IQScrollView.h"

/**
 The IQScheduleView is similar to the day/week calendar view in iCal
 */
@interface IQScheduleView : IQScrollView

@property (nonatomic, retain) id<IQCalendarDataSource> dataSource;
@property (nonatomic, retain) NSCalendar* calendar;

@property (nonatomic, readonly) NSDate* startDate;
@property (nonatomic, readonly) NSDate* endDate;
@property (nonatomic, readonly) int numberOfDays;
@property (nonatomic) NSRange zoom;

@property (nonatomic, retain) UIColor* tintColor;
@property (nonatomic, retain) UIColor* headerTextColor;
@property (nonatomic, retain) UIColor* darkLineColor;
@property (nonatomic, retain) UIColor* lightLineColor;

- (void) setStartDate:(NSDate*)startDate numberOfDays:(int)numberOfDays animated:(BOOL)animated;

/**
 Sets the scale to show the specified time interval, including the whole days
 of both endpoints.
 */
- (void) setStartDate:(NSDate*)startDate endDate:(NSDate*)endDate animated:(BOOL)animated;

- (void) setWeekWithDate:(NSDate*)dayInWeek workdays:(BOOL)workdays animated:(BOOL)animated;

- (void) reloadData;

#pragma mark - Overridable methods

// Defaults to IQCalendarHeaderView. Should return a UIView subclass implementing IQCalendarHeaderDelegate.
+ (Class) headerViewClass;

// Override this method to define a custom view creation. Detfault is to create a themeable simple view.
- (UIView*) createViewForActivityWithFrame:(CGRect)frame text:(NSString*)text;

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
