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

#import <UIKit/UIKit.h>

typedef struct _IQCalendarHeaderItem {
    CGFloat x;
    CGFloat width;
    NSTimeInterval timeOffset;
} IQCalendarHeaderItem;

// Common interface for headers for IQScheduleView and IQCalendarView
@protocol IQCalendarHeaderDelegate <NSObject>
@optional
- (void)setTintColor:(UIColor*)tintColor;
- (void)setTextColor:(UIColor*)textColor;

- (void)setTitleCalendarUnits:(NSCalendarUnit)units;
- (void)setCornerCalendarUnits:(NSCalendarUnit)units;
- (void)setItemCalendarUnits:(NSCalendarUnit)units;
- (void)setItems:(const IQCalendarHeaderItem*)items count:(NSUInteger)count cornerWidth:(CGFloat)cornerWidth startTime:(NSDate*)time animated:(BOOL)animated;
@end

@interface IQCalendarHeaderView : UIView<IQCalendarHeaderDelegate> {
    NSCalendarUnit titleCalendarUnits;
    NSCalendarUnit cornerCalendarUnits;
    NSCalendarUnit itemCalendarUnits;
    IQCalendarHeaderItem items[16];
    NSUInteger numItems;
    UIView* border;
    UILabel* titleLabel;
}

@property (nonatomic, readonly) UILabel* titleLabel;

@end
