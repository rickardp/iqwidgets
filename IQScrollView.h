//
//  IQScrollView.h
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-03-14.
//  Copyright 2011 Jeppesen. All rights reserved.
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
    UIScrollView* scrollView;
    UIView* contentPanel;
    UIView* rowHeaderView;
    UIView* columnHeaderView;
    UIView* cornerView;
    UIColor* backgroundColor;
    CGSize ssize;
    CGSize headerSize;
}

@property (nonatomic) BOOL borderShadows;
@property (nonatomic) IQHeaderPlacement rowHeaderPlacement;
@property (nonatomic) IQHeaderPlacement columnHeaderPlacement;
@property (nonatomic, retain) UIView* rowHeaderView;
@property (nonatomic, retain) UIView* columnHeaderView;
@property (nonatomic, retain) UIView* cornerView;
@property (nonatomic) CGPoint contentOffset;
@property (nonatomic) CGSize contentSize;

@end
