//
//  IQIconFon.m
//
//
//  Created by Rickard Lyrenius on 12/06/15.
//
//

#import "IQIconFont.h"
#import <CoreText/CoreText.h>
#import <objc/runtime.h>

@interface _IQIconFontObserver : NSObject
@end

@interface IQIconFont() {
    CGFontRef font;
    CTFontRef textFont;
}
@end

@protocol IQIconFontPrivate
@optional
- (NSArray*) _propertiesAffectingIcon;
- (void) _updateIconFontIcon;
@end

@interface NSObject (IconFontData)
@property (nonatomic, strong) NSString* iconFontResource;
@property (nonatomic, strong) NSString* iconFontName;
@property (nonatomic, strong) NSString* iconSymbol;
@end

@implementation IQIconFont
- (instancetype) initWithFont:(NSString*)fontName {
    if(fontName == nil) return nil;
    CGFontRef f = CGFontCreateWithFontName((CFStringRef)fontName);
    NSLog(@"%@", f);
    if(!f) return nil;

    if(self = [super init]) {
        font = f;
    }
    return self;
}

- (instancetype) initWithFontFile:(NSURL*)fontFileURL {
    if(fontFileURL == nil) return nil;
    CGDataProviderRef data = CGDataProviderCreateWithURL((CFURLRef)fontFileURL);
    CGFontRef f = CGFontCreateWithDataProvider(data);
    CGDataProviderRelease(data);
    if(!f) return nil;
    if(self = [super init]) {
        font = f;
    }
    return self;
}

- (instancetype) initWithFontResource:(NSString*)resource {
    NSString* fn = [resource stringByDeletingPathExtension];
    NSString* ext = [resource pathExtension];
    if(ext.length == 0) ext = nil;
    return [self initWithFontResource:fn withExtension:ext];
}

- (instancetype) initWithFontResource:(NSString*)resource withExtension:(NSString*)extension {
    if(extension == nil) extension = @"otf";
    return [self initWithFontFile:[[NSBundle mainBundle] URLForResource:resource withExtension:extension]];
}

- (void) dealloc {
    if(font) CGFontRelease(font);
    font = NULL;
    if(textFont) CFRelease(textFont);
    textFont = NULL;
}

- (CGPathRef) pathWithSymbol:(NSString*)symbol size:(CGSize)size scaleMode:(IQIconScaleMode)scaleMode {
    return [self pathWithGlyph:[self glyphForSymbol:symbol] size:size scaleMode:scaleMode];
}

- (CGPathRef) pathWithGlyph:(CGGlyph)glyph size:(CGSize)size scaleMode:(IQIconScaleMode)scaleMode {
    if(!textFont) {
        textFont = CTFontCreateWithGraphicsFont(font, 0, NULL, NULL);
    }
    if(!textFont) return 0;

    if(!glyph) return NULL;
    CGRect rect;
    CTFontGetBoundingRectsForGlyphs(textFont, kCTFontOrientationDefault, &glyph, &rect, 1);
    CGFloat dw = size.width / rect.size.width, dh = size.height / rect.size.height;
    switch(scaleMode) {
        case IQIconScaleModeAspectFill:
            dw = dh = dw < dh ? dh : dw;
            break;

        case IQIconScaleModeFill:
            break;

        case IQIconScaleModeAspectFit:
        default:
            dw = dh = dw > dh ? dh : dw;
            break;
    }
    CGAffineTransform t = CGAffineTransformMakeTranslation(-rect.origin.x, -rect.origin.y);
    t = CGAffineTransformScale(t, dw, dh);
    return CTFontCreatePathForGlyph(textFont, glyph, &t);
}

- (CGGlyph) glyphForSymbol:(NSString*)symbol {
    if(!symbol) return 0;
    if(!textFont) {
        textFont = CTFontCreateWithGraphicsFont(font, 0, NULL, NULL);
    }
    if(!textFont) return 0;

    int uniHexOffset = 0;
    if(symbol.length > 2 && [[symbol substringToIndex:2] isEqualToString:@"0x"]) {
        uniHexOffset = 2;

    } else if(symbol.length > 3 && [[symbol substringToIndex:3] isEqualToString:@"&#x"]) {
        uniHexOffset = 3;
    }
    if (uniHexOffset > 0) {
        // Unicode sequence
        NSScanner *scan = [NSScanner scannerWithString:symbol];
        scan.scanLocation = uniHexOffset;
        unsigned int hex;
        [scan scanHexInt:&hex];
        if(hex > 0xffff) {
            NSLog(@"Unicode sequence %ul out of range", hex);
            return 0;
        }
        UniChar c = (UniChar)hex;
        CGGlyph glyph;
        if(!CTFontGetGlyphsForCharacters(textFont, &c, &glyph, 1))
            return 0;
        return glyph;
    } else {
        // Character literal or ligature
        NSDictionary* attrs = @{(NSString*)kCTLigatureAttributeName: @2, (NSString*)kCTFontAttributeName: (__bridge id)textFont};

        NSAttributedString* s = [[NSAttributedString alloc] initWithString:symbol attributes:attrs];
        CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)s);
        if(!line || CTLineGetGlyphCount(line) < 1) {
            NSLog(@"No glyph(s) created from symbol '%@'", symbol);
            return 0;
        }
        CFArrayRef array = CTLineGetGlyphRuns(line);
        CGGlyph glyph = 0;

        if(CFArrayGetCount(array) > 0) {
            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(array, 0);
            if(CTRunGetGlyphCount(run) > 0) {
                CTRunGetGlyphs(run, CFRangeMake(0, 1), &glyph);
            }
        }
        CFRelease(line);
        return glyph;
    }
}

- (UIImage*) imageWithSymbol:(NSString*)symbol size:(CGSize)size color:(UIColor*)color scaleMode:(IQIconScaleMode)scaleMode {
    CGPathRef path = [self pathWithSymbol:symbol size:size scaleMode:scaleMode];
    if(!path) return NULL;
    CGRect rect = CGPathGetBoundingBox(path);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(ctx, color.CGColor);
    //CGContextFillRect(ctx, CGRectMake(0, 0, 10000, 10000));

    CGContextTranslateCTM(ctx, rect.origin.x, rect.size.height + rect.origin.y);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextAddPath(ctx, path);
    //CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
    //CGContextSetBlendMode(ctx, kCGBlendModeCopy);
    CGContextFillPath(ctx);

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGPathRelease(path);
    return image;
}
@end

@implementation NSObject (IconFontData)

- (void) setIconFontResource:(NSString *)iconFontResource {
    objc_setAssociatedObject(self, @selector(iconFontResource), iconFontResource, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if(iconFontResource && [self respondsToSelector:@selector(_updateIconFontIcon)]) {
        [(id)self _updateIconFontIcon];
    }
}

- (NSString*) iconFontResource {
    return (NSString*)objc_getAssociatedObject(self, @selector(iconFontResource));
}

- (void) setIconFontName:(NSString *)iconFontName {
    if(iconFontName) self.iconFontResource = nil;
    objc_setAssociatedObject(self, @selector(iconFontName), iconFontName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if(iconFontName && [self respondsToSelector:@selector(_updateIconFontIcon)]) {
        [(id)self _updateIconFontIcon];
    }
}

- (NSString*) iconFontName {
    return (NSString*)objc_getAssociatedObject(self, @selector(iconFontName));
}

- (void) _registerIconFontNotifications {
    if(!objc_getAssociatedObject(self, @selector(_registerIconFontNotifications))) {
        NSArray* props;
        if([self respondsToSelector:@selector(_propertiesAffectingIcon)]) {
            props = [(id)self _propertiesAffectingIcon];
        } else {
            props = @[];
        }
        objc_setAssociatedObject(self, @selector(_registerIconFontNotifications), props, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        _IQIconFontObserver* o = [_IQIconFontObserver new];
        for(NSString* prop in props) {
            [self addObserver:o forKeyPath:prop options:NSKeyValueObservingOptionNew context:NULL];
        }
    }
}

- (void) setIconSymbol:(NSString *)symbol {
    objc_setAssociatedObject(self, @selector(iconSymbol), symbol, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if(symbol && [self respondsToSelector:@selector(_updateIconFontIcon)]) {
        [(id)self _updateIconFontIcon];
    }
}

- (NSString*) iconSymbol {
    return (NSString*)objc_getAssociatedObject(self, @selector(iconSymbol));
}
@end

@implementation UIImageView (IQIconFont)

- (void) _updateIconFontIcon {
    if((self.iconFontResource || self.iconFontName) && self.iconSymbol) {
        IQIconFont* font = self.iconFontResource ?
        [[IQIconFont alloc] initWithFontResource:self.iconFontResource]
        : [[IQIconFont alloc] initWithFont:self.iconFontName];
        if(font) {
            IQIconScaleMode mode = IQIconScaleModeAspectFit;
            if(self.contentMode == UIViewContentModeScaleAspectFill) mode = IQIconScaleModeAspectFill;
            else if(self.contentMode == UIViewContentModeScaleToFill) mode = IQIconScaleModeFill;

            self.image = [font imageWithSymbol:self.iconSymbol size:self.bounds.size color:self.tintColor scaleMode:mode];
        }
    }
}

- (NSArray*) _propertiesAffectingIcon {
    return @[@"tintColor"];
}
@end

@implementation UIButton (IQIconFont)
- (void) _updateIconFontIcon {

}

- (NSArray*) _propertiesAffectingIcon {
    return @[@"tintColor"];
}
@end

@implementation UITabBarItem (IQIconFont)
- (void) _updateIconFontIcon {
    if((self.iconFontResource || self.iconFontName) && self.iconSymbol) {
        IQIconFont* font = self.iconFontResource ?
        [[IQIconFont alloc] initWithFontResource:self.iconFontResource]
        : [[IQIconFont alloc] initWithFont:self.iconFontName];
        if(font) {
            self.image = [font imageWithSymbol:self.iconSymbol size:CGSizeMake(25, 25) color:[UIColor blackColor] scaleMode:IQIconScaleModeAspectFit];
        }
    }
}
@end

@implementation _IQIconFontObserver

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([object respondsToSelector:@selector(_updateIconFontIcon)]) {
        [object _updateIconFontIcon];
    }
}

@end