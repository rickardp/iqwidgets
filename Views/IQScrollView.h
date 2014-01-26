//
//  IQScrollView.h
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

typedef enum _IQHeaderPlacement
{
    IQHeaderNone,
    IQHeaderBegin,
    IQHeaderEnd
} IQHeaderPlacement;

@interface IQScrollView : UIView<UIScrollViewDelegate> {
    IQHeaderPlacement rowHeaderPlacement;
    IQHeaderPlacement columnHeaderPlacement;
    BOOL borderShadows;
    BOOL scrollIndicatorsFollowContent;
    UIScrollView* scrollView;
    UIView* contentPanel;
    UIView* rowHeaderView;
    UIView* columnHeaderView;
    UIView* cornerView;
    UIColor* backgroundColor;
    CGSize ssize;
    CGSize headerSize;
    CGSize contentSize;
    BOOL alwaysBounceHorizontal, alwaysBounceVertical;
}

@property (nonatomic) BOOL borderShadows;

// If YES, scroll indicators stay within the content view. If NO, scroll indicators
// occupy the full area of the IQScrollView. Default is YES.
@property (nonatomic) BOOL scrollIndicatorsFollowContent;

@property (nonatomic) IQHeaderPlacement rowHeaderPlacement;
@property (nonatomic) IQHeaderPlacement columnHeaderPlacement;
@property (nonatomic, retain) UIView* rowHeaderView;
@property (nonatomic, retain) UIView* columnHeaderView;
@property (nonatomic, retain) UIView* cornerView;
@property (nonatomic) CGPoint contentOffset;
@property (nonatomic) CGSize contentSize;
@property (nonatomic) BOOL alwaysBounceHorizontal;
@property (nonatomic) BOOL alwaysBounceVertical;
@property (nonatomic, getter=isDirectionalLockEnabled) BOOL directionalLockEnabled;

- (void)flashScrollbarIndicators;

@end
