//
//  IQCalendarView.h
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

#import "IQScrollView.h"

typedef enum _IQCalendarSelectionMode {
    IQCalendarSelectionSingle,
    IQCalendarSelectionRange,
    IQCalendarSelectionRangeStart,
    IQCalendarSelectionRangeEnd,
    IQCalendarSelectionMulti
} IQCalendarSelectionMode;

@class IQCalendarArea;
@class IQCalendarRow;

@interface IQCalendarView : UIView {
    UIColor* tintColor, *selectionColor, *headerTextColor;
    UIView* header;
    
    NSCalendar* calendar;
    NSDate* currentDay, *displayDate;
    NSDate* selectionStart, *selectionEnd;
    IQCalendarArea* calendarArea;
    IQCalendarRow* rows[10];
}

#pragma mark Appearance

// Defaults to IQCalendarHeaderView. Should return a UIView subclass implementing IQCalendarHeaderDelegate.
+ (Class) headerViewClass;

@property (nonatomic, retain) UIColor* tintColor;
@property (nonatomic, retain) UIColor* selectionColor;
@property (nonatomic, retain) UIColor* headerTextColor;

@property (nonatomic, retain) NSCalendar* calendar;

#pragma mark Date navigation

// Sets the day which is shown in a different color. Default is the current date.
- (void)setCurrentDay:(NSDate*)date display:(BOOL)display animated:(BOOL)animated;

- (void)displayDay:(NSDate*)day animated:(BOOL)animated;

// Sets the selection interval
- (void) setSelectionIntervalFrom:(NSDate*)startDate to:(NSDate*)endDate animated:(BOOL)animated;

@property (nonatomic, retain) NSDate* currentDay;
@property (nonatomic, readonly) NSDate* firstDayInDisplayMonth;
@property (nonatomic, readonly) NSDate* lastDayInDisplayMonth;
@property (nonatomic, readonly) NSDate* firstDisplayedDay;
@property (nonatomic, readonly) NSDate* lastDisplayedDay;

@end


