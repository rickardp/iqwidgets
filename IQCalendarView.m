//
//  IQCalendarView.m
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

#import "IQCalendarView.h"
#import "IQCalendarHeaderView.h"


@interface IQCalendarView (PrivateMethods)
- (void) setupCalendarView;
@end

@implementation IQCalendarView
@synthesize tintColor, headerTextColor, selectionColor;
@synthesize calendar, currentDay;

#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupCalendarView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupCalendarView];
    }
    return self;
}

+ (Class) headerViewClass
{
    return [IQCalendarHeaderView class];
}

- (void) setupCalendarView
{
    CGRect r = self.bounds;
    currentDay = [[NSDate date] retain];
    self.calendar = [NSCalendar currentCalendar];
    self.tintColor = [UIColor colorWithRed:204/255.0 green:204/255.0 blue:209/255.0 alpha:1];
    self.headerTextColor = [UIColor colorWithRed:.15 green:.1 blue:0 alpha:1];
    header = (UIView*)[[[[self class] headerViewClass] alloc] initWithFrame:CGRectMake(0, 0, r.size.width, 44)];
    if([header respondsToSelector:@selector(setTintColor:)]) {
        [(id)header setTintColor:tintColor];
    }
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:header];
}

#pragma mark Disposal

- (void)dealloc
{
    [calendar release];
    [header release];
    [super dealloc];
}

#pragma mark Properties

- (void)setTintColor:(UIColor *)tc
{
    if([header respondsToSelector:@selector(setTintColor:)]) {
        [(id)header setTintColor:tc];
    }
    [tintColor release];
    tintColor = [tc retain];
}

- (void)setHeaderTextColor:(UIColor *)tc
{
    if([header respondsToSelector:@selector(setTextColor::)]) {
        [(id)header setTextColor:tc];
    }
    [headerTextColor release];
    headerTextColor = [tc retain];
}

#pragma mark Date navigation


- (void)setCurrentDay:(NSDate*)date display:(BOOL)display animated:(BOOL)animated
{
    [currentDay release];
    currentDay = [date retain];
}

- (void)setCurrentDay:(NSDate *)date
{
    [self setCurrentDay:date display:YES animated:YES];
}

- (void)displayDay:(NSDate*)day animated:(BOOL)animated
{
    [displayDate release];
    displayDate = [day retain];
}

- (void)setSelectionIntervalFrom:(NSDate*)startDate to:(NSDate*)endDate animated:(BOOL)animated
{
    
}

-(NSDate*)firstDayInDisplayMonth
{
    NSDate* date = displayDate;
    if(!date) date = currentDay;
    if(!date) date = [NSDate date];
    NSDateComponents* cmpnts = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:date];
    cmpnts.day = 1;
    return [calendar dateFromComponents:cmpnts];
}

-(NSDate*)lastDayInDisplayMonth
{
    NSDate* date = displayDate;
    if(!date) date = currentDay;
    if(!date) date = [NSDate date];
    NSDateComponents* cmpnts = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:date];
    cmpnts.day = 0;
    cmpnts.month += 1;
    return [calendar dateFromComponents:cmpnts];
}

-(NSDate*)firstDisplayedDay
{
    NSDateComponents* cmpnts = [calendar components:NSWeekdayCalendarUnit|NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self.firstDayInDisplayMonth];
    cmpnts.day += ([calendar firstWeekday] - cmpnts.weekday);
    return [calendar dateFromComponents:cmpnts];
}

-(NSDate*)lastDisplayedDay
{
    NSDateComponents* cmpnts = [calendar components:NSWeekdayCalendarUnit|NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self.lastDayInDisplayMonth];
    cmpnts.day += ([calendar firstWeekday] - cmpnts.weekday+7);
    return [calendar dateFromComponents:cmpnts];
}
@end



