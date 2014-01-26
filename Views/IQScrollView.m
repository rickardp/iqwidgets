//
//  IQScrollView.m
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
#import <QuartzCore/QuartzCore.h>

@interface IQScrollView ()
- (void) performLayoutAnimated:(BOOL)animated;
@end

@implementation IQScrollView
@synthesize scrollIndicatorsFollowContent;


#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self != nil) {
        scrollIndicatorsFollowContent = YES;
        backgroundColor = [UIColor whiteColor];
        columnHeaderPlacement = IQHeaderBegin;
        rowHeaderPlacement = IQHeaderBegin;
        alwaysBounceVertical = alwaysBounceHorizontal = YES;
        [super setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self != nil) {
        scrollIndicatorsFollowContent = YES;
        backgroundColor = [UIColor whiteColor];
        columnHeaderPlacement = IQHeaderBegin;
        rowHeaderPlacement = IQHeaderBegin;
        alwaysBounceVertical = alwaysBounceHorizontal = YES;
        [super setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    }
    return self;
}

#pragma mark Drawing

- (void) drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddRect(ctx, self.bounds);
    CGContextSetShadow(ctx, CGSizeMake(0, 0), 20.0f);
}

#pragma mark Properties

- (BOOL)alwaysBounceHorizontal
{
    return [scrollView alwaysBounceHorizontal];
}

- (void)setAlwaysBounceHorizontal:(BOOL)a
{
    alwaysBounceHorizontal = a;
    [scrollView setAlwaysBounceHorizontal:alwaysBounceHorizontal];
}

- (BOOL)alwaysBounceVertical
{
    return [scrollView alwaysBounceVertical];
}

- (void)setAlwaysBounceVertical:(BOOL)a
{
    alwaysBounceVertical = a;
    [scrollView setAlwaysBounceVertical:alwaysBounceVertical];
}

- (BOOL)isDirectionalLockEnabled
{
    return [scrollView isDirectionalLockEnabled];
}

- (void)setDirectionalLockEnabled:(BOOL)directionalLockEnabled
{
    [scrollView setDirectionalLockEnabled:directionalLockEnabled];
}

- (BOOL)borderShadows
{
    return borderShadows;
}

- (void) setBorderShadows:(BOOL)bs
{
    borderShadows = bs;
    // TODO:
}

- (IQHeaderPlacement)rowHeaderPlacement
{
    return rowHeaderPlacement;
}

- (void)setRowHeaderPlacement:(IQHeaderPlacement)rhp
{
    rowHeaderPlacement = rhp;
    [self performLayoutAnimated:NO];
}

- (IQHeaderPlacement)columnHeaderPlacement
{
    return columnHeaderPlacement;
}

- (void)setColumnHeaderPlacement:(IQHeaderPlacement)chp
{
    columnHeaderPlacement = chp;
    [self performLayoutAnimated:NO];
}

- (UIView*) rowHeaderView
{
    return rowHeaderView;
}

- (void) setRowHeaderView:(UIView *)rhv
{
    if(rowHeaderView != nil) {
        [rowHeaderView removeFromSuperview];
    }
    rowHeaderView = rhv;
    if(rhv) {
        headerSize.width = rhv.bounds.size.width;
        if(scrollView == nil) [self performLayoutAnimated:NO];
        if(cornerView != nil) {
            [scrollView insertSubview:rhv belowSubview:cornerView];
        } else {
            [scrollView addSubview:rhv];
        }
    }
    [self performLayoutAnimated:NO];
}

- (UIView*) columnHeaderView
{
    return columnHeaderView;
}

- (void) setColumnHeaderView:(UIView *)chv
{
    if(columnHeaderView != nil) {
        [columnHeaderView removeFromSuperview];
    }
    columnHeaderView = chv;
    if(chv) {
        headerSize.height = chv.bounds.size.height;
        if(scrollView == nil) [self performLayoutAnimated:NO];
        if(cornerView != nil) {
            [scrollView insertSubview:chv belowSubview:cornerView];
        } else {
            [scrollView addSubview:chv];
        }
    }
    [self performLayoutAnimated:NO];
}

- (UIView*) cornerView
{
    return cornerView;
}

- (void) setCornerView:(UIView *)cv
{
    if(cornerView != nil) {
        [cornerView removeFromSuperview];
    }
    cornerView = cv;
    if(cv) {
        if(scrollView == nil) [self performLayoutAnimated:NO];
        [scrollView addSubview:cornerView];
    }
    [self performLayoutAnimated:NO];
}

- (UIColor*)backgroundColor
{
    return backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)bg
{
    [contentPanel setBackgroundColor:bg];
    backgroundColor = bg;
}

- (CGPoint) contentOffset
{
    if(scrollView == nil) return CGPointMake(0, 0);
    return scrollView.contentOffset;
}

- (void) setContentOffset:(CGPoint)contentOffset
{
    if(scrollView == nil) [self performLayoutAnimated:NO];
    scrollView.contentOffset = contentOffset;
}

- (CGSize) contentSize
{
    return contentSize;
}

- (void) setContentSize:(CGSize)csz
{
    contentSize = csz;
    if(scrollView == nil) [self performLayoutAnimated:NO];
    CGSize innerSize = CGSizeMake(contentSize.width + headerSize.width, contentSize.height + headerSize.height);
    CGSize bsize = self.bounds.size;
    if(innerSize.width < bsize.width) innerSize.width = bsize.width;
    if(innerSize.height < bsize.height) innerSize.height = bsize.height;
    scrollView.contentSize = innerSize;
}

- (void)flashScrollbarIndicators
{
    [scrollView flashScrollIndicators];
}

#pragma mark Layout

- (void) addSubview:(UIView *)view
{
    if(scrollView == nil) [self performLayoutAnimated:NO];
    UIView* firstSysView = nil;
    for(UIView* v in scrollView.subviews) {
        if(v == rowHeaderView || v == cornerView || v == columnHeaderView) {
            firstSysView = v;
            break;
        }
    };
    view.center = CGPointMake(view.center.x + headerSize.width, view.center.y + headerSize.height);
    if(firstSysView != nil) {
        [scrollView insertSubview:view belowSubview:firstSysView];
    } else {
        [scrollView addSubview:view];
        
    }
}

- (void) performLayoutAnimated:(BOOL)animated
{
    if(animated) [UIView beginAnimations:nil context:nil];
    if(scrollView == nil) {
        scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        scrollView.bounces = YES;
        scrollView.alwaysBounceHorizontal = alwaysBounceHorizontal;
        scrollView.alwaysBounceVertical = alwaysBounceVertical;
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.delegate = self;
//        scrollView.zooming = YES;
        contentPanel = [[UIView alloc] initWithFrame:self.bounds];
        contentPanel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        contentPanel.layer.shadowOpacity = 0.9;
        contentPanel.layer.shadowRadius = 17.0;
        contentPanel.backgroundColor = backgroundColor;
        contentPanel.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        ssize = self.bounds.size;
        [scrollView addSubview:contentPanel];
        //contentView.frame = CGRectMake(0, sz, self.bounds.size.width, self.bounds.size.height - sz);
        scrollView.scrollEnabled = YES;
        scrollView.backgroundColor = [UIColor clearColor];
        //contentView.directionalLockEnabled = YES;
        [super addSubview:scrollView];
    }
    if(columnHeaderView != nil) {
        CGRect r = columnHeaderView.frame;
        r.origin.x = (cornerView == nil) ? 0 : headerSize.width;
        r.size.width = scrollView.contentSize.width - r.origin.x;
        columnHeaderView.frame = r;
    }
    if(rowHeaderView != nil) {
        CGRect r = rowHeaderView.frame;
        r.origin.y = headerSize.height;
        r.size.height = scrollView.contentSize.height - headerSize.height;
        rowHeaderView.frame = r;
    }
    [self scrollViewDidScroll:scrollView];
    if(animated) [UIView commitAnimations];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.contentSize = self.contentSize;
    [self performLayoutAnimated:NO];
}

#pragma mark Scroll delegate

- (void)scrollViewDidScroll:(UIScrollView *)sv
{
    if(scrollView == sv) {
        CGRect contentPanelBounds = self.bounds;
        CGSize vsz = contentPanelBounds.size;
        CGPoint o = scrollView.contentOffset;
        CGSize sz = scrollView.contentSize;
        UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        
        if(columnHeaderView != nil) {
            CGRect colhf = columnHeaderView.frame;
            colhf.size.height = headerSize.height;
            if(o.y < 0) {
                colhf.origin.y = 0;
            } else if(o.y > sz.height - vsz.height) {
                colhf.origin.y = sz.height - vsz.height;
            } else {
                colhf.origin.y = o.y;
            }
            if(columnHeaderPlacement == IQHeaderEnd) {
                scrollIndicatorInsets.bottom += colhf.size.height;
                colhf.origin.y += sz.height - colhf.size.height;
            } else if(columnHeaderPlacement == IQHeaderNone) {
                colhf.size.height = 0;
            } else {
                scrollIndicatorInsets.top += colhf.size.height;
            }
            columnHeaderView.frame = colhf;
        }
        if(rowHeaderView != nil) {
            CGRect rowhf = rowHeaderView.frame;
            rowhf.size.width = headerSize.width;
            if(o.x < 0) {
                rowhf.origin.x = 0;
            } else if(o.x > sz.width - vsz.width) {
                rowhf.origin.x = sz.width - vsz.width;
            } else {
                rowhf.origin.x = o.x;
            }
            if(rowHeaderPlacement == IQHeaderEnd) {
                scrollIndicatorInsets.right += rowhf.size.width;
                rowhf.origin.x += sz.width - rowhf.size.width;
            } else if(rowHeaderPlacement == IQHeaderNone) {
                rowhf.size.width = 0;
            } else {
                scrollIndicatorInsets.left += rowhf.size.width;
            }
            rowHeaderView.frame = rowhf;
        }
        if(cornerView != nil) {
            CGRect chf = cornerView.frame;
            chf.size = headerSize;
            if(o.y < 0) {
                scrollIndicatorInsets.top -= o.y;
                chf.origin.y = 0;
            } else if(o.y > sz.height - vsz.height) {
                scrollIndicatorInsets.bottom -= sz.height - vsz.height - o.y;
                chf.origin.y = sz.height - vsz.height;
            } else {
                chf.origin.y = o.y;
            }
            if(o.x < 0) {
                scrollIndicatorInsets.left -= o.x;
                chf.origin.x = 0;
            } else if(o.x > sz.width - vsz.width) {
                scrollIndicatorInsets.right -= sz.width - vsz.width - o.x;
                chf.origin.x = sz.width - vsz.width;
            } else {
                chf.origin.x = o.x;
            }
            cornerView.frame = chf;
        }
        if(o.y < 0) {
            contentPanelBounds.origin.y = 0;
        } else if(o.y > sz.height - vsz.height) {
            contentPanelBounds.origin.y = sz.height - vsz.height;
        } else {
            contentPanelBounds.origin.y = o.y;
        }
        if(o.x < 0) {
            contentPanelBounds.origin.x = 0;
        } else if(o.x > sz.width - vsz.width) {
            contentPanelBounds.origin.x = sz.width - vsz.width;
        } else {
            contentPanelBounds.origin.x = o.x;
        }
        if(scrollIndicatorsFollowContent) {
            [scrollView setScrollIndicatorInsets:scrollIndicatorInsets];
        }
        if(vsz.width != ssize.width || vsz.height != ssize.height) {
            ssize = vsz;
            contentPanel.layer.shadowPath = [UIBezierPath bezierPathWithRect:contentPanel.bounds].CGPath;
        }
        contentPanel.frame = contentPanelBounds;
    }
}
@end
