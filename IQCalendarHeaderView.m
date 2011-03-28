//
//  IQCalendarHeaderView.h
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

#import "IQCalendarHeaderView.h"
#import <QuartzCore/QuartzCore.h>

NSString* IQLocalizationFormatWeekNumber(int weekNumber)
{
    const char* d = [[[NSLocale currentLocale] localeIdentifier] UTF8String];
    if(d == nil || strlen(d) < 2) d = "en_US";
    if(d[0] == 's' && d[1] == 'v') {
        return [NSString stringWithFormat:@"v%d", weekNumber];
    } else if(d[0] == 'd' && d[1] == 'e') {
        return [NSString stringWithFormat:@"W%d", weekNumber];
    } else {
        return [NSString stringWithFormat:@"w%d", weekNumber];
    }
}

@interface IQArrowView : UIView {
}
@property (nonatomic) BOOL left;
@property (nonatomic, retain) UIColor* shadowColor;
@property (nonatomic) CGSize shadowOffset;
@end

@implementation IQCalendarHeaderView
@synthesize titleLabel, delegate;

#pragma mark Initialization

- (void)setupCalendarHeaderView
{
    CGRect bd = self.bounds;
    border = [[UIView alloc] initWithFrame:CGRectMake(0, bd.size.height-1, bd.size.width, 1)];
    [self addSubview:border];
    border.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    border.backgroundColor = [UIColor blackColor];
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,0,0)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    titleLabel.shadowColor = [UIColor whiteColor];
    titleLabel.shadowOffset = CGSizeMake(0, 1);
    titleLabel.contentMode = UIViewContentModeTop;
    leftArrow = [[IQArrowView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    rightArrow = [[IQArrowView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    leftArrow.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    rightArrow.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.displayArrows = NO;
    ((IQArrowView*)leftArrow).left = YES;
    ((IQArrowView*)rightArrow).left = NO;
    [self addSubview:leftArrow];
    [self addSubview:rightArrow];
    [self addSubview:titleLabel];
    titleFormatter = [[NSDateFormatter alloc] init];
    [titleFormatter setDateFormat:@"MMM"];
    itemFormatter = [[NSDateFormatter alloc] init];
    [itemFormatter setDateFormat:@"D"];
    cornerFormatter = [[NSDateFormatter alloc] init];
    [cornerFormatter setDateFormat:@"YYYY"];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupCalendarHeaderView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupCalendarHeaderView];
    }
    return self;
}

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

#pragma mark Disposal

- (void)dealloc
{
    [startDate release];
    [itemFormatter release];
    [titleFormatter release];
    [cornerFormatter release];
    [titleLabel release];
    for(int i = 0; i < 16; i++) {
        [itemLabels[i] release];
    }
    [leftArrow release];
    [rightArrow release];
    [border release];
    [super dealloc];
}

#pragma mark Layout

- (void)updateLabels
{
    for(int i=0; i < 16; i++) {
        if(i < numItems) {
            if(itemLabels[i] == nil) {
                itemLabels[i] = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                [self addSubview:itemLabels[i]];
                itemLabels[i].textAlignment = UITextAlignmentCenter;                
                itemLabels[i].contentMode = UIViewContentModeBottom;
                itemLabels[i].font = [UIFont boldSystemFontOfSize:10];
                itemLabels[i].shadowOffset = CGSizeMake(0, 1);
                itemLabels[i].shadowColor = [UIColor whiteColor];
                itemLabels[i].backgroundColor = [UIColor clearColor];
            }
            itemLabels[i].hidden = NO;
            itemLabels[i].text = [itemFormatter stringFromDate:[startDate dateByAddingTimeInterval:items[i].timeOffset]];
        } else {
            itemLabels[i].hidden = YES;
        }
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    CGRect r = self.bounds;
    CGSize textSize = [@"Gg" sizeWithFont:titleLabel.font constrainedToSize:CGSizeMake(1000, 1000) lineBreakMode:UILineBreakModeClip];
    if(displayArrows) {
        leftArrow.frame = CGRectMake(0, 0, r.size.height, r.size.height);
        rightArrow.frame = CGRectMake(r.size.width-r.size.height, 0, r.size.height, r.size.height);
        titleLabel.frame = CGRectMake(r.size.height, 5, r.size.width-2*r.size.height, textSize.height);
    } else {
        titleLabel.frame = CGRectMake(0, 5, r.size.width, textSize.height);
    }
    for(int i=0; i < numItems; i++) {
        itemLabels[i].frame = CGRectMake(round(i*r.size.width/numItems), r.size.height-20, round(r.size.width/numItems), 20);
    }
}

#pragma mark Initialization

- (void)setTintColor:(UIColor *)tintColor
{
    CAGradientLayer* layer = (CAGradientLayer*)self.layer;
    const CGFloat* cmpnts = CGColorGetComponents([tintColor CGColor]);
    if(cmpnts == nil) {
        static const CGFloat black[] = {0,0,0,1};
        cmpnts = black;
    }
    CGFloat colors[] = {
        cmpnts[0]+.16, cmpnts[1]+.16, cmpnts[2]+.16, 1,
        cmpnts[0], cmpnts[1], cmpnts[2], 1,
        cmpnts[0]-.12, cmpnts[1]-.12, cmpnts[2]-.12, 1,
    };
    layer.colors = [NSArray arrayWithObjects:(id)CGColorCreate(CGColorGetColorSpace([tintColor CGColor]), colors), (id)CGColorCreate(CGColorGetColorSpace([tintColor CGColor]), colors+4), nil];
    border.backgroundColor = [UIColor colorWithRed:colors[8] green:colors[9] blue:colors[10] alpha:1];
}

- (void)setTitleCalendarUnits:(NSCalendarUnit)units
{
    titleCalendarUnits = units;
    if(units & NSYearCalendarUnit) {
        if(units & NSMonthCalendarUnit) {
            [titleFormatter setDateFormat:@"MMMM yyyy"];
        } else {
            [titleFormatter setDateFormat:@"yyyy"];
        }
    } else if(units & NSMonthCalendarUnit) {
        [titleFormatter setDateFormat:@"MMMM"];        
    }
    [self updateLabels];
}
- (void)setCornerCalendarUnits:(NSCalendarUnit)units
{
    titleCalendarUnits = units;
    if(units & NSYearCalendarUnit) {
        if(units & NSMonthCalendarUnit) {
            [cornerFormatter setDateFormat:@"MMMM yyyy"];
        } else {
            [cornerFormatter setDateFormat:@"yyyy"];
        }
    } else if(units & NSMonthCalendarUnit) {
        [cornerFormatter setDateFormat:@"MMMM"];        
    }
    [self updateLabels];
}
- (void)setItemCalendarUnits:(NSCalendarUnit)units
{
    itemCalendarUnits = units;
    if(units & NSDayCalendarUnit) {
        if(units & NSWeekdayCalendarUnit) {
            [itemFormatter setDateFormat:@"EEE d"];
        } else {
            [itemFormatter setDateFormat:@"d"];
        }
    } else if(units & NSWeekdayCalendarUnit) {
        [itemFormatter setDateFormat:@"EEE"];
    } else if(units & NSWeekCalendarUnit) {
        [itemFormatter setDateFormat:@"w"];
    }
    [self updateLabels];
}
- (void)setItems:(const IQCalendarHeaderItem*)newItems count:(NSUInteger)count cornerWidth:(CGFloat)cornerWidth startTime:(NSDate*)time titleOffset:(NSTimeInterval)offset animated:(BOOL)animated
{
    titleLabel.text = [titleFormatter stringFromDate:[time dateByAddingTimeInterval:offset]];
    if(count > 16) count = 16;
    memcpy(items, newItems, count * sizeof(IQCalendarHeaderItem));
    numItems = count;
    [startDate release];
    startDate = [time copy];
    [self updateLabels];
}

- (void)didTapNextPrev:(UIView*)np
{
    if([delegate respondsToSelector:@selector(headerView:didReceiveInteraction:)]) {
        if(np == leftArrow) {
            [delegate headerView:self didReceiveInteraction:IQCalendarHeaderViewUserInteractionPrev];
        } else if(np == rightArrow) {
            [delegate headerView:self didReceiveInteraction:IQCalendarHeaderViewUserInteractionNext];
        }
    }
}

#pragma mark Appearance

- (BOOL)displayArrows
{
    return displayArrows;
}

- (void)setDisplayArrows:(BOOL)value
{
    displayArrows = value;
    leftArrow.hidden = !value;
    rightArrow.hidden = !value;
}

- (UIColor*)textColor
{
    return textColor;
}

- (void)setTextColor:(UIColor *)value
{
    [textColor release];
    textColor = [value retain];
    titleLabel.textColor = value;
    for(int i = 0; i < 16; i++) {
        itemLabels[i].textColor = value;
    }
}

- (UIColor*)shadowColor
{
    return titleLabel.shadowColor;
}

- (void)setShadowColor:(UIColor *)value
{
    titleLabel.shadowColor = value;
    for(int i = 0; i < 16; i++) {
        itemLabels[i].shadowColor = value;
    }
    ((IQArrowView*)leftArrow).shadowColor = value;
    ((IQArrowView*)rightArrow).shadowColor = value;
    [leftArrow setNeedsDisplay];
    [rightArrow setNeedsDisplay];
}

- (CGSize)shadowOffset
{
    return titleLabel.shadowOffset;
}

- (void)setShadowOffset:(CGSize)value
{
    titleLabel.shadowOffset = value;
    for(int i = 0; i < 16; i++) {
        itemLabels[i].shadowOffset = value;
    }
    ((IQArrowView*)leftArrow).shadowOffset = value;
    ((IQArrowView*)rightArrow).shadowOffset = value;
    [leftArrow setNeedsDisplay];
    [rightArrow setNeedsDisplay];
}

@end

@implementation IQArrowView
@synthesize left, shadowOffset, shadowColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        self.contentMode = UIViewContentModeRedraw;
        self.opaque = NO;
    }
    return self;
}
- (void)dealloc
      {
          self.shadowColor = nil;
          [super dealloc];
      }
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect bnds = self.bounds;
    CGFloat height = round(MAX(bnds.size.width, bnds.size.height) / 3.0);
    CGFloat width = height / sqrtf(2.0f);
    CGFloat dy = 0;
    dy -= 6;
    if(!left) width = -width;
    CGContextMoveToPoint(ctx, round((bnds.size.width-width)*.5)+.5, dy+round(bnds.size.height * .5)+.5);
    CGContextAddLineToPoint(ctx, round((bnds.size.width+width)*.5)+.5, dy+round((bnds.size.height-height) * .5)+.5);
    CGContextAddLineToPoint(ctx, round((bnds.size.width+width)*.5)+.5, dy+round((bnds.size.height+height) * .5)+.5);
    if([self.superview respondsToSelector:@selector(textColor)]) {
        CGContextSetFillColorWithColor(ctx, [[(id)self.superview textColor] CGColor]);
    }
    CGContextSetShadowWithColor(ctx, shadowOffset, 0, [shadowColor CGColor]);
    CGContextFillPath(ctx);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touches.count == 1) {
        if([self.superview respondsToSelector:@selector(didTapNextPrev:)]) {
            [(id)self.superview didTapNextPrev:self];
        }
    }
}
@end