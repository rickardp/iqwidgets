//
//  IQViewTessellation.m
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-04-12.
//  Copyright 2011 EvolvIQ. All rights reserved.
//

#import "IQViewTessellation.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface IQGLLayer : CAEAGLLayer {
@public
    CALayer* innerLayer;
    UIView* owningView;
}
@end

@interface IQViewTessellation ()

- (void) createFramebuffer;
- (void) destroyFramebuffer;

@end

@implementation IQViewTessellation
@synthesize transformation;

+ (Class)layerClass {
    return [IQGLLayer class];
}

- (id) initWithFrame:(CGRect)frame withTilesHorizontal:(NSUInteger)h vertical:(NSUInteger)v
{
    self = [super initWithFrame:frame];
    if(self != nil) {
        htiles = h;
        vtiles = v;
        if(htiles == 0 || htiles > 1000 || vtiles == 0 || vtiles > 1000) [NSException raise:@"InvalidArgument" format:@"Tiles out of range"];
        self.backgroundColor = [UIColor whiteColor];
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        scale = 1;
        
        if([[UIScreen mainScreen] respondsToSelector:
            NSSelectorFromString(@"scale")])
        {
            if([self respondsToSelector:
                NSSelectorFromString(@"contentScaleFactor")])
            {
                scale = [[UIScreen mainScreen] scale];
                self.contentScaleFactor = scale;
                innerLayer.contentsScale = scale;
            }
        }
        [self createFramebuffer];
        
        animationPosition = 0;
        [self startAnimation];
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"dellocing tessellation %p", self);
    [self stopAnimation];
    
    if(context) {
        [self destroyFramebuffer];
        [context release];
        context = nil;
    }
    
    self.transformation = nil;
    [backgroundImage release];
    backgroundImage = nil;
    [image release];
    image = nil;
    [transitionFrom release];
    transitionFrom = nil;
    [transitionTo release];
    transitionTo = nil;
}

- (void) createFramebuffer
{
    [self destroyFramebuffer];
    
    GLint backingWidth, backingHeight;
    // Create default framebuffer object.
    glGenFramebuffers(1, &_fb);
    glBindFramebuffer(GL_FRAMEBUFFER, _fb);
    
    // Create color render buffer and allocate backing store.
    glGenRenderbuffers(1, &_cb);
    glBindRenderbuffer(GL_RENDERBUFFER, _cb);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    vpw = backingWidth;
    vph = backingHeight;
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _cb);
    
    glGenRenderbuffersOES(1, &_db);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _db);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _db);
    
    glGenTextures(2, _tex);
    for(int i=0;i<2;i++){
        glBindTexture(GL_TEXTURE_2D, _tex[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    
    // Setup initial GL state
    glEnable(GL_LIGHT0);
    glEnable(GL_TEXTURE_2D);
    glLightfv(GL_LIGHT0, GL_POSITION, (GLfloat[]){0, 5, 5, 0});
    glLightfv(GL_LIGHT0, GL_AMBIENT, (GLfloat[]){1, 1, 1, 1});
    glLightfv(GL_LIGHT0, GL_DIFFUSE, (GLfloat[]){1, 1, 1, 1});
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, (GLfloat[]){1,1,1,1});
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    //NSLog(@"Backed by %d x %d", backingWidth, backingHeight);
    
}

- (void) destroyFramebuffer
{
    [EAGLContext setCurrentContext:context];
    if (_fb) glDeleteFramebuffers(1, &_fb);
    if (_cb) glDeleteRenderbuffers(1, &_cb);
    if (_db) glDeleteRenderbuffers(1, &_db);
    if (_tex) glDeleteTextures(2, _tex);
    _fb = _cb = _db = _tex[0] = _tex[1] = 0;
}

- (void) updateTexture:(BOOL)updateBackground updateView:(BOOL)updateView;
{
    if(context == nil) return;
    [EAGLContext setCurrentContext:context];
    for(int textureIndex=0; textureIndex<2; textureIndex++) {
        UIImage* img = textureIndex ? backgroundImage : image;
        CALayer* layer = textureIndex ? backgroundView.layer : innerLayer;
        UIView* transitionView = textureIndex ? transitionFrom : transitionTo;
        if(textureIndex && !updateBackground) continue;
        if(!textureIndex && !updateView) continue;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        GLubyte *textureData = malloc(vpw * vph * 4);
        GLubyte bytes[4] = {0,0,0,0};
        if(textureIndex) {
            const CGFloat* cmp = CGColorGetComponents([self.backgroundColor CGColor]);
            if(cmp != nil) {
                for(int i=0;i<4;i++) {
                    bytes[i] = cmp[i]*255.0;
                    clearColor[i] = cmp[i];   
                }
            }
        }
        memset_pattern4(textureData, bytes, vpw * vph * 4);
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * vpw;
        NSUInteger bitsPerComponent = 8;
        CGContextRef bitmapContext = CGBitmapContextCreate(textureData, vpw, vph, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        if(img != nil) {
            CGContextSaveGState(bitmapContext);
            CGContextTranslateCTM(bitmapContext, 0, vph);
            CGContextScaleCTM(bitmapContext, 1, -1);
            CGContextDrawImage(bitmapContext, CGRectMake(0, 0, vpw, vph), [img CGImage]);
            CGContextRestoreGState(bitmapContext);
        }
        if(doRenderSubviews && layer != nil) {
            CGContextScaleCTM(bitmapContext, scale, scale);
            [layer renderInContext:bitmapContext];
        }
        if(transitionView != nil) {
            CGContextScaleCTM(bitmapContext, scale, scale);
            
            BOOL h = transitionView.hidden;
            if(h) transitionView.hidden = NO;
            [transitionView.layer renderInContext:bitmapContext];
            if(h) transitionView.hidden = YES;
        }
        CGContextRelease(bitmapContext);
        /*GLuint* td = (GLuint*)textureData;
        for(int i=0; i<vpw * vph; i++) {
            td[i] = ~td[i] | 0xFF000000;
        }*/
        glBindTexture(GL_TEXTURE_2D, _tex[textureIndex]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, vpw, vph, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
        if(textureIndex) hasBackgroundTexture = YES;
        else hasForegroundTexture = YES;
        free(textureData);
    }
    if(updateView) needsTextureUpdate = NO;
    if(updateBackground) needsBackgroundTextureUpdate = NO;
}
IQPoint3 IQPoint3CrossProduct(IQPoint3 o, IQPoint3 b, IQPoint3 c) {
    IQPoint3 R;
    (R).x = ((b).y-(o).y) * ((c).z-(o).z) - ((c).y-(o).y) * ((b).z-(o).z);
    (R).y = ((b).z-(o).z) * ((c).x-(o).x) - ((c).z-(o).z) * ((b).x-(o).x);
    (R).z = ((b).x-(o).x) * ((c).y-(o).y) - ((c).x-(o).x) * ((b).y-(o).y);
    return R;
}

- (void) updateMesh
{
    if(context == nil) return;
    [EAGLContext setCurrentContext:context];
    
    // Retain self to prevent owner from releasing us in our callback block
    [self retain];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _fb);    
    glViewport(0, 0, vpw, vph);
    
    glClearColor(clearColor[0], clearColor[1], clearColor[2], clearColor[3]);
    glClear(GL_COLOR_BUFFER_BIT);
    
    struct mesh {
        IQPoint3 vertex;
        IQPoint3 normal;
        GLfloat texcoord[2];
        GLubyte color[4];
    } mesh[(htiles+1)*(vtiles+1)];
    CGFloat tx = 1.0/htiles, ty = 1.0/vtiles;
    IQViewTesselationTransformation transformation_ = transformation?Block_copy(transformation):nil;
    for(NSUInteger y = 0; y <= vtiles; y++) {
        for(NSUInteger x = 0; x <= htiles; x++) {
            int i = x+y*(htiles+1);
            if(!transformation) {
                mesh[i].vertex.x = x*tx*2-1;
                mesh[i].vertex.y = y*ty*2-1;
                mesh[i].vertex.z = 0;
            } else {
                mesh[i].vertex = transformation_(CGPointMake(x*tx*2-1, y*ty*2-1), animationPosition);
            }
            if(y>0 && x>0) {
                int left = (x-1)+y*(htiles+1);
                int top = x+(y-1)*(htiles+1);
                mesh[i].normal = IQPoint3CrossProduct(mesh[i].vertex, mesh[left].vertex, mesh[top].vertex);
                GLfloat scl = 1.0/sqrt(mesh[i].normal.x*mesh[i].normal.x+mesh[i].normal.y*mesh[i].normal.y+mesh[i].normal.z*mesh[i].normal.z);
                mesh[i].normal.x *= scl;
                mesh[i].normal.y *= scl;
                mesh[i].normal.z *= scl;
                if(x == 1) {
                    mesh[left].normal = mesh[i].normal;
                    if(y == 1) mesh[(x-1)+(y-1)*(htiles+1)].normal = mesh[i].normal;
                }
                if(y == 1) mesh[top].normal = mesh[i].normal;
            }
            mesh[i].texcoord[0] = x*tx;
            mesh[i].texcoord[1] = y*ty;
            mesh[i].color[0] = 0;
            mesh[i].color[1] = y*255/vtiles;
            mesh[i].color[2] = x*255/htiles;
            mesh[i].color[3] = 1;
        }
    }
    if(transformation_) Block_release(transformation_);
    GLushort indices[6*htiles*vtiles];
    for(NSUInteger y = 0; y < vtiles; y++) {
        for(NSUInteger x = 0; x < htiles; x++) {
            NSUInteger i = 6*(x+y*htiles);
            indices[i] = x+y*(htiles+1);
            indices[i+1] = x+(y+1)*(htiles+1);
            indices[i+2] = (x+1)+y*(htiles+1);
            
            indices[i+3] = (x+1)+y*(htiles+1);
            indices[i+4] = x+(y+1)*(htiles+1);
            indices[i+5] = (x+1)+(y+1)*(htiles+1);
        }
    }
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    static CGFloat vertices[] = {
        -1,-1,  -1,1,  1,1,  1,-1
    };
    static CGFloat texcoords[] = {
        0,0,  0,1,  1,1,  1,0
    };
    
    if(hasBackgroundTexture) {
        glDisable(GL_LIGHTING);
        glDisable(GL_BLEND);
        glBindTexture(GL_TEXTURE_2D, _tex[1]);
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glDisableClientState(GL_NORMAL_ARRAY);
        
        glVertexPointer(2, GL_FLOAT, 0, vertices);
        glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    }
    
    //glLightfv(GL_LIGHT0, GL_SPECULAR, (GLfloat[]){1, 1, 1, 1});
    if(hasForegroundTexture) {
        glEnable(GL_LIGHTING);
        glEnable(GL_BLEND);
        glBindTexture(GL_TEXTURE_2D, _tex[0]);
        
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glEnableClientState(GL_NORMAL_ARRAY);
        
        glVertexPointer(3, GL_FLOAT, sizeof(mesh[0]), &mesh[0].vertex);
        //glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(mesh[0]), &mesh[0].color[0]);
        glTexCoordPointer(2, GL_FLOAT, sizeof(mesh[0]), &mesh[0].texcoord[0]);
        glNormalPointer(GL_FLOAT, sizeof(mesh[0]), &mesh[0].normal);
        //glBindTexture(GL_TEXTURE_2D, _tex);
        glDrawElements(GL_TRIANGLES, 6*htiles*vtiles, GL_UNSIGNED_SHORT, indices);
    }
    glBindRenderbuffer(GL_RENDERBUFFER, _cb);
    [context presentRenderbuffer:GL_RENDERBUFFER];
    [self autorelease];
}

- (void) removeFromSuperview
{
    [self stopAnimation];
    [super removeFromSuperview];
}

- (void) addSubview:(UIView *)view
{
    [super addSubview:view];
    if(innerLayer == nil) {
        IQGLLayer* lay = (id)self.layer;
        lay->owningView = self;
        lay->innerLayer = innerLayer;
        innerLayer = [[CALayer alloc] init];
        innerLayer.frame = self.frame;
    }
    CALayer* l = view.layer;
    [l removeFromSuperlayer];
    [innerLayer addSublayer:l];
    doRenderSubviews = YES;
    needsTextureUpdate = YES;
}

- (void) setBackgroundImage:(UIImage *)img
{
    UIImage* old = backgroundImage;
    backgroundImage = nil;
    [old release];
    backgroundImage = [img retain];
    needsBackgroundTextureUpdate = YES;
}

- (void) setImage:(UIImage *)img
{
    UIImage* old = image;
    image = nil;
    [old release];
    image = [img retain];
    needsTextureUpdate = YES;
}

- (void) setBackgroundView:(UIView *)bgv
{
    UIView* old = backgroundView;
    backgroundView = nil;
    [old removeFromSuperview];
    [old release];
    needsBackgroundTextureUpdate = YES;
}

- (UIImage*) backgroundImage
{
    return backgroundImage;
}

- (UIImage*) image
{
    return image;
}

- (UIView*) backgroundView
{
    return backgroundView;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    innerLayer.frame = self.layer.frame;
    [self createFramebuffer];
    [self updateTexture:YES updateView:YES];
}

- (void) display
{
    NSTimeInterval ts = displayLink.timestamp;
    if(lastTimestamp > 0) {
        animationPosition += (ts - lastTimestamp);
    }
    lastTimestamp = ts;
    if(needsTextureUpdate || needsBackgroundTextureUpdate) {
        // TODO: Investigate if some of this could be done in another thread to minimize lag
        [self updateTexture:needsBackgroundTextureUpdate updateView:needsTextureUpdate];
    }
    if(hasBackgroundTexture || hasForegroundTexture) {
        if(displayLink != nil) {
            [self updateMesh];
        }
    }
}

- (void) presentFrame
{
    [self updateTexture:needsBackgroundTextureUpdate updateView:needsTextureUpdate];
    [self updateMesh];
}

- (void) startAnimation
{
    if(displayLink == nil) {
        displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(display)] retain];
    }
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}
- (void) stopAnimation
{
    if(displayLink != nil) {
        CADisplayLink *dl = displayLink;
        displayLink = nil;
        [dl removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [dl invalidate];
    }
}

- (void) setTransformation:(IQViewTesselationTransformation)t
{
    IQViewTesselationTransformation oldt = transformation;
    if(t != nil) {
        transformation = Block_copy(t);
    } else {
        transformation = nil;
    }
    if(oldt) {
        Block_release(oldt);
    }
    if(displayLink == nil && t != nil) {
        [self updateMesh];
    }
}

- (void) setNeedsTextureUpdate
{
    needsTextureUpdate = YES;
}
- (void) setTransitionViewsFrom:(UIView*)fromView to:(UIView*)toView
{
    [transitionFrom release];
    [transitionTo release];
    transitionFrom = [fromView retain];
    transitionTo = [toView retain];
    needsBackgroundTextureUpdate = needsTextureUpdate = YES;
}

@end

@implementation IQGLLayer

- (CALayer*)hitTest:(CGPoint)p
{
    NSLog(@"Hit test");
    if(innerLayer) {
        return [innerLayer hitTest:p];
    } else return self;
}

@end