//
//  IQScheduleView.m
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

#import "IQScheduleView.h"


@interface IQScheduleView (PrivateMethods)
- (void) reload;
- (void) setupCalendarView;
@end

@implementation IQScheduleView

@synthesize dataSource;
@synthesize calendar;
@synthesize numberOfDays = numDays;

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

#pragma mark Disposal

- (void)dealloc
{
    [startDate release];
    [calendar release];
    [cornerFormatter release];
    [cornerHeader release];
    for(int i=0; i<7; i++) {
        [dayHeaders[i] release];
        [days[i] release];
    }
    [blocks release];
    [timeLabels release];
    [calendarArea release];
    [super dealloc];
}

#pragma mark Time scaling

- (NSDate*) startDate
{
    return startDate;
}

- (NSDate*) endDate
{
    NSDateComponents* cmpnts = [NSDateComponents new];
    [cmpnts setDay:numDays-1];
    return [calendar dateByAddingComponents:cmpnts toDate:startDate options:0];
}

- (void) setStartDate:(NSDate*)s numberOfDays:(int)n
{
    [startDate release];
    if(s == nil) s = [NSDate date];
    NSDateComponents* dc = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:s];
    startDate = [[calendar dateFromComponents:dc] retain];
    
    if(n<1) n = 1;
    if(n>7) n = 7;
    numDays = n;
    [self reload];
}
- (void) setStartDate:(NSDate*)s endDate:(NSDate*)e
{
    if(s == nil || e == nil) {
        [NSException raise:@"InvalidArgument" format:@"setStartDate:endDate: cannot take nil arguments"];
    }
    NSDateComponents* dc = [calendar components:NSDayCalendarUnit|NSHourCalendarUnit fromDate:s toDate:e options:0];
    if(dc.day <= 0) {
        [self setStartDate:s numberOfDays:1];
    } else {
        int d = dc.day;
        if(dc.hour > 0 || dc.minute > 0 || dc.second > 0) d++;
        [self setStartDate:s numberOfDays:d];
    }
}

- (void) setWeekWithDate:(NSDate*)s workdays:(BOOL)workdays
{
    if(s == nil) s = [NSDate date];
    NSDateComponents* dc = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSWeekdayCalendarUnit fromDate:s];
    int diff, num;
    if(workdays) {
        diff = 2;
        num = 5;
    } else {
        diff = calendar.firstWeekday;
        num = 7;
    }
    dc.day -= dc.weekday-diff;
    dc.weekday = diff;
    [self setStartDate:[calendar dateFromComponents:dc] numberOfDays:num];
}

#pragma mark Private methods

- (void) didMoveToWindow
{
    cornerHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 52, 24)];
    cornerHeader.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    cornerHeader.textAlignment = UITextAlignmentCenter;
    cornerHeader.contentMode = UIViewContentModeCenter;
    [self addSubview:cornerHeader];
    float x = 52, w = (self.bounds.size.width - 52)/kIQScheduleViewMaxDays;
    for(int i=0; i<kIQScheduleViewMaxDays; i++) {
        dayHeaders[i] = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, 24)];
        dayHeaders[i].autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        dayHeaders[i].textAlignment = UITextAlignmentCenter;
        dayHeaders[i].contentMode = UIViewContentModeCenter;
        [self addSubview:dayHeaders[i]];
        x += w;
    }
    if(dirty) [self reload];
}


- (void) reload
{
    if(cornerHeader == nil) {
        dirty = YES;  
    } else {
        dirty = NO;
        cornerHeader.text = [cornerFormatter stringFromDate:startDate];
        NSDateComponents* dc = [[NSDateComponents alloc] init];
        BOOL taken[kIQScheduleViewMaxDays];
        int newIndices[kIQScheduleViewMaxDays];
        for(int i=0; i<kIQScheduleViewMaxDays; i++) {
            taken[i] = NO;
            if(i >= numDays) newIndices[i] = 0;
            else {
                dc.day = i;
                NSDate* d = [calendar dateByAddingComponents:dc toDate:startDate options:0];
                newIndices[i] = (int)[d timeIntervalSinceReferenceDate];
            }
        }
        int startIndex = -1, startOldIndex = -1;
        for(int i=0; i<kIQScheduleViewMaxDays; i++) {
            for(int j=0; j<7; j++) {
                if(indices[j] == newIndices[i]) {
                    startIndex = i;
                    startOldIndex = j;
                    break;
                }
            }
        }
    }
}

- (void) setupCalendarView
{
    self.calendar = [NSCalendar currentCalendar];
    [self setWeekWithDate:nil workdays:YES];
    cornerFormatter = [[NSDateFormatter alloc] init];
    [cornerFormatter setDateFormat:@"YYYY"];
}

@end
