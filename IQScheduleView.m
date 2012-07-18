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
#import "IQCalendarDataSource.h"
#import "IQCalendarHeaderView.h"
#import <QuartzCore/QuartzCore.h>

const CGFloat kDayViewPadding = 0.0;

@interface IQScheduleView (PrivateMethods)
- (void) reloadAnimated:(BOOL)animated;
- (void) setupCalendarView;
- (void) ensureCapacity:(int)capacity;
- (UIView*) createViewForBlockItem:(id)item;
@end

@interface IQScheduleViewDay : NSObject {
    int timeIndex;
    NSTimeInterval dayOffset;
    NSTimeInterval dayLength;
    UILabel* headerView;
    NSMutableSet* blocks;
    IQScheduleDayView* contentView;
}
- (id) initWithHeaderView:(UILabel*)headerView contentView:(UIView*)contentView;
- (void) setTimeIndex:(int)ti left:(CGFloat)left width:(CGFloat)width;
- (void) reloadDataWithSource:(IQScheduleView*)dataSource;
@property (nonatomic, readonly) int timeIndex;
@property (nonatomic, readonly) UILabel* headerView;
@property (nonatomic, readonly) IQScheduleDayView* contentView;
@property (nonatomic, retain) NSString* title;
@property (nonatomic) NSTimeInterval dayOffset, dayLength;
@end

@implementation IQScheduleView

@synthesize dataSource;
@synthesize calendar;
@synthesize numberOfDays = numDays;
@synthesize tintColor;
@synthesize darkLineColor;
@synthesize lightLineColor;

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
    self.darkLineColor = nil;
    self.lightLineColor = nil;
    self.tintColor = nil;
    self.headerTextColor = nil;
    for(int i=0; i<24; i++) [hours[i] release];
    [startDate release];
    [calendar release];
    [cornerFormatter release];
    [headerFormatter release];
    [tightHeaderFormatter release];
    [days release];
    [super dealloc];
}

#pragma mark IQScrollView overrides


#pragma mark Properties


- (void)setTintColor:(UIColor *)tc
{
    if([self.columnHeaderView respondsToSelector:@selector(setTintColor:)]) {
        [(id)self.columnHeaderView setTintColor:tc];
    }
    [tintColor release];
    tintColor = [tc retain];
}

- (UIColor*)tintColor
{
    return tintColor;
}

- (void)setHeaderTextColor:(UIColor *)tc
{
    if([self.columnHeaderView respondsToSelector:@selector(setTextColor:)]) {
        [(id)self.columnHeaderView setTintColor:tc];
    }
    [headerTextColor release];
    headerTextColor = [tc retain];
}

- (UIColor*)headerTextColor
{
    return headerTextColor;
}

#pragma mark Horizontal time scaling

- (NSDate*) startDate
{
    return startDate;
}

- (NSDate*) endDate
{
    NSDateComponents* cmpnts = [[NSDateComponents new] autorelease];
    [cmpnts setDay:numDays-1];
    return [calendar dateByAddingComponents:cmpnts toDate:startDate options:0];
}

- (void) setStartDate:(NSDate*)s numberOfDays:(int)n animated:(BOOL)animated
{
    [startDate release];
    if(s == nil) s = [NSDate date];
    NSDateComponents* dc = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:s];
    startDate = [[calendar dateFromComponents:dc] retain];
    
    if(n<1) n = 1;
    if(n>7) n = 7;
    numDays = n;
    [self reloadAnimated:animated];
}
- (void) setStartDate:(NSDate*)s endDate:(NSDate*)e animated:(BOOL)animated
{
    if(s == nil || e == nil) {
        [NSException raise:@"InvalidArgument" format:@"setStartDate:endDate: cannot take nil arguments"];
    }
    NSDateComponents* dc = [calendar components:NSDayCalendarUnit|NSHourCalendarUnit fromDate:s toDate:e options:0];
    if(dc.day <= 0) {
        [self setStartDate:s numberOfDays:1 animated:animated];
    } else {
        int d = dc.day;
        if(dc.hour > 0 || dc.minute > 0 || dc.second > 0) d++;
        [self setStartDate:s numberOfDays:d animated:animated];
    }
}

- (void) setWeekWithDate:(NSDate*)s workdays:(BOOL)workdays animated:(BOOL)animated
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
    [self setStartDate:[calendar dateFromComponents:dc] numberOfDays:num animated:animated];
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

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGRect bnds = self.bounds;
    // Make sure an hour has an integral height
    CGFloat height = bnds.size.height * 2;
    height = (height - 2 * kDayViewPadding) / 24.0f;
    height = round(height) * 24 + 2 * kDayViewPadding;
    self.contentSize = CGSizeMake(bnds.size.width, height);
    
    CGFloat ht = self.contentSize.height - 2 * kDayViewPadding;
    for(int i=1; i<= 23; i++) {
        hours[i].frame = CGRectMake(0, 12+kDayViewPadding+i*ht/24.0f, 50, 20);
    }
    for(IQScheduleViewDay* day in days) {
        CGRect r = day.contentView.frame;
        if(r.size.height != height) {
            r.size.height = height;
            day.contentView.frame = r;
        }
    }
}

- (void)didMoveToSuperview
{
    [self layoutSubviews];
    if(dirty) [self reloadAnimated:NO];
    self.contentOffset = CGPointMake(0, self.bounds.size.height * .5);
    [self flashScrollbarIndicators];
}

#pragma mark Layouting (private)

- (void) recreateFromScratch
{
    dirty = TRUE;
    for(IQScheduleViewDay* day in days) {
        [day.contentView removeFromSuperview];
    }
}

- (void) ensureCapacity:(int)capacity
{
    if(days == nil) return;
    while([days count] < capacity) {
        UILabel* hdr = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 24)] autorelease];
        hdr.font = [UIFont systemFontOfSize:14];
        hdr.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        hdr.textAlignment = UITextAlignmentCenter;
        hdr.contentMode = UIViewContentModeCenter;
        hdr.backgroundColor = [UIColor clearColor];
        hdr.shadowColor = [UIColor whiteColor];
        hdr.shadowOffset = CGSizeMake(0, 1);
        hdr.hidden = YES;
        [self.columnHeaderView addSubview:hdr];
        IQScheduleDayView* dayContent = [[[IQScheduleDayView alloc] initWithFrame:CGRectMake(0, 0, 120, 100)] autorelease];
        dayContent.opaque = YES;
        dayContent.clipsToBounds = YES;
        dayContent.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        dayContent.backgroundColor = self.backgroundColor;
        dayContent.darkLineColor = self.darkLineColor;
        dayContent.lightLineColor = self.lightLineColor;
        dayContent.tintColor = self.tintColor;
        IQScheduleViewDay* day = [[[IQScheduleViewDay alloc] initWithHeaderView:hdr contentView:dayContent] autorelease];
        [self addSubview:dayContent];
        [days addObject:day];
    }
}

- (void) reloadData
{
    for(IQScheduleViewDay* day in days) {
        if([day timeIndex] != 0) {
            [day reloadDataWithSource:self];
        }
    }
}

- (void) reloadAnimated:(BOOL)animated
{
    if(self.superview == nil) {
        dirty = YES;
        return;
    }
    dirty = NO;
    ((UILabel*)self.cornerView).text = [cornerFormatter stringFromDate:startDate];
    [self ensureCapacity:numDays];
    
    NSDateComponents* dc = [[NSDateComponents new] autorelease];
    
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
    CGFloat left = 60;
    CGFloat width = (bnds.size.width - left) / numDays;
    NSLog(@"Pivot point: %d", pivotPoint);
    if(pivotPoint < 0||YES) {
        // We have no view in common, just swap the views
        int i = 0;
        if(animated) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self cache:YES];
            [UIView setAnimationsEnabled:NO]; 
            [UIView setAnimationDuration:0.5];
        }
        for(IQScheduleViewDay* day in days) {
            dc.day = i;
            int t = 0;
            if(i < numDays) {
                NSDate* d = [calendar dateByAddingComponents:dc toDate:startDate options:0];
                NSTimeInterval tt = [d timeIntervalSinceReferenceDate];
                dc.day = i+1;
                NSTimeInterval t2 = [[calendar dateByAddingComponents:dc toDate:startDate options:0] timeIntervalSinceReferenceDate];
                t = (int)tt;
                day.title = [((width < 100)?tightHeaderFormatter:headerFormatter) stringFromDate:d];
                day.dayOffset = tt - t;
                day.dayLength = t2 - tt;
            }
            [day setTimeIndex:t left:left width:width];
            left += width;
            i++;
        }
        [self layoutSubviews];
        if(animated) {
            [UIView commitAnimations];
        }
        for(IQScheduleViewDay* day in days) {
            [day reloadDataWithSource:self];
        }
    } else {
        
    }
}

- (UIView*) createViewForBlockItem:(id)item withFrame:(CGRect)frame
{
    return createBlock(self, item, frame);
}

+ (Class) headerViewClass
{
    return [IQCalendarHeaderView class];
}

- (void) setupCalendarView
{
    self.alwaysBounceHorizontal = NO;
    createBlock = Block_copy(^(IQScheduleView* parent, id item, CGRect frame) {
        IQScheduleBlockView* view = [[IQScheduleBlockView alloc] initWithFrame:frame];
        if([dataSource respondsToSelector:@selector(textForItem:)]) {
            view.text = [dataSource textForItem:item];
        }
        return [view autorelease];
    });
    self.backgroundColor = [UIColor whiteColor];
    self.darkLineColor = [UIColor lightGrayColor];
    self.lightLineColor = [UIColor colorWithWhite:0.8 alpha:1];
    self.tintColor = [UIColor colorWithRed:204/255.0 green:204/255.0 blue:209/255.0 alpha:1];
    self.headerTextColor = [UIColor colorWithRed:.15 green:.1 blue:0 alpha:1];
    days = [[NSMutableArray alloc] initWithCapacity:7];
    self.calendar = [NSCalendar currentCalendar];
    [self setWeekWithDate:nil workdays:YES animated:NO];
    cornerFormatter = [[NSDateFormatter alloc] init];
    [cornerFormatter setDateFormat:@"YYYY"];
    headerFormatter = [[NSDateFormatter alloc] init];
    //[headerFormatter setDateStyle:NSDateFormatterMediumStyle];
    //[headerFormatter setTimeStyle:NSDateFormatterNoStyle];
    [headerFormatter setDateFormat:@"EEE MMM dd"];
    tightHeaderFormatter = [[NSDateFormatter alloc] init];
    //[headerFormatter setDateStyle:NSDateFormatterMediumStyle];
    //[headerFormatter setTimeStyle:NSDateFormatterNoStyle];
    [tightHeaderFormatter setDateFormat:@"EEE"];
    
    UIView* hdr = (UIView*)[[[[self class] headerViewClass] alloc] initWithFrame:CGRectMake(0, 0, 100, 24)];
    if([hdr respondsToSelector:@selector(setTintColor:)]) {
        [(id)hdr setTintColor:tintColor];
    }
    self.columnHeaderView = hdr;
    
    
    for(int i=1; i<= 23; i++) {
        hours[i] = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 46, 20)];
        hours[i].text = [NSString stringWithFormat:@"%02d.00", i];
        hours[i].textAlignment = UITextAlignmentRight;
        hours[i].font = [UIFont systemFontOfSize:12];
        hours[i].textColor = [UIColor grayColor];
        hours[i].contentMode = UIViewContentModeCenter;
        hours[i].autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        hours[i].backgroundColor = self.backgroundColor;
        [self addSubview:hours[i]];
    }
}

@end

@implementation IQScheduleViewDay
@synthesize timeIndex;
@synthesize headerView;
@synthesize contentView;
@synthesize dayOffset, dayLength;

- (id) initWithHeaderView:(UILabel*)h contentView:(UIView*)c
{
    if((self = [super init])) {
        headerView = [h retain];
        contentView = [c retain];
        blocks = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [blocks release];
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
    left = floor(left);
    width = ceil(width);
    r.origin.x = left;
    r.size.width = ceil(width);
    headerView.frame = r;
    r = contentView.frame;
    r.origin.x = left;
    if(r.size.width != ceil(width)) {
        r.size.width = ceil(width);
        [contentView setNeedsDisplay];
    }
    //NSLog(@"Setting frm %d to %f", ti, r.size.height);
    contentView.frame = r;
    if(ti <= 0) {
        headerView.hidden = YES;
        contentView.hidden = YES;
    } else {
        headerView.hidden = NO;
        contentView.hidden = NO;
    }
    timeIndex = ti;
}

- (void) reloadDataWithSource:(IQScheduleView*)dataSource
{
    for(UIView* view in blocks) {
        [view removeFromSuperview];
    }
    [blocks removeAllObjects];
    
    if(dataSource == nil) return;
    CGRect bounds = contentView.bounds;
    CGFloat ht = bounds.size.height - 2 * kDayViewPadding;
    [[dataSource dataSource] enumerateEntriesUsing:^(id item, NSTimeInterval startDate, NSTimeInterval endDate) {
        CGFloat y1 = kDayViewPadding - 1 + bounds.origin.y + round(ht * (startDate - timeIndex) / dayLength);
        CGFloat y2 = kDayViewPadding + bounds.origin.y + round(ht * (endDate - timeIndex) / dayLength);
        CGRect frame = CGRectMake(bounds.origin.x, y1, bounds.size.width, y2 - y1);
        if(frame.size.height < 10) frame.size.height = 10;
        UIView* view = [dataSource createViewForBlockItem:item withFrame:frame];
        if(view != nil) {
            [blocks addObject:view];
            [contentView addSubview:view];
            view.backgroundColor = [UIColor redColor];
        }
    } from:timeIndex+dayOffset to:timeIndex+dayOffset+dayLength];
}

@end

@implementation IQScheduleView (CallbackInterface)
- (void) setBlockCreationCallback:(IQScheduleBlockViewCreationCallback)callback
{
    Block_release(createBlock);
}
@end
@implementation IQScheduleDayView
@synthesize darkLineColor, lightLineColor, tintColor;

- (void) dealloc
{
    self.darkLineColor = nil;
    self.lightLineColor = nil;
    self.tintColor = nil;
}

- (void)drawRect:(CGRect)rect
{
    CGRect bnds = self.bounds;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetShouldAntialias(ctx, NO);
    CGContextSetFillColorWithColor(ctx, [self.backgroundColor CGColor]);
    CGContextFillRect(ctx, rect);
    CGFloat hourSize = (bnds.size.height - 2 * kDayViewPadding) / 24.0f;
    CGContextAddLines(ctx, (CGPoint[]){CGPointMake(0, kDayViewPadding), CGPointMake(0, (int)bnds.size.height-kDayViewPadding)}, 2);
    for(int i=0; i<=24; i++) {
        int y = (int)(i * hourSize + kDayViewPadding);
        CGContextMoveToPoint(ctx, 0, y);
        CGContextAddLineToPoint(ctx, bnds.size.width, y);
        
    }
    CGContextSetStrokeColorWithColor(ctx, [self.lightLineColor CGColor]);
    CGContextStrokePath(ctx);
    for(int i=0; i<24; i++) {
        int y = (int)((i+.5f) * hourSize + kDayViewPadding);
        CGContextMoveToPoint(ctx, 0, y);
        CGContextAddLineToPoint(ctx, bnds.size.width, y);
        
    }
    CGContextSetStrokeColorWithColor(ctx, [self.lightLineColor CGColor]);
    CGContextSaveGState(ctx);
    CGContextSetLineDash(ctx, 0, (CGFloat[]){1,1}, 2);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
    //CGContextMoveToPoint(ctx, 0, 20);
    //CGContextAddLineToPoint(ctx, 100, 20);
}

@end

@implementation IQScheduleBlockView
@synthesize textLabel;
- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        self.layer.cornerRadius = 8.0f;
        self.layer.borderWidth = 1.0;
        self.backgroundColor = [UIColor blueColor];
        CGRect b = self.bounds;
        b.origin.x = 5;
        b.origin.y = 5;
        b.size.width -= 2 * b.origin.x;
        b.size.height -= 2 * b.origin.y;
        textLabel = [[UILabel alloc] initWithFrame:b];
        textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textLabel.opaque = NO;
        textLabel.backgroundColor = [UIColor clearColor];
        textLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:textLabel];
    }
    return self;
}

- (void) setBackgroundColor:(UIColor *)backgroundColor
{
    self.layer.borderColor = [[backgroundColor colorWithAlphaComponent:0.5] CGColor];
    const CGFloat* ft = CGColorGetComponents([backgroundColor CGColor]);
    //textLabel.textColor = backgroundColor;
    [super setBackgroundColor:[UIColor colorWithRed:ft[0]*.5+.5 green:ft[1]*.5+.5 blue:ft[2]*.5+.5 alpha:.75]];
    textLabel.textColor = [UIColor colorWithRed:ft[0]*.75 green:ft[1]*.75 blue:ft[2]*.75 alpha:1];
}

- (void) setText:(NSString *)text
{
    textLabel.text = text;
}

- (NSString*) text
{
    return textLabel.text;
}
@end


