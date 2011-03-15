//
//  IQGanttView.m
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

#import "IQGanttView.h"
#import <QuartzCore/QuartzCore.h>
#import "IQCalendarDataSource.h"

@interface IQGanttView (PrivateMethods)
- (void) setupGanttView;
- (void) layoutOnPropertyChange:(BOOL)didChangeZoom;
@end

@implementation IQGanttView

#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupGanttView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupGanttView];
    }
    return self;
}

- (void)setupGanttView
{
    displayCalendarUnits = NSDayCalendarUnit | NSWeekCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    NSDateComponents* cmpnts = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    cmpnts.day -= 3;
    scaleWindow.viewStart = [[[NSCalendar currentCalendar] dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
    cmpnts.day += 7;
    scaleWindow.viewSize = [[[NSCalendar currentCalendar] dateFromComponents:cmpnts] timeIntervalSinceReferenceDate] - scaleWindow.viewStart;
    cmpnts.month = 1;
    scaleWindow.windowStart = [[[NSCalendar currentCalendar] dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
    cmpnts.year += 1;
    scaleWindow.windowEnd = [[[NSCalendar currentCalendar] dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
    NSLog(@"Date is %@ - %@", [NSDate dateWithTimeIntervalSinceReferenceDate:scaleWindow.viewStart], [NSDate dateWithTimeIntervalSinceReferenceDate:scaleWindow.viewSize+scaleWindow.viewStart]);
    NSLog(@"Date is %@ - %@", [NSDate dateWithTimeIntervalSinceReferenceDate:scaleWindow.windowStart], [NSDate dateWithTimeIntervalSinceReferenceDate:scaleWindow.windowEnd]);
}

#pragma mark Layout


- (void) didMoveToWindow
{
    UIView* view = [[self createTimeHeaderViewWithFrame:CGRectMake(0, 0, self.bounds.size.width, 44)] autorelease];
    if(view != nil) {
        if([view respondsToSelector:@selector(ganttView:shouldDisplayCalendarUnits:)]) {
            [(id<IQGanttHeaderDelegate>)view ganttView:self shouldDisplayCalendarUnits:displayCalendarUnits];
        }
        self.columnHeaderView = view;
    }
    view = [[self createRowHeaderViewWithFrame:CGRectMake(0, 0, 100, self.bounds.size.height)] autorelease];
    if(view != nil) self.rowHeaderView = view;
    view = [[self createTimeHeaderViewWithFrame:CGRectMake(0, 0, self.bounds.size.width, 44)] autorelease];
    if(view != nil) self.columnHeaderView = view;
    [self layoutOnPropertyChange:YES];
}

- (void) layoutOnPropertyChange:(BOOL)didChangeZoom
{
    NSLog(@"Did layout on property change");
    CGRect bds = self.bounds;
    CGFloat rel = (scaleWindow.windowEnd - scaleWindow.windowStart) / (scaleWindow.viewSize);
    
    CGSize csz;
    if(didChangeZoom) {
        self.contentSize = csz = CGSizeMake(rel * bds.size.width, bds.size.height);
    } else {
        csz = self.contentSize;
    }
    self.contentOffset = CGPointMake(self.contentSize.width * (scaleWindow.viewStart-scaleWindow.windowStart) /(scaleWindow.windowEnd - scaleWindow.windowStart), 0);
    if(didChangeZoom) {
        if([self.columnHeaderView respondsToSelector:@selector(ganttView:didScaleWindow:)]) {
            [(id<IQGanttHeaderDelegate>)self.columnHeaderView ganttView:self didScaleWindow:scaleWindow];
        }
    } else {
        
    }
}

#pragma mark Disposal

- (void)dealloc
{
    [super dealloc];
}

#pragma mark Properties

- (NSCalendarUnit)displayCalendarUnits
{
    return displayCalendarUnits;
}

- (void)setDisplayCalendarUnits:(NSCalendarUnit)dcu
{
    displayCalendarUnits = dcu;
    UIView* view = self.columnHeaderView;
    if(view != nil && [view respondsToSelector:@selector(ganttView:shouldDisplayCalendarUnits:)]) {
        [(id<IQGanttHeaderDelegate>)view ganttView:self shouldDisplayCalendarUnits:displayCalendarUnits];
    }
}

- (IQGanttViewTimeWindow)scaleWindow
{
    return scaleWindow;
}

- (void)setScaleWindow:(IQGanttViewTimeWindow)win
{
    if(win.viewSize < 60) win.viewSize = 60;
    if(win.windowStart > win.viewStart) win.windowStart = win.viewStart;
    if(win.windowEnd < win.viewStart + win.viewSize) win.windowEnd = win.viewStart + win.viewSize;
    if(win.windowEnd - win.windowStart < 60) win.windowEnd = win.windowStart + 60;
    BOOL didChangeZoom = scaleWindow.windowStart != win.windowStart || scaleWindow.windowEnd != win.windowEnd || scaleWindow.viewSize != win.viewSize;
    scaleWindow = win;
    [self layoutOnPropertyChange:didChangeZoom];
}

- (UIColor*)backgroundColor
{
    return backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)bg
{
    [contentPanel setBackgroundColor:bg];
    [backgroundColor release];
    backgroundColor = [bg retain];
}
#pragma mark Scroll delegate

- (void)scrollViewDidScroll:(UIScrollView *)sv
{
    [super scrollViewDidScroll:sv];
    
    CGFloat cw = self.contentSize.width;
    if(cw > 0) {
        UIView* view = self.columnHeaderView;
        scaleWindow.viewStart = self.contentOffset.x / cw * (scaleWindow.windowEnd - scaleWindow.windowStart) + scaleWindow.windowStart;
        if(view != nil && [view respondsToSelector:@selector(ganttView:didMoveWindow:)]) {
            [(id<IQGanttHeaderDelegate>)view ganttView:self didMoveWindow:scaleWindow];
        }
    }
}

#pragma mark Data

- (void)removeAllRows
{
    
}
- (void)addRow:(id<IQCalendarDataSource>)row
{
    
}

#pragma mark Default implementation of base methods

- (UIView*) createCornerViewWithFrame:(CGRect)frame
{
    return nil;
}

- (UIView<IQGanttHeaderDelegate>*) createTimeHeaderViewWithFrame:(CGRect)frame
{
    return [[IQGanttHeaderView alloc] initWithFrame:frame];
}

- (UIView*) createRowHeaderViewWithFrame:(CGRect)frame
{
    return nil;
}

@end


@implementation IQGanttHeaderView
@synthesize tintColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self != nil) {
        self.tintColor = [UIColor colorWithRed:204/255.0 green:204/255.0 blue:209/255.0 alpha:1];
    }
    return self;
}

- (void)dealloc
{
    if(grad != nil) CGGradientRelease(grad);
    [tintColor release];
    [firstLineLabel release];
    [secondLineLabel release];
    [super dealloc];
}

+ (Class) layerClass
{
    return [CATiledLayer class];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGRect r = CGContextGetClipBoundingBox(ctx);
    CGSize size = self.bounds.size;
    if(grad != nil) {
        CGContextSetFillColorWithColor(ctx, [[UIColor whiteColor] CGColor]);
        CGContextDrawLinearGradient(ctx, grad, CGPointMake(r.origin.x, r.origin.y), CGPointMake(r.origin.x, r.origin.y + r.size.height), 0);
    }
    if(border != nil) {
        CGContextSetStrokeColorWithColor(ctx, border);
    }
    CGContextAddLines(ctx, (CGPoint[]){CGPointMake(r.origin.x, r.origin.y+r.size.height),
        CGPointMake(r.origin.x+r.size.width, r.origin.y+r.size.height)}, 2);
    CGContextStrokePath(ctx);
    CGFloat r0 = r.origin.x;
    CGFloat r1 = r.origin.x + r.size.width;
    CGFloat scl = (scaleWindow.windowEnd-scaleWindow.windowStart) / size.width;
    NSTimeInterval t0 = scaleWindow.windowStart + scl * r0;
    NSTimeInterval t1 = scaleWindow.windowStart + scl * r1;
    UIFont* textFont = [UIFont systemFontOfSize:8];
    if(scaleWindow.windowEnd > scaleWindow.windowStart) {
        NSCalendar* cal = [NSCalendar currentCalendar];
        int fwd = [cal firstWeekday];
        NSDate* d = [NSDate dateWithTimeIntervalSinceReferenceDate:t0];
        // Days
        NSDateComponents* cmpnts = [cal components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:d];
        NSTimeInterval t = [[cal dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
        while (t <= t1) {
            NSDateComponents* c2 = [cal components:NSWeekdayCalendarUnit|NSDayCalendarUnit fromDate:d];
            int wd = c2.weekday;
            NSLog(@"Weekday = %d", wd);
            CGFloat scale = 0.6;
            if(wd == fwd) {
                scale = 0.4;
            }
            
            CGFloat x = round(r0 + (t-t0) / scl)+.5;
            CGContextAddLines(ctx, (CGPoint[]){CGPointMake(x, r.origin.y+scale*r.size.height), CGPointMake(x, r.origin.y + r.size.height)}, 2);
            
            
            /*[@"Apan" drawAtPoint:CGPointMake(x, r.origin.y + r.size.height - 18) forWidth:30 withFont:textFont minFontSize:6 actualFontSize:nil lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentNone];*/
            CGContextSetFont(ctx, (CGFontRef)textFont);
            CGContextSetFontSize(ctx, 8);
            CGContextSetTextDrawingMode(ctx, kCGTextFill);
            CGContextSetTextPosition(ctx, x, r.origin.y + r.size.height - 18);
            CGContextShowText(ctx, "HejHopp", 7);
            
            cmpnts.day += 1;
            d = [cal dateFromComponents:cmpnts];
            t = [d timeIntervalSinceReferenceDate];
        }
        CGContextSetShadowWithColor(ctx, CGSizeMake(1, 0), 0, [[UIColor colorWithWhite:1 alpha:.5] CGColor]);
        CGContextStrokePath(ctx);
        NSLog(@"Drawing layer: %@", [NSDate dateWithTimeIntervalSinceReferenceDate:t0]);
    }
}

- (void)moveLabels
{
    if(firstLineLabel == nil) {
        firstLineLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 16)];
        firstLineLabel.text = @"Dummy";
        firstLineLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:firstLineLabel];
    }
    firstLineLabel.center = CGPointMake(offset+100, 8);
}

- (void)ganttView:(IQGanttView *)view didScaleWindow:(IQGanttViewTimeWindow)win
{
    NSLog(@"My window is %@", view);
    scaleWindow = win;
    [self moveLabels];
    [self setNeedsDisplay];
}

- (void)ganttView:(IQGanttView *)view didMoveWindow:(IQGanttViewTimeWindow)win
{
    scaleWindow = win;
    offset = view.contentOffset.x;
    [self moveLabels];
}

- (void)ganttView:(IQGanttView*)view shouldDisplayCalendarUnits:(NSCalendarUnit) dcu
{
    displayCalendarUnits = dcu;
    [self setNeedsDisplay];
}

- (void)setTintColor:(UIColor *)tc
{
    [tintColor release];
    tintColor = [tc retain];
    CGColorRef tint = [tc CGColor];
    const CGFloat* cmpnts = CGColorGetComponents(tint);
    CGFloat colors[] = {
        cmpnts[0]+.16, cmpnts[1]+.16, cmpnts[2]+.16, 1,
        cmpnts[0], cmpnts[1], cmpnts[2], 1,
        cmpnts[0]-.12, cmpnts[1]-.12, cmpnts[2]-.12, 1,
    };
    CGGradientRef gd = CGGradientCreateWithColorComponents(CGColorGetColorSpace(tint), colors, (CGFloat[]){0,1}, 2);
    CGColorRef bd = CGColorCreate(CGColorGetColorSpace(tint), colors+8);
    CGColorRef oldBorder = border;
    CGGradientRef oldGrad = grad;
    
    grad = CGGradientRetain(gd);
    border = CGColorRetain(bd);
    
    if(oldGrad != nil) {
        CGGradientRelease(oldGrad);
    }
    if(oldBorder != nil) {
        CGColorRelease(oldBorder);
    }
    
}

@end

