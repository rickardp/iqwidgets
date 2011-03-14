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

@interface IQScrollView (PrivateMethods)
- (void) performLayoutAnimated:(BOOL)animated;
@end

@implementation IQScrollView


#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self != nil) {
        backgroundColor = [UIColor whiteColor];
        columnHeaderPlacement = IQHeaderBegin;
        rowHeaderPlacement = IQHeaderBegin;
        [super setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self != nil) {
        backgroundColor = [UIColor whiteColor];
        columnHeaderPlacement = IQHeaderBegin;
        rowHeaderPlacement = IQHeaderBegin;
        [super setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    }
    return self;
}

#pragma mark Disposal

- (void) dealloc
{
    [scrollView release];
    [contentPanel release];
    [rowHeaderView release];
    [columnHeaderView release];
    [cornerView release];
    [backgroundColor release];
    [super dealloc];
}

#pragma mark Drawing

- (void) drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddRect(ctx, self.bounds);
    CGContextSetShadow(ctx, CGSizeMake(0, 0), 20.0f);
}

#pragma mark Properties

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
        [rowHeaderView release];
    }
    rowHeaderView = [rhv retain];
    headerSize.width = rhv.bounds.size.width;
    if(scrollView == nil) [self performLayoutAnimated:NO];
    if(cornerView != nil) {
        [scrollView insertSubview:rhv belowSubview:cornerView];
    } else {
        [scrollView addSubview:rhv];
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
        [columnHeaderView release];
    }
    columnHeaderView = [chv retain];
    headerSize.height = chv.bounds.size.height;
    if(scrollView == nil) [self performLayoutAnimated:NO];
    if(cornerView != nil) {
        [scrollView insertSubview:chv belowSubview:cornerView];
    } else {
        [scrollView addSubview:chv];
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
        [cornerView release];
    }
    cornerView = [cv retain];
    if(scrollView == nil) [self performLayoutAnimated:NO];
    [scrollView addSubview:cornerView];
    [self performLayoutAnimated:NO];
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
    if(scrollView == nil) return self.bounds.size;
    return scrollView.contentSize;
}

- (void) setContentSize:(CGSize)contentSize
{
    if(scrollView == nil) [self performLayoutAnimated:NO];
    scrollView.contentSize = CGSizeMake(contentSize.width + headerSize.width, contentSize.height + headerSize.height);
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
        NSLog(@"Inserting before %@", firstSysView);
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
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.delegate = self;
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
        r.origin.x = headerSize.width;
        r.size.width = scrollView.contentSize.width - headerSize.width;
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
                colhf.origin.y += sz.height - colhf.size.height;
            } else if(columnHeaderPlacement == IQHeaderNone) {
                colhf.size.height = 0;
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
                rowhf.origin.x += sz.width - rowhf.size.width;
            } else if(rowHeaderPlacement == IQHeaderNone) {
                rowhf.size.width = 0;
            }
            rowHeaderView.frame = rowhf;
        }
        if(cornerView != nil) {
            CGRect chf = cornerView.frame;
            chf.size = headerSize;
            if(o.y < 0) {
                chf.origin.y = 0;
            } else if(o.y > sz.height - vsz.height) {
                chf.origin.y = sz.height - vsz.height;
            } else {
                chf.origin.y = o.y;
            }
            if(o.x < 0) {
                chf.origin.x = 0;
            } else if(o.x > sz.width - vsz.width) {
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
        if(vsz.width != ssize.width || vsz.height != ssize.height) {
            ssize = vsz;
            contentPanel.layer.shadowPath = [UIBezierPath bezierPathWithRect:contentPanel.bounds].CGPath;
        }
        contentPanel.frame = contentPanelBounds;
    }
}
@end
