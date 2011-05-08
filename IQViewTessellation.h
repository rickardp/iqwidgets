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

typedef IQPoint3 (^IQViewTesselationTransformation)(CGPoint pt, CGFloat animationPosition);

@class CADisplayLink;
@class EAGLContext;
@class CALayer;

@interface IQViewTessellation : UIView {
    NSUInteger htiles, vtiles, vpw, vph;
    //id *tiles;
    EAGLContext *context;
    UIImage* backgroundImage;
    UIImage* image;
    UIView* backgroundView;
    IQViewTesselationTransformation transformation;
    CGFloat animationPosition;
    CADisplayLink* displayLink;
    unsigned int _fb, _cb, _db, _tex[2];
    float clearColor[4];
    CALayer* innerLayer;
    BOOL doRenderSubviews;
    BOOL hasBackgroundTexture, hasForegroundTexture;
    BOOL needsTextureUpdate, needsBackgroundTextureUpdate;
    float scale;
}

-(id)initWithFrame:(CGRect)frame withTilesHorizontal:(NSUInteger)htiles vertical:(NSUInteger)vtiles;

@property (nonatomic, retain) UIImage* backgroundImage;
@property (nonatomic, retain) UIView* backgroundView;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, copy) IQViewTesselationTransformation transformation;

- (void) startAnimation;
- (void) stopAnimation;

- (void) setNeedsTextureUpdate;

@end
