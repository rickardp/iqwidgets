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

@interface IQViewTessellationLayer : CALayer {
@private
    IQViewTessellation* parent;
}
- (id) initWithViewTessellation:(IQViewTessellation*)parent;
@end

@implementation IQViewTessellation
@synthesize transformation;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}
- (void) destroyFramebuffer
{
    [EAGLContext setCurrentContext:context];
    if (_fb) glDeleteFramebuffers(1, &_fb);
    if (_cb) glDeleteRenderbuffers(1, &_cb);
    if (_db) glDeleteRenderbuffers(1, &_db);
    if (_tex) glDeleteTextures(1, &_tex);
    _fb = _cb = _db = _tex = 0;
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
    
    glGenTextures(1, &_tex);
    glBindTexture(GL_TEXTURE_2D, _tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    NSLog(@"Backed by %d x %d", backingWidth, backingHeight);
    
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
        innerLayer = [[CALayer alloc] init];
        innerLayer.frame = frame;
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
        
        /*tiles = calloc(htiles*vtiles, sizeof(id));
        if(!tiles) [NSException raise:@"BadAlloc" format:@"malloc() failed"];
        CGSize tileSize = CGSizeMake(self.bounds.size.width / htiles, self.bounds.size.height / vtiles);
        for(NSUInteger y = 0; y < vtiles; y++) {
            for(NSUInteger x = 0; x < htiles; x++) {
                CALayer* tile = [[IQViewTessellationLayer alloc] initWithViewTessellation:self];
                tiles[x+y*htiles] = tile;
                tile.frame = CGRectMake(x*tileSize.width, y*tileSize.height, tileSize.width, tileSize.height);
                [self.layer addSublayer:tile];
                tile.borderWidth = 1;
            }
        }*/
        animationPosition = 0;
        self.transformation = ^(CGPoint pt, CGFloat a) {
            return IQMakePoint3(pt.x*(1+0.1*sin(5*pt.y+4*M_PI*a)), pt.y, 0.1*sin(5*pt.y+4*M_PI*a));
        };
        [self startAnimation];
    }
    return self;
}

- (void) updateTexture
{
    [EAGLContext setCurrentContext:context];
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	GLubyte *textureData = malloc(vpw * vph * 4);
    GLubyte bytes[4] = {0,0,0,0};
    const CGFloat* cmp = CGColorGetComponents([self.backgroundColor CGColor]);
    if(cmp != nil) {
        for(int i=0;i<4;i++) {
            bytes[i] = cmp[i]*255.0;
            clearColor[i] = cmp[i];   
        }
    }
	memset_pattern4(textureData, bytes, vpw * vph * 4);
	NSUInteger bytesPerPixel = 4;
	NSUInteger bytesPerRow = bytesPerPixel * vpw;
	NSUInteger bitsPerComponent = 8;
	CGContextRef bitmapContext = CGBitmapContextCreate(textureData, vpw, vph, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
    if(backgroundImage != nil) {
        CGContextSaveGState(bitmapContext);
        CGContextTranslateCTM(bitmapContext, 0, vph);
        CGContextScaleCTM(bitmapContext, 1, -1);
        CGContextDrawImage(bitmapContext, CGRectMake(0, 0, vpw, vph), [backgroundImage CGImage]);
        CGContextRestoreGState(bitmapContext);
    }
    if(doRenderSubviews) {
        CGContextScaleCTM(bitmapContext, scale, scale);
        CALayer* l = [[innerLayer sublayers] objectAtIndex:0];
        NSLog(@"Rendering subviews %@ @ %f", l, scale);
        [innerLayer renderInContext:bitmapContext];
    }
	CGContextRelease(bitmapContext);
    
	glBindTexture(GL_TEXTURE_2D, _tex);
    NSLog(@"TexImaging %d to %p  %dx%d", _tex, textureData, vpw, vph);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, vpw, vph, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    
	free(textureData);
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
    [EAGLContext setCurrentContext:context];
    
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
    for(NSUInteger y = 0; y <= vtiles; y++) {
        for(NSUInteger x = 0; x <= htiles; x++) {
            int i = x+y*(htiles+1);
            mesh[i].vertex = self.transformation(CGPointMake(x*tx*2-1, y*ty*2-1), animationPosition);
            if(y>0 && x>0) {
                int left = (x-1)+y*(htiles+1);
                int top = x+(y-1)*(htiles+1);
                mesh[i].normal = IQPoint3CrossProduct(mesh[i].vertex, mesh[left].vertex, mesh[top].vertex);
                GLfloat scl = 1.0/sqrt(mesh[i].normal.x*mesh[i].normal.x+mesh[i].normal.y*mesh[i].normal.y+mesh[i].normal.z*mesh[i].normal.z);
                mesh[i].normal.x *= scl;
                mesh[i].normal.y *= scl;
                mesh[i].normal.z *= scl;
                if(x == 1) mesh[left].normal = mesh[i].normal;
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
    
    
    glEnable(GL_TEXTURE_2D);
	glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glLightfv(GL_LIGHT0, GL_POSITION, (GLfloat[]){0, 5, 5, 0});
    glLightfv(GL_LIGHT0, GL_AMBIENT, (GLfloat[]){1, 1, 1, 1});
    glLightfv(GL_LIGHT0, GL_DIFFUSE, (GLfloat[]){1, 1, 1, 1});
    //glLightfv(GL_LIGHT0, GL_SPECULAR, (GLfloat[]){1, 1, 1, 1});
	glBindTexture(GL_TEXTURE_2D, _tex);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    //glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    
    glVertexPointer(3, GL_FLOAT, sizeof(mesh[0]), &mesh[0].vertex);
    //glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(mesh[0]), &mesh[0].color[0]);
    glTexCoordPointer(2, GL_FLOAT, sizeof(mesh[0]), &mesh[0].texcoord[0]);
    glNormalPointer(GL_FLOAT, sizeof(mesh[0]), &mesh[0].normal);
	glBindTexture(GL_TEXTURE_2D, _tex);
    glDrawElements(GL_TRIANGLES, 6*htiles*vtiles, GL_UNSIGNED_SHORT, indices);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _cb);
    [context presentRenderbuffer:GL_RENDERBUFFER];
    /*for(NSUInteger y = 0; y < vtiles; y++) {
        for(NSUInteger x = 0; x < htiles; x++) {
            CALayer* tile = tiles[x+y*htiles];
            tile.transform = transform;
        }
    }*/
}

- (void) addSubview:(UIView *)view
{
    [super addSubview:view];
    CALayer* l = view.layer;
    [l removeFromSuperlayer];
    [innerLayer addSublayer:l];
    NSLog(@"Adding view");
    doRenderSubviews = YES;
    [self setNeedsDisplay];
}

- (void) setBackgroundImage:(UIImage *)image
{
    UIImage* old = backgroundImage;
    backgroundImage = nil;
    [old release];
    backgroundImage = [image retain];
    [self updateTexture];
    [self setNeedsDisplay];
}

- (UIImage*) backgroundImage
{
    return backgroundImage;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    innerLayer.frame = self.layer.frame;
    [self createFramebuffer];
    [self updateTexture];
}

- (void) display
{
    animationPosition += displayLink.duration;
    while(animationPosition > 1) animationPosition -= 1;
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
    [displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void) setTransformation:(IQViewTesselationTransformation)t
{
    if(transformation) {
        Block_release(transformation);
    }
    transformation = Block_copy(t);
    [self updateMesh];
}

- (void) dealloc
{
    [self stopAnimation];
    [displayLink invalidate];
    
    if(context) {
        [self destroyFramebuffer];
        [context release];
    }
    
    self.transformation = nil;
    [backgroundImage release];
    /*for(NSUInteger i = 0; i < htiles*vtiles; i++) {
        [tiles[i] release];
    }
    free(tiles);*/
}

- (void) drawTile:(CGRect)tileRect inContext:(CGContextRef)ctx
{
   /* CGContextTranslateCTM(ctx, 0, tileRect.size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    CGImageRef tile = CGImageCreateWithImageInRect([texture CGImage], tileRect);    
    CGContextDrawImage(ctx, CGRectMake(0, 0, tileRect.size.width, tileRect.size.height), tile);
    CGImageRelease(tile);*/
}
@end

@implementation IQViewTessellationLayer

- (id) initWithViewTessellation:(IQViewTessellation*)p
{
    self = [super init];
    if(self) {
        parent = p; // Do not need retain
    }
    return self;
}

- (void) drawInContext:(CGContextRef)ctx
{
    [parent drawTile:self.frame inContext:ctx];
}

@end
