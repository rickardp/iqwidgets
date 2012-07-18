//
//  IQDrawerView.m
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-10-01.
//  Copyright (c) 2011 EvolvIQ. All rights reserved.
//

#import "IQDrawerView.h"
#import <QuartzCore/QuartzCore.h>

@interface IQDrawerHeaderView : UIView <UIGestureRecognizerDelegate> {
@public
    BOOL bottom;
    CGSize tipSize;
    CGFloat borderHeight;
}

- (id) initWithFrame:(CGRect)frame bottom:(BOOL)bottom;
@end

@implementation IQDrawerView
@synthesize drawerDelegate;

- (id) initWithStyle:(IQDrawerViewStyle)drawerStyle align:(IQDrawerViewAlign)align
{
    self = [super initWithFrame:CGRectMake(0, 0, 0, 30)];
    if (self) {
        contentHeight = 0;
        style = drawerStyle;
        bottom = (align == IQDrawerViewAlignBottom);
        header = [[IQDrawerHeaderView alloc] initWithFrame:self.bounds bottom:bottom];
        if(bottom) {
            self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        } else {
            self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        }
        [self addSubview:header];
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)dealloc
{
    [header release];
    [backgroundView release];
    [super dealloc];
}

- (void)didMoveToSuperview
{
    for(UIView* view in self.superview.subviews) {
        if(view == self) break;
        if([view isKindOfClass:[UIToolbar class]] || [view isKindOfClass:[UINavigationBar class]]) {
            NSLog(@"Will move me to behind the toolbar %@", view);
            [self.superview insertSubview:view belowSubview:view];
            return;
        }
    }
    CGRect frame = self.frame;
    if(frame.size.width == 0) {
        frame.size.width = self.superview.bounds.size.width;
        self.frame = frame;
    }
}

- (void)layoutSubviews
{
    contentHeight = contentView.bounds.size.height;
    [self setExpanded:expanded animated:NO];
    CGRect r = self.bounds;
    CGFloat framesz = header->tipSize.height+header->borderHeight;
    if(bottom) {
        header.frame = CGRectMake(0, 0, r.size.width, framesz);
        backgroundView.frame = CGRectMake(0, framesz, r.size.width, contentHeight);
    } else {
        header.frame = CGRectMake(0, r.size.height-framesz, r.size.width, framesz);
        backgroundView.frame = CGRectMake(0, 0, r.size.width, contentHeight);
    }
    contentView.frame = backgroundView.frame;
}

- (void) _animationsComplete
{
    if([(NSObject*)drawerDelegate respondsToSelector:@selector(drawer:didChangeState:)]) {
        [drawerDelegate drawer:self didChangeState:expanded];
    }
}

- (void) setExpanded:(BOOL)newexp
{
    [self setExpanded:newexp animated:YES];
}

- (BOOL) expanded
{
    return expanded;
}
    
- (void) setExpanded:(BOOL)newexp animated:(BOOL)animated
{
    CGRect r = self.superview.bounds;
    if(newexp == expanded && animated) return;
    expanded = newexp;
    if([(NSObject*)drawerDelegate respondsToSelector:@selector(drawer:willChangeState:)]) {
        [drawerDelegate drawer:self willChangeState:expanded];
    }
    CGRect frame = self.frame;
    CGFloat ht0 = header->borderHeight + header->tipSize.height;
    frame.size.height = ht0 + contentHeight;
    if(bottom) {
        CGFloat ylow = r.size.height;
        for(UIView* view in self.superview.subviews) {
            if([view isKindOfClass:[UIToolbar class]]) {
                CGRect cr = view.frame;
                if(cr.origin.y < ylow) ylow = cr.origin.y;
            }
        }
        if(expanded) frame.origin.y = ylow-frame.size.height;
        else frame.origin.y = ylow-ht0;
    } else {
        if(expanded) frame.origin.y = 0;
        else frame.origin.y = -contentHeight;
    }
    if(animated) [UIView beginAnimations:nil context:nil];
    self.frame = frame;
    if(animated) {
        [UIView setAnimationDidStopSelector:@selector(_animationsComplete)];
        [UIView setAnimationDelegate:self];
        [UIView commitAnimations];   
    }
}

- (void) toggleExpanded
{
    [self setExpanded:!expanded animated:YES];
}

- (void) _createBackgroundView
{
    if(!backgroundViewIsImage) {
        [backgroundView removeFromSuperview];
        [backgroundView release];
        backgroundView = nil;
    }
    if(backgroundView == nil) {
        backgroundViewIsImage = YES;
        backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 10)];
        [self addSubview:backgroundView];
    }
}

- (void) _createContentView
{
    if(contentView == nil) {
        contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 10)];
        [self addSubview:contentView];
    }
}

#pragma mark Properties

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [self _createBackgroundView];
    [backgroundView setBackgroundColor:backgroundColor];
}

- (UIColor*)backgroundColor
{
    if(!backgroundViewIsImage) return [UIColor clearColor];
    return backgroundView.backgroundColor;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    [self _createBackgroundView];
    [(UIImageView*)backgroundView setImage:backgroundImage];
}

- (UIImage*)backgroundImage
{
    if(!backgroundViewIsImage) return nil;
    return [(UIImageView*)backgroundView image];
}

- (void)setBackgroundView:(UIView *)bgv
{
    [backgroundView removeFromSuperview];
    backgroundView = [bgv retain];
    [self addSubview:backgroundView];
}

- (UIView*)backgroundView
{
    return backgroundView;
}

- (void)setContentView:(UIView *)cv
{
    [contentView removeFromSuperview];
    contentView = [cv retain];
    [self addSubview:contentView];
}

- (UIView*)contentView
{
    if(contentView == nil) {
        [self setContentView:[[[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 10)] autorelease]];
    }
    return contentView;
}

- (void)setShadowColor:(UIColor *)shadowColor {
    header.layer.shadowColor = shadowColor.CGColor;
}

- (UIColor*)shadowColor {
    CGColorRef colr = header.layer.shadowColor;
    if(colr == nil) return nil;
    return [UIColor colorWithCGColor:colr];
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity {
    header.layer.shadowOpacity = shadowOpacity;
}

- (CGFloat)shadowOpacity {
    return header.layer.shadowOpacity;
}

- (void)setShadowOffset:(CGSize)shadowOffset {
    header.layer.shadowOffset = shadowOffset;
}

- (CGSize)shadowOffset {
    return header.layer.shadowOffset;
}

- (void)setShadowRadius:(CGFloat)shadowRadius {
    header.layer.shadowRadius = shadowRadius;
}

- (CGFloat)shadowRadius {
    return header.layer.shadowRadius;
}
@end


@implementation IQDrawerHeaderView

- (void) toggleByTap
{
    [(IQDrawerView*)self.superview toggleExpanded];
}

- (id) initWithFrame:(CGRect)frame bottom:(BOOL)btm
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 30)];
    if (self) {
        bottom = btm;
        tipSize = CGSizeMake(100, 20);
        borderHeight = 10;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        if(bottom) {
            self.layer.shadowOffset = CGSizeMake(0, -2);
        } else {
            self.layer.shadowOffset = CGSizeMake(0, 2);
        }
        self.opaque = NO;
        UITapGestureRecognizer* tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleByTap)] autorelease];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (CGGradientRef) newFill
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locs[] = {0,0.5,0.5,1};
    CGColorRef tint1 = [UIColor colorWithRed:175.0f/255.0f green:189.0f/255.0f blue:205.0f/255.0f alpha:1.0f].CGColor;
    CGColorRef tint2 = [UIColor colorWithRed:134.0f/255.0f green:156.0f/255.0f blue:179.0f/255.0f alpha:1.0f].CGColor;
    CGColorRef tint3 = [UIColor colorWithRed:126.0f/255.0f green:150.0f/255.0f blue:174.0f/255.0f alpha:1.0f].CGColor;
    CGColorRef tint4 = [UIColor colorWithRed:106.0f/255.0f green:133.0f/255.0f blue:162.0f/255.0f alpha:1.0f].CGColor;
    NSArray* colors = [NSArray arrayWithObjects:(id)tint1,(id)tint2,(id)tint3,(id)tint4,nil];
    CGGradientRef grad = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, locs);
    CGColorSpaceRelease(colorSpace);
    return grad;
}

- (UIBezierPath*)drawerPathWithTopCap:(BOOL)topCap
{
    CGRect r = self.bounds;
    CGFloat rc = .5*r.size.width+.25*tipSize.width, lc = .5*r.size.width-.25*tipSize.width;
    UIBezierPath* path = [UIBezierPath bezierPath];
    CGFloat begin = 0;
    CGFloat borderStart = borderHeight;
    CGFloat end = borderHeight+tipSize.height;
    if(bottom) {
        begin = r.size.height;
        borderStart = begin - borderHeight;
        end = r.size.height-borderHeight-tipSize.height;
    }
    if(topCap) {
        [path moveToPoint:CGPointMake(0, begin)];
        [path addLineToPoint:CGPointMake(r.size.width, begin)];
        [path addLineToPoint:CGPointMake(r.size.width, borderStart)];
    } else {
        [path moveToPoint:CGPointMake(r.size.width, borderStart)];
    }
    [path addLineToPoint:CGPointMake(.5*(r.size.width+tipSize.width), borderStart)];
    [path addCurveToPoint:CGPointMake(r.size.width*.5f, end) controlPoint1:CGPointMake(rc, borderStart) controlPoint2:CGPointMake(rc, end)];
    [path addCurveToPoint:CGPointMake(.5*(r.size.width-tipSize.width), borderStart) controlPoint1:CGPointMake(lc, end) controlPoint2:CGPointMake(lc, borderStart)];
    
    [path addLineToPoint:CGPointMake(0, borderStart)];
    if(topCap) [path addLineToPoint:CGPointMake(0, begin)];
    return path;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGRect r = self.bounds;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    /*CGContextSetBlendMode(ctx, kCGBlendModeCopy);
     CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
     CGContextFillRect(ctx, r);
     CGContextSetBlendMode(ctx, kCGBlendModeNormal);*/
    //UIBezierPath* path = [[[UIBezierPath alloc] init] autorelease];
    //CGContextSetFillColorWithColor(ctx, [UIColor blueColor].CGColor);
    //CGContextFillRect(ctx, CGRectMake((r.size.width-tipSize.width)*.5f, borderHeight, tipSize.width, tipSize.height));
    CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
    UIBezierPath* path = [self drawerPathWithTopCap:YES];
    [self.layer setShadowPath:[path CGPath]];
    [path addClip];
    CGGradientRef grad = [self newFill];
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(0, 0), CGPointMake(0, borderHeight+tipSize.height), 0);
    CGGradientRelease(grad);
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0 alpha:1].CGColor);
    
    path = [self drawerPathWithTopCap:NO];
    [path stroke];
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1 alpha:0.4].CGColor);
    if(bottom) {
        CGContextTranslateCTM(ctx, 0, 1);
        [path stroke];
        CGContextTranslateCTM(ctx, 0, -1);
    } else {
        CGPoint wline[] = {
            CGPointMake(0, bottom?(r.size.height-1):0),
            CGPointMake(r.size.width, bottom?(r.size.height-1):0)
        };    
        CGContextStrokeLineSegments(ctx, wline, 2);
    }
    path = [UIBezierPath bezierPath];
    
    CGFloat h1 = borderHeight+tipSize.height*.25f, h2 = borderHeight+tipSize.height*.75f;
    if(bottom) {
        CGFloat t = h1-borderHeight;
        h1 = h2-borderHeight;
        h2 = t;
    }
    [path moveToPoint:CGPointMake((r.size.width-30)*.5f, h1)];
    [path addLineToPoint:CGPointMake((r.size.width+30)*.5f, h1)];
    [path addLineToPoint:CGPointMake(r.size.width*.5f, h2)];
    [path addLineToPoint:CGPointMake((r.size.width-30)*.5f, h1)];
    
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    [path fill];
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0 alpha:0.24].CGColor);
    CGPoint line[] = {
        CGPointMake((r.size.width-30)*.5f, h1+(bottom?.5f:-.5f)),
        CGPointMake((r.size.width+30)*.5f, h1+(bottom?.5f:-.5f))
    };
    CGContextStrokeLineSegments(ctx, line, 2);
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0 alpha:0.8].CGColor);
    line[0] = CGPointMake(0, (bottom?(borderHeight+tipSize.height):0));
    line[1] = CGPointMake(r.size.width, (bottom?(borderHeight+tipSize.height):0));
    
    /*CGContextMoveToPoint(ctx, 0, 0);
     CGContextAddLineToPoint(ctx, r.size.width, 0);
     CGContextAddLineToPoint(ctx, r.size.width, borderHeight);
     CGContextAddLineToPoint(ctx, .5*(r.size.width+tipSize.width), borderHeight);
     
     
     CGContextAddCurveToPoint(ctx, rc, borderHeight, rc, borderHeight+tipSize.height, r.size.width*.5f, borderHeight+tipSize.height);
     
     CGContextAddCurveToPoint(ctx, lc, borderHeight+tipSize.height, lc, borderHeight, .5*(r.size.width-tipSize.width), borderHeight);
     
     CGContextAddLineToPoint(ctx, 0, borderHeight);
     CGContextAddLineToPoint(ctx, 0, 0);
     CGContextFillPath(ctx);*/
}

@end