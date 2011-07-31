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
typedef void (^IQViewTesselationMeshTransformation)(IQPoint3* mesh, NSUInteger htiles, NSUInteger vtiles, NSUInteger stride, CGFloat animationPosition);

@class CADisplayLink;
@class EAGLContext;
@class CALayer;

@interface IQViewTessellation : UIView {
@protected
    NSUInteger htiles, vtiles;
@private
    NSUInteger vpw, vph;
    //id *tiles;
    EAGLContext *context;
    UIImage* backgroundImage;
    UIImage* image;
    UIView* backgroundView;
    NSTimeInterval animationPosition, prevAnimationPosition;
    IQViewTesselationTransformation transformation;
    IQViewTesselationMeshTransformation meshTransformation;
    NSTimeInterval lastTimestamp;
    CADisplayLink* displayLink;
    unsigned int _fb, _cb, _db, _tex[3];
    float clearColor[4];
    CALayer* innerLayer;
    BOOL doRenderSubviews;
    BOOL hasBackgroundTexture, hasForegroundTexture;
    BOOL needsTextureUpdate, needsBackgroundTextureUpdate;
    UIView* transitionFrom, *transitionTo;
    float scale;
    struct mesh {
        IQPoint3 vertex;
        IQPoint3 normal;
        CGFloat texcoord[2];
        unsigned char color[4];
    } *mesh;
    CGSize viewSize;
    CGFloat viewDepth;
    BOOL viewPerspective;
    BOOL drawShadow;
    IQPoint3 shadow[4];
    CGFloat shadowOpacity;
}

-(id)initWithFrame:(CGRect)frame withTilesHorizontal:(NSUInteger)htiles vertical:(NSUInteger)vtiles;

@property (nonatomic, retain) UIImage* backgroundImage;
@property (nonatomic, retain) UIView* backgroundView;
@property (nonatomic, retain) UIImage* image;

// The view transformation, given as a callback on every data point.
// Note that setting this property to non-nil automatically sets meshTransformation to nil.
@property (nonatomic, retain) IQViewTesselationTransformation transformation;

// The view transformation, operating on the mesh in a single call. This performs slightly better than
// using the transformation property.
// Note that setting this property to non-nil automatically sets transformation to nil.
@property (nonatomic, retain) IQViewTesselationMeshTransformation meshTransformation;

// The opacity for the view shadow (if used). Default is 0.75.
@property (nonatomic) CGFloat shadowOpacity;

// Sets the view shadow coordinates. The shadow must be four vertices, the z-coordinate
// is used to calculate the softness of the shadow.
// Set to NULL to disable shadow.
- (void) setShadow:(IQPoint3*)shadow;

- (void) startAnimation;
- (void) stopAnimation;

- (void) resetMesh;
- (void) display;
- (void) setNeedsTextureUpdate;

// Sets two view references for the background and foreground views. Use this method
// instead of setting backgroundView and adding subviews if the tessellation effect
// is temporary, for example during a transition.
// For transitions, look into IQViewTransition which simplifies the interface.
- (void) setTransitionViewsFrom:(UIView*)fromView to:(UIView*)toView;

// Uses a perspective matrix for the vertex shader or fixed pipeline.
- (void) setPerspective:(CGSize)size depth:(CGFloat)depth;
// Uses an orthographic for the vertex shader or fixed pipeline. This is the default
// (default size is (1,1).
- (void) setOrthographic:(CGSize)size;

- (void) presentFrame;


@end

@interface IQViewTessellation (OverridableMethods)
- (void) updateMesh;
- (void) drawShadow:(IQPoint3*)shadow;
- (void) performMeshUpdateInternal:(struct mesh*)mesh animationPosition:(NSTimeInterval)animationPosition dt:(CGFloat)dt;
@end
