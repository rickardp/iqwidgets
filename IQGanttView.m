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
- (void) createViews;
- (void) layoutOnPropertyChange;
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
    NSDateComponents* cmpnts = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    cmpnts.day = 1;
    scaleWindow.viewStart = [[[NSCalendar currentCalendar] dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
    cmpnts.month += 1;
    scaleWindow.viewEnd = [[[NSCalendar currentCalendar] dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
    cmpnts.month = 1;
    scaleWindow.windowStart = [[[NSCalendar currentCalendar] dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
    cmpnts.year += 1;
    scaleWindow.windowEnd = [[[NSCalendar currentCalendar] dateFromComponents:cmpnts] timeIntervalSinceReferenceDate];
    NSLog(@"Date is %@ - %@", [NSDate dateWithTimeIntervalSinceReferenceDate:scaleWindow.viewStart], [NSDate dateWithTimeIntervalSinceReferenceDate:scaleWindow.viewEnd]);
    NSLog(@"Date is %@ - %@", [NSDate dateWithTimeIntervalSinceReferenceDate:scaleWindow.windowStart], [NSDate dateWithTimeIntervalSinceReferenceDate:scaleWindow.windowEnd]);
    [self setBackgroundColor:[UIColor whiteColor]];
    [super setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
}

#pragma mark Layout

- (void)createViews
{
    if(contentView == nil) {
        contentView = [[UIScrollView alloc] initWithFrame:self.bounds];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        contentView.delegate = self;
        contentPanel = [[UIView alloc] initWithFrame:self.bounds];
        contentPanel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        contentPanel.layer.shadowOpacity = 0.9;
        contentPanel.layer.shadowRadius = 17.0;
        contentPanel.backgroundColor = self.backgroundColor;
        contentPanel.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        [contentView addSubview:contentPanel];
        //contentView.frame = CGRectMake(0, sz, self.bounds.size.width, self.bounds.size.height - sz);
        contentView.contentSize = CGSizeMake(120, 120);
        contentView.scrollEnabled = YES;
        contentView.backgroundColor = [UIColor clearColor];
        //contentView.directionalLockEnabled = YES;
        [self addSubview:contentView];
    }
    if(headerView == nil) {
        self.headerView = [[[IQGanttHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 44)] autorelease];
    }
}

- (void) layoutOnPropertyChange
{
    CGRect bds = self.bounds;
    CGRect hdf = headerView.frame;
    CGFloat offset = hdf.size.height;
    CGFloat rel = (scaleWindow.windowEnd - scaleWindow.windowStart) / (scaleWindow.viewEnd - scaleWindow.viewStart);
    contentView.contentSize = CGSizeMake(rel * bds.size.width, offset + bds.size.height);
    hdf.size.width = contentView.contentSize.width;
    headerView.frame = hdf;
    if([headerView respondsToSelector:@selector(ganttView:didUpdateWindow:)]) {
        [headerView ganttView:self didUpdateWindow:scaleWindow];
    }
}

- (void) didMoveToWindow
{
    [self createViews];
}

#pragma mark Disposal

- (void)dealloc
{
    self.headerView = nil;
    [super dealloc];
}

#pragma mark Properties

- (IQGanttViewTimeWindow)scaleWindow
{
    return scaleWindow;
}

- (void)setScaleWindow:(IQGanttViewTimeWindow)win
{
    if(win.viewEnd - win.viewStart < 60) win.viewEnd = win.viewStart + 60;
    if(win.windowStart > win.viewStart) win.windowStart = win.viewStart;
    if(win.windowEnd < win.viewEnd) win.windowEnd = win.viewEnd;
    if(win.windowEnd - win.windowStart < 60) win.windowEnd = win.windowStart + 60;
    scaleWindow = win;
    [self layoutOnPropertyChange];
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

- (BOOL)isDirectionalLockEnabled
{
    return [contentView isDirectionalLockEnabled];
}

- (void)setDirectionalLockEnabled:(BOOL)directionalLockEnabled
{
    [contentView setDirectionalLockEnabled:directionalLockEnabled];
}

#pragma mark Scroll delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView == contentView) {
        CGRect rc = headerView.frame;
        CGRect cc = contentPanel.frame;
        if(contentView.contentOffset.y < 0) {
            rc.origin.y = 0;
            cc.origin.y = 0;
            contentView.scrollIndicatorInsets = UIEdgeInsetsMake(rc.size.height-contentView.contentOffset.y, 0, 0, 0);
        } else if(contentView.contentOffset.y > contentView.contentSize.height-contentView.bounds.size.height) {
            cc.origin.y = contentView.contentSize.height-contentView.bounds.size.height;
        } else {
            rc.origin.y = contentView.contentOffset.y;
            cc.origin.y = contentView.contentOffset.y;
            contentView.scrollIndicatorInsets = UIEdgeInsetsMake(rc.size.height, 0, 0, 0);            
        }
        if(contentView.contentOffset.x < 0) {
            cc.origin.x = 0;
        } else if(contentView.contentOffset.x > contentView.contentSize.width-contentView.bounds.size.width) {
            cc.origin.x = contentView.contentSize.width-contentView.bounds.size.width;
        } else {
            cc.origin.x = contentView.contentOffset.x;
            //rc.origin.x = -contentView.contentOffset.x;
        }
        /*rc.origin.x = -contentView.contentOffset.x;
        if(contentView.contentOffset.y < 0) {
            rc.origin.y = -contentView.contentOffset.y;
            contentView.contentOffset = CGPointMake(contentView.contentOffset.x, 0);
        } else {
            rc.origin.y = 0;
        }*/
        contentPanel.frame = cc;
        headerView.frame = rc;
    }
}

#pragma mark Header

- (UIView<IQGanttHeaderDelegate>*) headerView
{
    [self createViews];
    return headerView;
}

- (void) setHeaderView:(UIView<IQGanttHeaderDelegate> *)hdv
{
    if(headerView != nil) {
        [headerView removeFromSuperview];
        [headerView release];
    }
    headerView = [hdv retain];
    CGFloat sz = headerView.bounds.size.height;
    headerView.frame = CGRectMake(0, 0, 100, sz);
    if(contentView != nil) {
        [contentView addSubview:headerView];
    }
    [self layoutOnPropertyChange];
}

#pragma mark Data

- (void)removeAllRows
{
    
}
- (void)addRow:(id<IQCalendarDataSource>)row
{
    
}
@end

@implementation IQGanttHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self != nil) {
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

+ (Class) layerClass
{
    return [CATiledLayer class];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    NSLog(@"Drawing layer: %@", layer);
    CGRect r = CGContextGetClipBoundingBox(ctx);
    CGContextSetFillColorWithColor(ctx, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(ctx, r);
    CGFloat r0 = r.origin.x;
    CGFloat y0 = 60+60*sin(r0/60);
    for(CGFloat r1 = r.origin.x+4; r1 <= r.origin.x + r.size.width; r1 += 4) {
        CGFloat y1 = 60+60*sin(r1/60);
        CGContextAddLines(ctx, (CGPoint[]){CGPointMake(r0, y0), CGPointMake(r1, y1)}, 2);
        y0 = y1;
        r0 = r1;
    }
    CGContextStrokePath(ctx);
    NSLog(@"Drawing layer: %f,%f,%f,%f", r.origin.x, r.origin.y, r.size.width, r.size.height);
}

- (void)ganttView:(IQGanttView *)view didUpdateWindow:(IQGanttViewTimeWindow)win
{
    NSLog(@"My window is %@", view);
    scaleWindow = win;
}

@end


