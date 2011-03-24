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
#import "IQScheduleView.h"
#import <QuartzCore/QuartzCore.h>
#import "IQCalendarDataSource.h"

@interface IQGanttView (PrivateMethods)
- (void) setupGanttView;
- (void) layoutOnRowsChange;
- (void) layoutOnPropertyChange:(BOOL)didChangeZoom;
- (UIView*) createBlockWithRow:(UIView*)rowView item:(id)item frame:(CGRect)frame;
@end

@implementation IQGanttView
@synthesize defaultRowHeight;

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
    calendar = [[NSCalendar currentCalendar] retain];
    defaultRowHeight = 72;
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
        if([view respondsToSelector:@selector(ganttView:didChangeCalendar:)]) {
            [(id<IQGanttHeaderDelegate>)view ganttView:self didChangeCalendar:calendar];
        }
        
        self.columnHeaderView = view;
    }
    view = [[self createRowHeaderViewWithFrame:CGRectMake(0, 0, 100, self.bounds.size.height)] autorelease];
    if(view != nil) self.rowHeaderView = view;
    view = [[self createCornerViewWithFrame:CGRectMake(0, 0, self.bounds.size.width, 44)] autorelease];
    if(view != nil) self.cornerView = view;
    [self layoutOnPropertyChange:YES];
}

- (void) layoutOnPropertyChange:(BOOL)didChangeZoom
{
    CGRect bds = self.bounds;
    CGFloat rel = (scaleWindow.windowEnd - scaleWindow.windowStart) / (scaleWindow.viewSize);
    
    CGSize csz;
    if(didChangeZoom) {
        self.contentSize = csz = CGSizeMake(rel * bds.size.width, bds.size.height);
    } else {
        csz = self.contentSize;
    }
    self.contentOffset = CGPointMake(self.contentSize.width * (scaleWindow.viewStart-scaleWindow.windowStart) / (scaleWindow.windowEnd - scaleWindow.windowStart), 0);
    if(didChangeZoom) {
        if([self.columnHeaderView respondsToSelector:@selector(ganttView:didScaleWindow:)]) {
            [(id<IQGanttHeaderDelegate>)self.columnHeaderView ganttView:self didScaleWindow:scaleWindow];
        }
        [self layoutOnRowsChange];
        for(UIView<IQGanttRowDelegate>* view in rowViews) {
            if([view respondsToSelector:@selector(ganttView:didScaleWindow:)]) {
                [(id<IQGanttRowDelegate>)view ganttView:self didScaleWindow:scaleWindow];
            }
        }
    } else {
        
    }
}

- (void)layoutOnRowsChange
{
    int y = 0;
    if(columnHeaderView != nil) {
        y += columnHeaderView.frame.size.height;
    }
    for(int i = 0; i < rows.count; i++) {
        UIView* view = [rowViews objectAtIndex:i];
        id<IQCalendarDataSource> data = [rows objectAtIndex:i];
        NSInteger height = defaultRowHeight;
        if(rowHeight != nil) height = rowHeight(self, view, data);
        view.frame = CGRectMake(0, y, self.contentSize.width, height);
        y += height;
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

- (NSCalendar*)calendar
{
    return calendar;
}

- (void)setCalendar:(NSCalendar *)cal
{
    [calendar release];
    calendar = [cal retain];
    
    if([columnHeaderView respondsToSelector:@selector(ganttView:didChangeCalendar:)]) {
        [(id<IQGanttHeaderDelegate>)columnHeaderView ganttView:self didChangeCalendar:calendar];
    }
    for(UIView* view in rowViews) {
        if([view respondsToSelector:@selector(ganttView:didChangeCalendar:)]) {
            [(id<IQGanttRowDelegate>)view ganttView:self didChangeCalendar:calendar];
        }
    }
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
    for(UIView* view in rowViews) {
        [view removeFromSuperview];
    }
    [rows removeAllObjects];
    [rowViews removeAllObjects];
    [self layoutOnRowsChange];
}
- (void)addRow:(id<IQCalendarDataSource>)row
{
    UIView<IQGanttRowDelegate>* view = [self createViewForRow:row withFrame:CGRectMake(0, 0, self.contentSize.width, self.bounds.size.height * 0.25)];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:view];
    if(rows == nil) rows = [NSMutableArray new];
    if(rowViews == nil) rowViews = [NSMutableArray new];
    [rows addObject:row];
    [rowViews addObject:view];
    if([view respondsToSelector:@selector(ganttView:didChangeDataSource:)]) {
        [view ganttView:self didChangeDataSource:row];
    }
    if([view respondsToSelector:@selector(ganttView:didChangeCalendar:)]) {
        [view ganttView:self didChangeCalendar:calendar];
    }
    [view setNeedsDisplay];
    NSLog(@"Added row: %@", view);
    [self layoutOnRowsChange];
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
- (UIView<IQGanttRowDelegate>*) createViewForRow:(id<IQCalendarDataSource>)row withFrame:(CGRect)frame
{
    return [[IQGanttRowView alloc] initWithFrame:frame];
}

- (UIView*) createBlockWithRow:(UIView*)rowView item:(id)item frame:(CGRect)frame
{
    if(createBlock == nil) {
        IQScheduleBlockView* lbl = [[IQScheduleBlockView alloc] initWithFrame:frame];
        lbl.contentMode = UIViewContentModeCenter;
        lbl.backgroundColor = [UIColor redColor];
        return lbl;
    }
    return createBlock(self, rowView, item, frame);
}

@end

@implementation IQGanttView (CallbackInterface)

- (void)setBlockCreationCallback:(IQGanttBlockViewCreationCallback)callback
{
    createBlock = callback;
}
- (void) setRowHeightCallback:(IQGanttRowHeightCallback)callback
{
    Block_release(rowHeight);
    rowHeight = Block_copy(callback);
}

@end

@implementation IQGanttHeaderView
@synthesize tintColor, monthNameFormatter;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self != nil) {
        weekPrefixChar = 'w';
        monthNameFormatter = [[NSDateFormatter alloc] init];
        [monthNameFormatter setDateFormat:@"MMMM YYYY"];
        self.tintColor = [UIColor colorWithRed:204/255.0 green:204/255.0 blue:209/255.0 alpha:1];
        int i = 0;
        for(NSString* wds in [[NSCalendar currentCalendar] veryShortWeekdaySymbols]) {
            weekdayLetters[i++] = [wds cStringUsingEncoding:NSUTF8StringEncoding][0];
            if(i >= 7) break;
        }
    }
    return self;
}

- (void)dealloc
{
    if(grad != nil) CGGradientRelease(grad);
    [tintColor release];
    [cal release];
    [floatingLabels release];
    [monthNameFormatter release];
    [super dealloc];
}

+ (Class) layerClass
{
    return [CATiledLayer class];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGRect r = CGContextGetClipBoundingBox(ctx);
    CGSize size = self.bounds.size;
    CGContextSaveGState(ctx);
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
    NSCalendar* calendar = [[cal copy] autorelease];
    if(scaleWindow.windowEnd > scaleWindow.windowStart) {
        int fwd = [calendar firstWeekday];
        NSDate* d = [NSDate dateWithTimeIntervalSinceReferenceDate:t0];
        // Days
        NSDateComponents* cmpnts = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:d];
        NSTimeInterval t = [[calendar dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
        CGAffineTransform xform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
        CGContextSetTextMatrix(ctx, xform);
        CGContextSelectFont(ctx, [textFont.fontName cStringUsingEncoding:NSUTF8StringEncoding], 10, kCGEncodingMacRoman);
        CGContextSetFontSize(ctx, 10);
        CGContextSetTextDrawingMode(ctx, kCGTextFill);
        while (t <= t1) {
            NSDateComponents* c2 = [calendar components:NSWeekdayCalendarUnit|NSDayCalendarUnit|NSWeekCalendarUnit fromDate:d];
            int wd = c2.weekday;
            int md = c2.day;
            int wk = c2.week;
            CGFloat scale = 0.6;
            if(wd == fwd && displayCalendarUnits & NSWeekCalendarUnit) {
                scale = 0.4;
            }
            if(md == 1) {
                scale = 0;
            }
            
            CGFloat x = round(r0 + (t-t0) / scl)+.5;
            CGContextAddLines(ctx, (CGPoint[]){CGPointMake(x, r.origin.y+scale*r.size.height), CGPointMake(x, r.origin.y + r.size.height)}, 2);
            
            
            /*[@"Apan" drawAtPoint:CGPointMake(x, r.origin.y + r.size.height - 18) forWidth:30 withFont:textFont minFontSize:6 actualFontSize:nil lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentNone];*/
            //CGContextSetTextDrawingMode (ctx, kCGTextFillStroke);
            char str[12] = "";
            if(displayCalendarUnits & NSWeekdayCalendarUnit) {
                if(displayCalendarUnits & NSDayCalendarUnit) {
                    snprintf(str, sizeof(str), "%c %d", weekdayLetters[wd-1], md);
                } else {
                    snprintf(str, sizeof(str), "%c", weekdayLetters[wd-1]);
                }
            } else {
                if(displayCalendarUnits & NSDayCalendarUnit) {
                    snprintf(str, sizeof(str), "%d", md);
                }
            }
            if(str[0] != 0) {
                CGContextSetRGBFillColor (ctx, 1, 1, 1, 1);
                CGContextShowTextAtPoint(ctx, round(x + 3), round(r.origin.y + r.size.height - 3), str, strlen(str));
                if(wd == 1) {
                    CGContextSetRGBFillColor(ctx, 1, 0.05, 0, 1);
                } else {
                    CGContextSetRGBFillColor(ctx, 0.1, 0.05, 0, 1);
                }
                CGContextShowTextAtPoint(ctx, round(x + 3), round(r.origin.y + r.size.height - 4), str, strlen(str));
            }
            if(wd == fwd && displayCalendarUnits & NSWeekCalendarUnit) {
                CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.7);
                snprintf(str, sizeof(str), "%c%d", weekPrefixChar, wk);
                CGContextShowTextAtPoint(ctx, round(x + 3), round(r.origin.y + 0.4*r.size.height + 10), str, strlen(str));
            }
            
            cmpnts.day += 1;
            d = [calendar dateFromComponents:cmpnts];
            t = [d timeIntervalSinceReferenceDate];
        }
        CGContextSetShadowWithColor(ctx, CGSizeMake(1, 0), 0, [[UIColor colorWithWhite:1 alpha:.5] CGColor]);
        CGContextStrokePath(ctx);
        //NSLog(@"Drawing layer: %@", [NSDate dateWithTimeIntervalSinceReferenceDate:t0]);
    }
    CGContextRestoreGState(ctx);
}

- (UILabel*)floatAtIndex:(int)index
{
    if(floatingLabels == nil) {
        floatingLabels = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    while(index >= floatingLabels.count) {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 16)];
        label.font = [UIFont boldSystemFontOfSize:12];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor colorWithRed:.15 green:.1 blue:0 alpha:1];
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        //label.lineBreakMode = UILineBreakModeClip;
        [self addSubview:label];
        [floatingLabels addObject:label];
    }
    return [floatingLabels objectAtIndex:index];
}

- (void)moveLabels
{
    NSTimeInterval t0 = scaleWindow.viewStart;
    NSTimeInterval t1 = scaleWindow.viewStart + scaleWindow.viewSize;
    
    NSCalendar* calendar = [[cal copy] autorelease];
    if(scaleWindow.windowEnd > scaleWindow.windowStart) {
        NSDate* d = [NSDate dateWithTimeIntervalSinceReferenceDate:t0];
        NSDateComponents* cmpnts = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:d];
        cmpnts.day = 1;
        cmpnts.month += 1;
        NSDate* od = d;
        d = [calendar dateFromComponents:cmpnts];
        NSTimeInterval t = [d timeIntervalSinceReferenceDate];
        int i = 0;
        CGFloat scl = self.bounds.size.width / (scaleWindow.windowEnd-scaleWindow.windowStart);
        CGRect bnds = CGRectMake(0, 3, 200, 18);
        while(t0 <= t1) {
            bnds.origin.x = 4 + round((t0-scaleWindow.windowStart) * scl);
            if(offset < 0 && t0 <= scaleWindow.viewStart) {
                bnds.origin.x -= offset;
            }
            CGFloat w = round((t-scaleWindow.windowStart) * scl) - bnds.origin.x;
            if(w > 20) {
                UILabel* lbl = [self floatAtIndex:i++];
                lbl.hidden = NO;
                lbl.frame = bnds;
                lbl.text = [monthNameFormatter stringFromDate:od];
                CGFloat a = (w-20) / 100;
                if(a > 1) a = 1;
                lbl.alpha = a;
            }
            cmpnts.month += 1;
            t0 = t;
            od = d;
            d = [calendar dateFromComponents:cmpnts];
            t = [d timeIntervalSinceReferenceDate];
        }
        for(;i<floatingLabels.count; i++) {
            [[self floatAtIndex:i] setHidden:YES];
        }
    }
    
    /*if(firstLineLabel == nil) {
     }
     firstLineLabel.center = CGPointMake(offset+100, 8);*/
}

- (void)ganttView:(IQGanttView *)view didScaleWindow:(IQGanttViewTimeWindow)win
{
    scaleWindow = win;
    offset = view.contentOffset.x;
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

- (void)ganttView:(IQGanttView *)view didChangeCalendar:(NSCalendar*)calendar
{
    NSCalendar* oldCal = cal;
    cal = [calendar retain];
    [oldCal release];
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

@implementation IQGanttRowView
@synthesize dataSource, primaryGridColor, secondaryGridColor, tertaryGridColor, primaryGridDash, secondaryGridDash, tertaryGridDash;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        primaryGridColor = [[UIColor grayColor] retain];
        secondaryGridColor = [[UIColor grayColor] retain];
        tertaryGridColor = [[UIColor colorWithWhite:0.8 alpha:1] retain];
        primaryLineUnits = NSMonthCalendarUnit;
        secondaryLineUnits = NSWeekCalendarUnit;
        tertaryLineUnits = NSDayCalendarUnit;
        secondaryGridDash = IQMakeGridDash(5, 5);
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)dealloc
{
    [cal release];
    [primaryGridColor release];
    [secondaryGridColor release];
    [tertaryGridColor release];
    [super dealloc];
}

+ (Class) layerClass
{
    return [CATiledLayer class];
}

- (void) layoutItems:(IQGanttView*)gantt
{
    while(self.subviews.count > 0) {
        [[self.subviews lastObject] removeFromSuperview];
    }
    NSTimeInterval t0 = scaleWindow.windowStart;
    NSTimeInterval t1 = scaleWindow.windowEnd;
    CGSize sz = self.bounds.size;
    CGFloat tscl = sz.width / (t1 - t0);
    [self.dataSource enumerateEntriesUsing:^(id item, NSTimeInterval startDate, NSTimeInterval endDate) {
        CGRect frame = CGRectMake((startDate-t0)*tscl, 0, (endDate-startDate)*tscl, sz.height);
        //UIButton* btn = [[[UIButton alloc] initWithFrame:frame] autorelease];
        /*UIButton* btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
         btn.frame = frame;
         btn.titleLabel.text = @"Apan";*/
        //btn.buttonType = UIButtonTypeRoundedRect;
        UIView* blk = [[gantt createBlockWithRow:self item:item frame:frame] autorelease];
        if([blk respondsToSelector:@selector(setText:)] && [self.dataSource respondsToSelector:@selector(textForItem:)]) {
            NSString* txt = [self.dataSource textForItem:item];
            if(txt != nil) {
                [(id)blk setText:txt];
            }
        }
        [self addSubview:blk];
        //[self addSubview:btn];
    } from:scaleWindow.windowStart to:scaleWindow.windowEnd];
}

- (void)ganttView:(IQGanttView *)view didChangeDataSource:(id<IQCalendarDataSource>)ds
{
    self.dataSource = ds;
    if(scaleWindow.windowEnd > scaleWindow.windowStart) {
        [self layoutItems:view];
    }
}

- (void)ganttView:(IQGanttView *)view didChangeCalendar:(NSCalendar*)calendar
{
    NSCalendar* oldCal = cal;
    cal = [calendar retain];
    [oldCal release];
    [self setNeedsDisplay];
}

#pragma Grid properties

- (void)setPrimaryGridColor:(UIColor *)gcl
{
    UIColor* oldGridColor = primaryGridColor;
    primaryGridColor = [gcl retain];
    [oldGridColor release];
    [self setNeedsDisplay];
}

- (void)setSecondaryGridColor:(UIColor *)gcl
{
    UIColor* oldGridColor = secondaryGridColor;
    secondaryGridColor = [gcl retain];
    [oldGridColor release];
    [self setNeedsDisplay];
}

- (void)setTertaryGridColor:(UIColor *)gcl
{
    UIColor* oldGridColor = tertaryGridColor;
    tertaryGridColor = [gcl retain];
    [oldGridColor release];
    [self setNeedsDisplay];
}

- (void)setPrimaryGridDash:(IQGridDash)gd
{
    primaryGridDash = gd;
    [self setNeedsDisplay];
}

- (void)setSecondaryGridDash:(IQGridDash)gd
{
    secondaryGridDash = gd;
    [self setNeedsDisplay];
}

- (void)setTertaryGridDash:(IQGridDash)gd
{
    tertaryGridDash = gd;
    [self setNeedsDisplay];
}

#pragma mark Drawing

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGRect r = CGContextGetClipBoundingBox(ctx);
    CGContextSetFillColorWithColor(ctx, [[self backgroundColor] CGColor]);
    CGContextFillRect(ctx, r);
    //CGRect r2 = CGRectMake(r.origin.x + 3, r.origin.y + 3, r.size.width-6, r.size.height-6);
    //CGContextStrokeRect(ctx, r2);
    CGSize size = self.bounds.size;
    //if(gridColor != nil) CGContextSetStrokeColorWithColor(ctx, [gridColor CGColor]);
    CGFloat r0 = r.origin.x;
    CGFloat r1 = r.origin.x + r.size.width;
    CGFloat scl = (scaleWindow.windowEnd-scaleWindow.windowStart) / size.width;
    NSTimeInterval t0 = scaleWindow.windowStart + scl * r0;
    NSTimeInterval t1 = scaleWindow.windowStart + scl * r1;
    CGContextSaveGState(ctx);
    
    //CGAffineTransform xform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
    //CGContextSetTextMatrix(ctx, xform);
    //CGContextSelectFont(ctx, "Helvetica", 10, kCGEncodingMacRoman);
    //CGContextSetFontSize(ctx, 10);
    //CGContextSetTextDrawingMode(ctx, kCGTextFill);
    //CGContextSetFillColorWithColor(ctx, [[UIColor blackColor] CGColor]);
    NSCalendar* calendar = [[cal copy] autorelease];
    IQGridDash prevGridDash = IQMakeGridDash(0, 0);
    UIColor* prevGridColor = nil;
    if(scaleWindow.windowEnd > scaleWindow.windowStart) {
        int fwd = [calendar firstWeekday];
        NSDate* d = [NSDate dateWithTimeIntervalSinceReferenceDate:t0];
        // Days
        NSDateComponents* cmpnts = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:d];
        NSTimeInterval t = [[calendar dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
        //int text = 0;
        while (t <= t1) {
            NSDateComponents* c2 = [calendar components:NSWeekdayCalendarUnit|NSDayCalendarUnit fromDate:d];
            int wd = c2.weekday;
            int md = c2.day;
            CGFloat x = round(r0 + (t-t0) / scl)+.5;
            
            BOOL l1 = NO, l2 = NO, l3 = NO;
            
            if(primaryLineUnits & NSDayCalendarUnit) {
                l1 = YES;
            }
            if(secondaryLineUnits & NSDayCalendarUnit) {
                l2 = YES;
            }
            if(tertaryLineUnits & NSDayCalendarUnit) {
                l3 = YES;
            }
            if(wd == fwd) {
                if(primaryLineUnits & NSWeekCalendarUnit) {
                    l1 = YES;
                }
                if(secondaryLineUnits & NSWeekCalendarUnit) {
                    l2 = YES;
                }
                if(tertaryLineUnits & NSWeekCalendarUnit) {
                    l3 = YES;
                }
            }
            if(md == 1) {
                if(primaryLineUnits & NSMonthCalendarUnit) {
                    l1 = YES;
                }
                if(secondaryLineUnits & NSMonthCalendarUnit) {
                    l2 = YES;
                }
                if(tertaryLineUnits & NSMonthCalendarUnit) {
                    l3 = YES;
                }
            }
            /*if(YES) {
                char buf[1024];
                snprintf(buf, sizeof(buf), "%d %d %c%c%c %f", wd, md, l1?'1':' ', l2?'2':' ', l3?'3':' ', t);
                CGContextShowTextAtPoint(ctx, r.origin.x + 20, r.origin.y+20+text*15, buf, strlen(buf));
                text ++;
                //text = NO;
            }*/
            CGContextAddLines(ctx, (CGPoint[]){CGPointMake(x, r.origin.y), CGPointMake(x, r.size.height + r.origin.y)}, 2);
            IQGridDash gd;
            UIColor* color = nil;
            if(l1) {
                gd = primaryGridDash;
                color = primaryGridColor;
            } else if(l2) {
                gd = secondaryGridDash;
                color = secondaryGridColor;
            } else if(l3) {
                gd = tertaryGridDash;
                color = tertaryGridColor;
            }
            if(color != nil) {
                if(YES || gd.a != prevGridDash.a || gd.b != prevGridDash.b || color != prevGridColor) {
                    prevGridDash = gd;
                    prevGridColor = color;
                    if(gd.a != 0 || gd.b != 0) {
                        CGContextSetLineDash(ctx, r.origin.y+self.frame.origin.y, (CGFloat[]){gd.a, gd.b}, 2);
                    } else {
                        CGContextSetLineDash(ctx, 0, nil, 0);
                    }
                    CGContextSetStrokeColorWithColor(ctx, [color CGColor]);
                    CGContextStrokePath(ctx);
                }
            }
            cmpnts.day += 1;
            d = [calendar dateFromComponents:cmpnts];
            t = [d timeIntervalSinceReferenceDate];
        }
    }
    CGContextRestoreGState(ctx);
}

- (void)ganttView:(IQGanttView *)view didScaleWindow:(IQGanttViewTimeWindow)win
{
    scaleWindow = win;
    if(scaleWindow.windowEnd > scaleWindow.windowStart) {
        [self layoutItems:view];
    }
    [self setNeedsDisplay];
}

@end

