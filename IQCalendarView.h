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
@class IQCalendarView;

@protocol IQCalendarContentDelegate <NSObject>
@required
- (void) calendarView:(IQCalendarView*)view layoutRow:(UIView*)rowView startDate:(NSDate*)startDate endDate:(NSDate*)endDate contentRect:(CGRect)contentRect;
@optional
- (void) calendarViewWillLayoutRows:(IQCalendarView*)view;
- (void) calendarViewDidLayoutRows:(IQCalendarView*)view;
@end

@interface IQCalendarView : UIControl {
    UIColor* tintColor, *selectionColor, *headerTextColor;
    UIView* header;
    BOOL needsDayRedisplay;
    NSCalendar* calendar;
    NSDate* currentDay, *displayDate;
    NSDate* selectionStart, *selectionEnd;
    NSDate* activeRangeStart, *activeRangeEnd;
    NSSet* selectedDays;
    CGPoint dragStart;
    BOOL inDrag;
    IQCalendarArea* calendarArea;
    IQCalendarRow* rows[9];
    CGFloat dayContentSize;
    NSDateFormatter* dayFormatter;
    CGSize headerShadowOffset;
}

#pragma mark Appearance

// Defaults to IQCalendarHeaderView. Should return a UIView subclass implementing IQCalendarHeaderDelegate.
+ (Class) headerViewClass;

@property (nonatomic, readonly) UIView* headerView;

@property (nonatomic, retain) UIColor* tintColor;
@property (nonatomic, retain) UIColor* selectionColor;
@property (nonatomic, retain) UIColor* headerTextColor;
@property (nonatomic, retain) UIColor* currentDayColor;
@property (nonatomic, retain) UIColor* textColor;
@property (nonatomic, retain) UIColor* selectedTextColor;

@property (nonatomic, retain) NSCalendar* calendar;
@property (nonatomic) BOOL showCurrentDay;

// The vertical space reserved below each day number label for extra content
@property (nonatomic) CGFloat dayContentSize;

@property (nonatomic) IQCalendarSelectionMode selectionMode;

@property (nonatomic, retain) UIFont* dayFont;

@property (nonatomic, readonly) NSDate* selectionStart;
@property (nonatomic, readonly) NSDate* selectionEnd;
@property (nonatomic, readonly) NSSet* selectedDays;

#pragma mark Application content

@property (nonatomic, retain) id<IQCalendarContentDelegate> contentDelegate;

#pragma mark User interaction

// Returns the date associated with the point at which the specified touch occurred.
- (NSDate*)dateFromTouch:(UITouch*)touch;
// Returns the date associated with a certain point relative to the calendar view
- (NSDate*)dateFromPoint:(CGPoint)point;

#pragma mark Date navigation

// Sets the day which is shown in a different color. Default is the current date.
- (void)setCurrentDay:(NSDate*)date display:(BOOL)display animated:(BOOL)animated;

- (void)displayDay:(NSDate*)day animated:(BOOL)animated;

- (void)displayNextMonth;
- (void)displayPreviousMonth;

// Sets the selection interval
- (void)setSelectionIntervalFrom:(NSDate*)startDate to:(NSDate*)endDate animated:(BOOL)animated;

- (void)setActiveSelectionRangeFrom:(NSDate*)startDate to:(NSDate*)endDate;

- (void)clearSelection;

- (void)setSelected:(BOOL)selected forDay:(NSDate*)day;
- (BOOL)isDaySelected:(NSDate*)day;

@property (nonatomic, retain) NSDate* currentDay;
@property (nonatomic, readonly) NSDate* firstDayInDisplayMonth;
@property (nonatomic, readonly) NSDate* lastDayInDisplayMonth;
@property (nonatomic, readonly) NSDate* firstDisplayedDay;
@property (nonatomic, readonly) NSDate* lastDisplayedDay;
@property (nonatomic, readonly) NSDate* firstDayInNextMonth;
@property (nonatomic, readonly) NSDate* lastDayInPreviousMonth;

- (NSDate*)dayForDate:(NSDate*)date;

@end


