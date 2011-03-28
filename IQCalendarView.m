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
#import <QuartzCore/QuartzCore.h>

@interface IQCalendarArea : UIView {
    CGGradientRef gradient;
    CGColorRef lightBorder;
    CGColorRef darkBorder;
}
- (void)setTintColor:(UIColor*)tintColor;
@end

@interface IQCalendarRow : UITableViewCell {
    UILabel* days[7];
}
@end

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
    if([header respondsToSelector:@selector(setCornerCalendarUnits:)]) {
        [(id)header setCornerCalendarUnits:0];
    }
    if([header respondsToSelector:@selector(setTitleCalendarUnits:)]) {
        [(id)header setTitleCalendarUnits:NSMonthCalendarUnit|NSYearCalendarUnit];
    }
    if([header respondsToSelector:@selector(setItemCalendarUnits:)]) {
        [(id)header setItemCalendarUnits:NSWeekdayCalendarUnit];
    }
    if([header respondsToSelector:@selector(setDisplayArrows:)]) {
        [(id)header setDisplayArrows:YES];
    }
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:header];
    CGFloat ht = r.size.height-44;
    calendarArea = [[IQCalendarArea alloc] initWithFrame:CGRectMake(0, 44, r.size.width, ht)];
    [self addSubview:calendarArea];
    [calendarArea setTintColor:tintColor];
    calendarArea.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    for(int i=0; i<10; i++) {
        rows[i] = [[IQCalendarRow alloc] initWithFrame:CGRectMake(0, 44+ht/5.0*i, r.size.width, ht/5.0)];
        [self addSubview:rows[i]];
    }
    [self displayDay:currentDay animated:NO];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect r = self.bounds;
    CGFloat ht = r.size.height-44;
    CGFloat y = 44;
    for(int i=0; i<10; i++) {
        CGFloat eht = round(ht/5.0);
        rows[i].frame = CGRectMake(0, y, r.size.width, eht);
        y += eht;
    }
}

#pragma mark Disposal

- (void)dealloc
{
    for(int i=0; i<10; i++) {
        [rows[i] release];
    }
    [calendarArea release];
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
    [calendarArea setTintColor:tintColor];
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
    if([header respondsToSelector:@selector(setItems:count:cornerWidth:startTime:titleOffset:animated:)]) {
        IQCalendarHeaderItem items[7];
        [(id)header setItems:items count:7 cornerWidth:0 startTime:self.firstDisplayedDay titleOffset:7*24*3600 animated:animated];
    }
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

@implementation IQCalendarArea
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
    }
    return self;
}

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (void)setTintColor:(UIColor*)tintColor
{
    CAGradientLayer* layer = (CAGradientLayer*)self.layer;
    CGColorRef tint = [tintColor CGColor];
    const CGFloat* cmpnts = CGColorGetComponents(tint);
    CGFloat colors[] = {
        cmpnts[0]+.1, cmpnts[1]+.1, cmpnts[2]+.1, 1,
        cmpnts[0], cmpnts[1], cmpnts[2], 1,
        cmpnts[0]-.12, cmpnts[1]-.12, cmpnts[2]-.12, 1,
    };
    layer.colors = [NSArray arrayWithObjects:(id)CGColorCreate(CGColorGetColorSpace([tintColor CGColor]), colors), (id)CGColorCreate(CGColorGetColorSpace([tintColor CGColor]), colors+4), nil];
}

@end

@implementation IQCalendarRow
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        self.contentMode = UIViewContentModeRedraw;
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect bnds = self.bounds;
    UIColor* lightBorder = [UIColor colorWithWhite:1 alpha:0.7];
    UIColor* darkBorder = [UIColor colorWithWhite:0 alpha:0.25];
    
    for(int i=0; i<7; i++) {
        CGFloat x = bnds.size.width / 7.0 * i;
        CGContextMoveToPoint(ctx, round(x)+.5, bnds.size.height-.5);
        CGContextAddLineToPoint(ctx, round(x)+.5, .5);
        CGContextAddLineToPoint(ctx, round(x+bnds.size.width / 7.0)-1, .5);
        CGContextSetStrokeColorWithColor(ctx, [lightBorder CGColor]);
        CGContextStrokePath(ctx);
        CGContextMoveToPoint(ctx, round(x+bnds.size.width / 7.0)-.5, .5);
        CGContextAddLineToPoint(ctx, round(x+bnds.size.width / 7.0)-.5, bnds.size.height-.5);
        CGContextAddLineToPoint(ctx, round(x)+.5, bnds.size.height-.5);
        CGContextSetStrokeColorWithColor(ctx, [darkBorder CGColor]);
        CGContextStrokePath(ctx);
    }
}
@end