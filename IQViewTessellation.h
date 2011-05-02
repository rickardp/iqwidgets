//
//  IQViewTessellation.h
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-04-12.
//  Copyright 2011 EvolvIQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef struct {
    CGFloat x,y,z;
} IQPoint3;

#define IQMakePoint3(x,y,z) ((IQPoint3){(x),(y),(z)})

typedef CGFloat (^IQViewTesselationTransformation)(CGPoint tile, CGSize size, CGFloat animationPosition);

@interface IQViewTessellation : NSObject {
    
}

-(id)initWithFrame:(CGRect)frame withTilesHorizontal:(NSUInteger)htiles vertical:(NSUInteger)vtiles;

@property (nonatomic, retain) IQViewTesselationTransformation transformation;

@end
