//
//  IQDrawerView.h
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-10-01.
//  Copyright (c) 2011 EvolvIQ. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _IQDrawerViewStyle {
    IQDrawerViewStylePlain,
    IQDrawerViewStyleBarDefault,
    IQDrawerViewStyleBarBlack
} IQDrawerViewStyle;

typedef enum _IQDrawerViewAlign {
    IQDrawerViewAlignTop,
    IQDrawerViewAlignBottom
} IQDrawerViewAlign;

@interface IQDrawerView : UIView {
    IQDrawerViewStyle style;
    CGFloat contentHeight, borderHeight;
    CGSize tipSize;
    BOOL bottom;
    BOOL expanded;
}

- (id) initWithStyle:(IQDrawerViewStyle)style align:(IQDrawerViewAlign)align;

@end
