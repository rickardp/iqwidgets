//
//  IQIconFon.h
//  
//
//  Created by Rickard Lyrenius on 12/06/15.
//
//

#import <UIKit/UIKit.h>

typedef enum IQIconScaleMode {
    IQIconScaleModeAspectFit,
    IQIconScaleModeAspectFill,
    IQIconScaleModeFill
} IQIconScaleMode;

@interface IQIconFont : NSObject

- (instancetype) initWithFont:(NSString*)fontName;
- (instancetype) initWithFontFile:(NSURL*)fontFileURL;
- (instancetype) initWithFontResource:(NSString*)resource;
- (instancetype) initWithFontResource:(NSString*)resource withExtension:(NSString*)extension;
- (CGGlyph) glyphForSymbol:(NSString*)symbol;
- (CGPathRef) pathWithSymbol:(NSString*)symbol size:(CGSize)size scaleMode:(IQIconScaleMode)scaleMode CF_RETURNS_RETAINED;
- (CGPathRef) pathWithGlyph:(CGGlyph)glyph size:(CGSize)size scaleMode:(IQIconScaleMode)scaleMode CF_RETURNS_RETAINED;
- (UIImage*) imageWithSymbol:(NSString*)symbol size:(CGSize)size color:(UIColor*)color scaleMode:(IQIconScaleMode)scaleMode;
@end

@protocol IQIconFontView <NSObject>
@required
@property (nonatomic, retain) NSString* iconSymbol;
@property (nonatomic, retain) NSString* iconFontResource;
@property (nonatomic, retain) NSString* iconFontName;
@end

@interface UIImageView (IQIconFont) <IQIconFontView>
@end

@interface UIButton (IQIconFont) <IQIconFontView>
@end

@interface UITabBarItem (IQIconFont) <IQIconFontView>
@end