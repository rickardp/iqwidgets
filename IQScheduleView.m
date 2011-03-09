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
- (void) ensureCapacity:(int)capacity;
@end

@interface IQscheduleViewDay : NSObject {
    int timeIndex;
    UILabel* headerView;
    IQScheduleDayView* contentView;
}
- (id) initWithHeaderView:(UILabel*)headerView contentView:(UIView*)contentView;
- (void) setTimeIndex:(int)ti left:(CGFloat)left width:(CGFloat)width;
@property (nonatomic, readonly) int timeIndex;
@property (nonatomic, readonly) UILabel* headerView;
@property (nonatomic, readonly) IQScheduleDayView* contentView;
@property (nonatomic, retain) NSString* title;
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
    [days release];
    [blocks release];
    [timeLabels release];
    [calendarArea release];
    [super dealloc];
}

#pragma mark Horizontal time scaling

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

#pragma mark Vertical time zooming

- (void) setZoom:(NSRange)zoom
{
    
}

- (NSRange) zoom
{
    // TODO: Implement zooming
    //CGPoint o = [calendarArea contentOffset];
    //CGSize s = [calendarArea contentSize];
    return NSMakeRange(0, 0);
}

#pragma mark Notifications

- (void) didMoveToSuperview
{
    if(cornerHeader == nil) {
        cornerHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 52, 24)];
        cornerHeader.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        cornerHeader.textAlignment = UITextAlignmentCenter;
        cornerHeader.contentMode = UIViewContentModeCenter;
        [self addSubview:cornerHeader];
        CGSize winSize = self.superview.bounds.size;
        CGRect bnds = CGRectMake(0, 24, winSize.width, winSize.height - 24);
        calendarArea = [[UIScrollView alloc] initWithFrame:bnds];
        calendarArea.contentSize = CGSizeMake(bnds.size.width, bnds.size.height * 2);
        calendarArea.contentOffset = CGPointMake(0, bnds.size.height * .5);
        calendarArea.multipleTouchEnabled = YES;
        [calendarArea flashScrollIndicators];
        [self addSubview:calendarArea];
        if(dirty) [self reload];
    }
}

#pragma mark Layouting (private)

- (void) ensureCapacity:(int)capacity
{
    if(days == nil) return;
    while([days count] < capacity) {
        UILabel* hdr = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 24)];
        hdr.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        hdr.textAlignment = UITextAlignmentCenter;
        hdr.contentMode = UIViewContentModeCenter;
        hdr.hidden = YES;
        [self addSubview:hdr];
        IQscheduleViewDay* day = [[[IQscheduleViewDay alloc] initWithHeaderView:hdr contentView:nil] autorelease];
        [days addObject:day];
    }
}

- (void) reload
{
    if(cornerHeader == nil) {
        dirty = YES;  
    } else {
        dirty = NO;
        cornerHeader.text = [cornerFormatter stringFromDate:startDate];
        [self ensureCapacity:numDays];
        
        NSDateComponents* dc = [[NSDateComponents alloc] init];
        
        int tMin = 0;
        int pivotPoint = -1;
        
        for(int i=0; i<numDays; i++) {
            dc.day = i;
            int t = (int)[[calendar dateByAddingComponents:dc toDate:startDate options:0] timeIntervalSinceReferenceDate];
            if(i == 0) tMin = t;
            int j = 0;
            for(IQScheduleViewDay* day in days) {
                if([day timeIndex] == t) {
                    pivotPoint = i;
                    break;
                }
                j++;
            }
            if(pivotPoint >= 0) {
                while(j > pivotPoint) {
                    IQScheduleViewDay* day = [days objectAtIndex:0];
                    [days addObject:day];
                    [days removeObjectAtIndex:0];
                    j--;
                }
                while(j < pivotPoint) {
                    IQScheduleViewDay* day = [days lastObject];
                    [days insertObject:day atIndex:0];
                    [days removeLastObject];
                    j++;
                }
            }
        }
        if(tMin == 0) return;
        CGRect bnds = self.bounds;
        CGFloat left = cornerHeader.bounds.size.width;
        CGFloat width = (bnds.size.width - left) / numDays;
        if(pivotPoint < 0) {
            // We have no view in common, just swap the views
            int i = 0;
            for(IQscheduleViewDay* day in days) {
                dc.day = i;
                int t = 0;
                if(i < numDays) {
                    NSDate* d = [calendar dateByAddingComponents:dc toDate:startDate options:0];
                    t = (int)[d timeIntervalSinceReferenceDate];
                    day.title = [headerFormatter stringFromDate:d];
                }
                [day setTimeIndex:t left:left width:width ];
                left += width;
                i++;
            }
        } else {
            
        }
    }
}

- (void) setupCalendarView
{
    days = [[NSMutableArray alloc] initWithCapacity:7];
    self.calendar = [NSCalendar currentCalendar];
    [self setWeekWithDate:nil workdays:YES];
    cornerFormatter = [[NSDateFormatter alloc] init];
    [cornerFormatter setDateFormat:@"YYYY"];
    headerFormatter = [[NSDateFormatter alloc] init];
    //[headerFormatter setDateStyle:NSDateFormatterMediumStyle];
    //[headerFormatter setTimeStyle:NSDateFormatterNoStyle];
    [headerFormatter setDateFormat:@"EEE MMM dd"];
}

@end

@implementation IQscheduleViewDay
@synthesize timeIndex;
@synthesize headerView;
@synthesize contentView;

- (id) initWithHeaderView:(UILabel*)h contentView:(UIView*)c
{
    if((self = [super init])) {
        headerView = [h retain];
        contentView = [c retain];
    }
    return self;
}

- (void) dealloc
{
    [headerView release];
    [contentView release];
    [super dealloc];
}

- (void) setTitle:(NSString *)title
{
    headerView.text = title;
}

- (NSString*) title
{
    return headerView.text;
}

- (void) setTimeIndex:(int)ti left:(CGFloat)left width:(CGFloat)width
{
    CGRect r = headerView.frame;
    r.origin.x = left;
    r.size.width = width;
    headerView.frame = r;
    if(ti <= 0) {
        headerView.hidden = YES;
        //contentView.hidden = YES;
    } else {
        headerView.hidden = NO;
    }
}

@end
