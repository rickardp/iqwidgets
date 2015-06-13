//
//  IQTheme.m
//  IQWidgets for iOS
//
//  Copyright 2012 Rickard Petzäll, EvolvIQ
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

#import "IQTheme.h"

NSString* kIQThemeNotificationDefaultThemeChanged = @"IQTheme_DefaultThemeChanged";
NSString* kIQThemeNotificationThemeChanged = @"IQTheme_Changed";

NSArray* _IQMutableTheme_TokenizeCSS(NSString* cssSelector, int* outPos);
float _IQMutableTheme_SizeInPoints(NSString* cssSizeSpec, float refSize);
UIColor* _IQMutableTheme_ParseCssColor(NSString* cssColorSpec);

static IQTheme* _default = nil;

@interface _IQDummyThemeable : NSObject<IQThemeable> {
}
@property (nonatomic, retain) id<IQThemeable> parentThemeable;
@property (nonatomic, retain) NSString* themeElementName;
@property (nonatomic) BOOL defaultInherit;
@end

@interface _IQThemeDeclaration : NSObject {
    NSString* elementName;
    NSSet* classes;
    NSString* uniqueId;
    _IQThemeDeclaration* parent;
}
- (id) initWithElement:(NSString*)e classes:(NSSet*)c uid:(NSString*)u parent:(_IQThemeDeclaration*)p;
- (NSString*) valueString;
- (NSInteger) specificity;
- (NSComparisonResult) compareSpecificity:(id)other;
- (BOOL) matches:(NSString*)elem classes:(NSSet*)classes uid:(NSString*)uid themeable:(NSObject<IQThemeable>*)themeable;
@property (nonatomic, retain) NSObject* value;
@end

@interface IQMutableTheme () {
    NSMutableDictionary* theme;
    BOOL batchUpdating;
    BOOL overwriteLocked;
}
- (void) _setThemeValue:(NSObject*)value property:(NSString*)property for:(NSObject*)themeableOrString;
- (void) _setThemeValue:(NSObject*)value property:(NSString*)property forTokens:(NSArray*)tokens;
- (void) _setThemeValue:(NSObject*)value property:(NSString*)property forDecl:(_IQThemeDeclaration*)decl;

- (NSObject*) _themeProperty:(NSString*)property for:(NSObject<IQThemeable>*)themeable;
- (void) _postModify:(NSString*)prop;
@end

@implementation IQTheme

+ (IQTheme*) defaultTheme
{
    if(!_default) {
        _default = [[IQTheme alloc] init];
    }
    return _default;
}

+ (void) setDefaultTheme:(IQTheme*)theme
{
    _default = theme;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIQThemeNotificationDefaultThemeChanged object:nil];
}

+ (NSObject<IQThemeable>*) themeableForElement:(NSString*)element ofParent:(NSObject<IQThemeable>*)parent defaultInherit:(BOOL)inherit
{
    _IQDummyThemeable* thm = [[_IQDummyThemeable alloc] init];
    thm.parentThemeable = parent;
    thm.themeElementName = element;
    thm.defaultInherit = inherit;
    return thm;
}

+ (NSSet*) themeClassesFor:(NSObject<IQThemeable>*)themeable
{
    if([themeable respondsToSelector:@selector(themeClasses)]) {
        return [themeable themeClasses];
    }
    return nil;
}

+ (NSString*) themeUniqueIdentifierFor:(NSObject<IQThemeable>*)themeable
{
    if([themeable respondsToSelector:@selector(themeUniqueIdentifier)]) {
        NSString* tui = [themeable themeUniqueIdentifier];
        if(tui != nil) return tui;
    }
    return [NSString stringWithFormat:@"__%p__", themeable];
}

- (IQTheme*) themeForWidget:(NSObject*)widget
{
    return self;
}

- (BOOL) applyToView:(UIView*)view for:(NSObject<IQThemeable>*)themeable flags:(IQThemeViewApplyFlags)flags
{
    BOOL didSet = NO;
    if(flags & IQThemeViewApplyBackgroundStyle) {
        UIColor* bgColor = [self backgroundColorFor:themeable];
        if(bgColor != nil) {
            view.backgroundColor = bgColor;
            didSet = YES;
        }
    }
    if(flags & IQThemeViewApplyTextStyle) {
        if([view respondsToSelector:@selector(setTextColor:)]) {
            UIColor* textColor = [self colorFor:themeable];
            if(textColor != nil) {
                [(id)view setTextColor:textColor];
                didSet = YES;
            }
        }
        if([view respondsToSelector:@selector(setTextAlignment:)]) {
            UITextAlignment align = [self textAlignmentFor:themeable];
            if(align >= 0) {
                [(id)view setTextAlignment:(NSTextAlignment)align];
                didSet = YES;
            }
        }
        if([view respondsToSelector:@selector(setShadowColor:)]) {
            IQThemeTextShadow* shadow = [self textShadowFor:themeable];
            if(shadow) {
                [(id)view setShadowColor:shadow.color];
            }
        }
    }
    if(flags & IQThemeViewApplyVisibility) {
        IQThemeTristate hidden = [self isHidden:themeable];
        if(hidden != IQThemeNotSet) {
            view.hidden = hidden;
            didSet = YES;
        }
    }
    return didSet;
}

- (IQThemeTristate) isHidden:(NSObject<IQThemeable>*)themeable
{
    return IQThemeNotSet;
}

- (UIFont*) fontFor:(NSObject<IQThemeable>*)themeable
{
    NSString* elem = [themeable themeElementName];
    if([elem isEqualToString:@"item"]) {
        return [UIFont boldSystemFontOfSize:0];
    }
    return [UIFont systemFontOfSize:0];
}

- (UITextAlignment) textAlignmentFor:(NSObject<IQThemeable>*)themeable
{
    return UITextAlignmentLeft;
}

- (UITableViewStyle) tableViewStyleFor:(NSObject<IQThemeable>*)themeable
{
    return UITableViewStylePlain;
}

- (UIColor*) colorFor:(NSObject<IQThemeable>*)themeable
{
    return nil;
}

- (UIColor*) backgroundColorFor:(NSObject<IQThemeable>*)themeable
{
    return nil;
}

- (UIColor*) borderColorFor:(NSObject<IQThemeable>*)themeable
{
    return nil;
}

- (IQThemeTextShadow*) textShadowFor:(NSObject<IQThemeable>*)themeable
{
    return nil;
}

@end

@implementation IQMutableTheme

#pragma mark - IQTheme overrides

- (UIFont*) fontFor:(NSObject<IQThemeable>*)themeable
{
    UIFont* fnt = [super fontFor:themeable];
    
    NSString* weightStr = (NSString*)[self _themeProperty:@"font-weight" for:themeable];
    NSString* sizeStr = (NSString*)[self _themeProperty:@"font-size" for:themeable];
    NSString* family = (NSString*)[self _themeProperty:@"font-family" for:themeable];
    NSString* style = (NSString*)[self _themeProperty:@"font-style" for:themeable];
    
    if(weightStr || sizeStr || family || style) {
        NSString* font = fnt.fontName;
        float size = fnt.pointSize;
        BOOL isBold = NO;
        BOOL isItalic = NO;
        BOOL isLight = NO;
        NSRange variantRange = [font rangeOfString:@"-" options:NSBackwardsSearch];
        if(variantRange.length > 0) {
            NSString* variant = [font substringFromIndex:variantRange.location+1];
            if([variant rangeOfString:@"Bold"].length) {
                isBold = YES;
            } else if([variant rangeOfString:@"Italic"].length || [variant rangeOfString:@"Oblique"].length) {
                isItalic = YES;
            } else if([variant rangeOfString:@"Light"].length) {
                isLight = YES;
            }
            font = [font substringToIndex:variantRange.location];
        }
        
        if(family != nil) {
            font = family;
        }
        NSArray* variants = [UIFont fontNamesForFamilyName:font];
        if(variants.count == 0) {
            font = @"Helvetica";
            variants = [UIFont fontNamesForFamilyName:font];
        }
        
        if(sizeStr) {
            size = _IQMutableTheme_SizeInPoints(sizeStr, size);
        }
        float weight = 400;
        if([weightStr isEqual:@"bold"]) {
            weight = 700;
        } else if([weightStr isEqual:@"normal"]) {
            weight = 400;
        } else if([weightStr isEqual:@"bolder"]) {
            weight = isLight?400:700;
        } else if([weightStr isEqual:@"lighter"]) {
            weight = isBold?100:400;
        } else if(weight) {
            float wt = [weightStr floatValue];
            if(wt) {
                weight = wt;
            }
        }
        if(weight < 300) {
            isLight = YES;
            isBold = NO;
        } else if(weight > 500) {
            isLight = NO;
            isBold = YES;
        } else {
            isLight = NO;
            isBold = NO;
        }
        if([style isEqualToString:@"italic"]) {
            isItalic = YES;
        } else if(style) {
            isItalic = NO;
        }
        
        NSString* fontWithVariant = font;
        if(isBold && isItalic) {
            fontWithVariant = [font stringByAppendingString:@"-BoldItalic"];
            if(![variants containsObject:fontWithVariant]) {
                fontWithVariant = [font stringByAppendingString:@"-BoldOblique"];
                if(![variants containsObject:fontWithVariant]) {
                    fontWithVariant = font;
                }
            }
        } else if(isBold) {
            fontWithVariant = [font stringByAppendingString:@"-Bold"];
            if(![variants containsObject:fontWithVariant]) {
                fontWithVariant = font;
            }
        } else if(isItalic) {
            fontWithVariant = [font stringByAppendingString:@"-Italic"];
            if(![variants containsObject:fontWithVariant]) {
                fontWithVariant = [font stringByAppendingString:@"-Oblique"];
                if(![variants containsObject:fontWithVariant]) {
                    fontWithVariant = font;
                }
            }
        }
        if(size == 0) size = 17.0f; // Size 0 is "magic" to some controls (will use system default size)
        UIFont* newFont = [UIFont fontWithName:fontWithVariant size:size];
        if(!newFont) {
            NSLog(@"Warning: Font %@ could not be created", fontWithVariant);
        } else {
            fnt = newFont;
        }
    }
    return fnt;
}

- (UITextAlignment) textAlignmentFor:(NSObject<IQThemeable>*)themeable
{
    NSObject* align = (NSObject*)[self _themeProperty:@"text-align" for:themeable];
    if([align isEqual:@"right"]) {
        return UITextAlignmentRight;
    } else if([align isEqual:@"center"]) {
        return UITextAlignmentCenter;
    } else if([align isEqual:@"left"]) {
        return UITextAlignmentLeft;
    } else {
        return (UITextAlignment)-1;
    }
}

- (UIColor*) colorFor:(NSObject<IQThemeable>*)themeable
{
    NSObject* color = (NSObject*)[self _themeProperty:@"color" for:themeable];
    if(color) {
        if([color isKindOfClass:[UIColor class]]) {
            return (UIColor*)color;
        } else {
            return _IQMutableTheme_ParseCssColor([color description]);
        }
    }
    return nil;
}

- (UIColor*) backgroundColorFor:(NSObject<IQThemeable>*)themeable
{
    NSObject* color = (NSObject*)[self _themeProperty:@"background-color" for:themeable];
    if(color) {
        if([color isKindOfClass:[UIColor class]]) {
            return (UIColor*)color;
        } else {
            return _IQMutableTheme_ParseCssColor([color description]);
        }
    }
    return nil;
}

- (UIColor*) borderColorFor:(NSObject<IQThemeable>*)themeable
{
    NSObject* color = (NSObject*)[self _themeProperty:@"border-color" for:themeable];
    if(color) {
        if([color isKindOfClass:[UIColor class]]) {
            return (UIColor*)color;
        } else {
            return _IQMutableTheme_ParseCssColor([color description]);
        }
    }
    return nil;
}

- (IQThemeTristate) isHidden:(NSObject<IQThemeable>*)themeable
{
    NSObject* vis = [self _themeProperty:@"visibility" for:themeable];
    if([vis isEqual:@"hidden"]) {
        return IQThemeYes;
    } else if([vis isEqual:@"visible"]) {
        return IQThemeNo;
    }
    return IQThemeNotSet;
}

- (UITableViewStyle) tableViewStyleFor:(NSObject<IQThemeable>*)themeable
{
    NSObject* tst = [self _themeProperty:@"table-style" for:themeable];
    if([tst isEqual:@"grouped"]) {
        return UITableViewStyleGrouped;
    } else if([tst isEqual:@"plain"]) {
        return UITableViewStylePlain;
    }
    return [super tableViewStyleFor:themeable];
}

- (IQThemeTextShadow*) textShadowFor:(NSObject<IQThemeable>*)themeable
{
    NSObject* shadow = (NSObject*)[self _themeProperty:@"text-shadow" for:themeable];
    if(shadow) {
        return [[IQThemeTextShadow alloc] initWithCssString:[shadow description]];
    }
    return nil;
}

#pragma mark - Setters

- (void) setFont:(UIFont*)font for:(NSObject*)themeableOrString
{
    [self _setThemeValue:font property:@"font" for:themeableOrString];
}

- (void) setTextAlignment:(UITextAlignment)textAlignment for:(NSObject*)themeableOrString
{
    NSString* alignString;
    switch(textAlignment) {
        case UITextAlignmentLeft:
            alignString = @"left";
            break;
        case UITextAlignmentCenter:
            alignString = @"center";
            break;
        case UITextAlignmentRight:
            alignString = @"right";
            break;
        default:
            [NSException raise:@"InvalidEnum" format:@"Invalid UITextAlignment value %ld", (long)textAlignment];
            return;
    }
    [self _setThemeValue:alignString property:@"text-align" for:themeableOrString];
}

- (void) setTableViewStyle:(UITableViewStyle)style for:(NSObject*)themeableOrString
{
    NSString* styleString;
    switch(style) {
        case UITableViewStyleGrouped:
            styleString = @"grouped";
            break;
        case UITableViewStylePlain:
            styleString = @"plain";
            break;
        default:
            [NSException raise:@"InvalidEnum" format:@"Invalid UITableViewStyle value %ld", (long)style];
            return;
    }
    [self _setThemeValue:styleString property:@"table-style" for:themeableOrString];
}

- (void) setColor:(UIColor*)color for:(NSObject*)themeableOrString
{
    [self _setThemeValue:color property:@"color" for:themeableOrString];
}

- (void) setBackgroundColor:(UIColor*)bgcolor for:(NSObject*)themeableOrString
{
    [self _setThemeValue:bgcolor property:@"background-color" for:themeableOrString];
}

- (void) setBorderColor:(UIColor*)bdcolor for:(NSObject*)themeableOrString
{
    [self _setThemeValue:bdcolor property:@"border-color" for:themeableOrString];
}

#pragma mark - CSS output

- (NSString*) CSSText
{
    NSMutableSet* contents = [NSMutableSet set];
    for(NSString* prop in theme) {
        [contents addObjectsFromArray:[theme objectForKey:prop]];
    }
    NSMutableArray* contentsArray = [NSMutableArray arrayWithCapacity:contents.count];
    for(id object in contents) {
        [contentsArray addObject:object];
    }
    [contentsArray sortUsingSelector:@selector(compareSpecificity:)];
    NSMutableString* str = [NSMutableString string];
    for(_IQThemeDeclaration* decl in contentsArray) {
        [str appendString:[decl description]];
        [str appendString:@" {\n"];
        for(NSString* prop in theme) {
            NSMutableArray* arr = [theme objectForKey:prop];
            NSInteger idx = [arr indexOfObject:decl];
            if(idx != NSNotFound) {
                [str appendString:@"   "];
                [str appendString:prop];
                [str appendString:@" : "];
                [str appendString:[[arr objectAtIndex:idx] valueString]];
                [str appendString:@";\n"];
            }
        }
        [str appendString:@"}\n\n"];
    }
    return str;
}

#pragma mark - Private methods

- (void) _setThemeValue:(NSObject*)value property:(NSString*)property for:(NSObject*)themeableOrString
{
    if([themeableOrString respondsToSelector:@selector(themeElementName)]) {
        NSString* element = [(id)themeableOrString themeElementName];
        NSString* uid = [IQTheme themeUniqueIdentifierFor:(id)themeableOrString];
        [self _setThemeValue:value property:property forDecl:[[_IQThemeDeclaration alloc] initWithElement:element classes:nil uid:uid parent:nil]];
    } else {
        [self _setThemeValue:value property:property forTokens:_IQMutableTheme_TokenizeCSS([themeableOrString description], NULL)];
    }
}

- (void) _setThemeValue:(NSObject*)value property:(NSString*)property forTokens:(NSArray*)tokens
{
    NSString* uid = nil;
    NSMutableSet* classes = nil;
    _IQThemeDeclaration* parent = nil;
    NSString* elementName = nil;
    for(NSString* token in tokens) {
        if(token.length == 0) continue;
        switch([token characterAtIndex:0]) {
            case '#':
                if(!uid) {
                    uid = [token substringFromIndex:1];
                }
                break;
            case '.':
                if(!classes) classes = [NSMutableSet set];
                [classes addObject:[token substringFromIndex:1]];
                break;
            default:
                if(elementName || uid || classes) {
                    parent = [[_IQThemeDeclaration alloc] initWithElement:elementName classes:classes uid:uid parent:parent];
                }
                elementName = token;
        }
    }
    if(elementName || uid || classes) {
        parent = [[_IQThemeDeclaration alloc] initWithElement:elementName classes:classes uid:uid parent:parent];
    }
    if(parent) {
        [self _setThemeValue:value property:property forDecl:parent];
    }
}
         
- (void) _setThemeValue:(NSObject*)value property:(NSString*)property forDecl:(_IQThemeDeclaration*)decl
{
    NSMutableArray* props = [theme objectForKey:property];
    if(!props) {
        props = [NSMutableArray array];
        if(!theme) theme = [NSMutableDictionary dictionary];
        [theme setObject:props forKey:property];
    } else {
        NSInteger idx = [props indexOfObject:decl];
        if(idx != NSNotFound) {
            // Only the first property is set
            if(overwriteLocked) {
                return;
            } else {
                [props removeObjectAtIndex:idx];
            }
        }
    }
    decl.value = value;
    [props addObject:decl];
    if(!batchUpdating) {
        [self _postModify:property];
    }
}

- (NSObject*) _themeProperty:(NSString*)property for:(NSObject<IQThemeable>*)themeable
{
    NSString* element = [themeable themeElementName];
    NSSet* cls = [IQTheme themeClassesFor:themeable];
    NSString* uid = [IQTheme themeUniqueIdentifierFor:themeable];
    NSMutableArray* props = [theme objectForKey:property];
    if(props) {
        for(_IQThemeDeclaration* decl in props) {
            if([decl matches:element classes:cls uid:uid themeable:themeable]) {
                if(decl.value) {
                    return decl.value;
                }
            }
        }
    }
    
    if([themeable respondsToSelector:@selector(defaultInherit)] && [(id)themeable defaultInherit]) {
        if([themeable respondsToSelector:@selector(parentThemeable)]) {
            NSObject<IQThemeable>* parent = [(id)themeable parentThemeable];
            if(parent) {
                return [self _themeProperty:property for:parent];
            }
        }
    }
    
    return nil;
}

- (void) _postModify:(NSString*)prop
{
    if(prop == nil) {
        for(NSString* prop in theme.keyEnumerator) {
            if(prop) [self _postModify:prop];
        }
    } else {
        NSMutableArray* a = [theme objectForKey:prop];
        if(a) {
            [a sortUsingSelector:@selector(compareSpecificity:)];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"IQTheme_Changed" object:self];
}

@end

@implementation _IQDummyThemeable
@synthesize parentThemeable, themeElementName, defaultInherit;

- (NSSet*) themeClasses
{
    return nil;
}

- (NSString*) themeUniqueIdentifier
{
    return nil;
}


@end

@implementation _IQThemeDeclaration
@synthesize value;

- (id) initWithElement:(NSString*)e classes:(NSSet*)c uid:(NSString*)u parent:(_IQThemeDeclaration *)p
{
    self = [super init];
    if(self) {
        if([e isEqualToString:@"*"]) e = nil;
        if([u isEqualToString:@"*"]) u = nil;
        elementName = e;
        classes = c;
        uniqueId = u;
        parent = p;
    }
    return self;
}
- (NSInteger) specificity
{
    NSInteger specificity = classes.count * 100;
    if(uniqueId) specificity += 100000;
    if(elementName) specificity += 10;
    specificity += (parent.specificity) / 10;
    return specificity;
}

- (NSComparisonResult) compareSpecificity:(id)other
{
    NSInteger s1 = self.specificity;
    NSInteger s2 = [other specificity];
    if(s1 > s2) return NSOrderedAscending;
    if(s1 < s2) return NSOrderedDescending;
    return NSOrderedSame;
}

- (BOOL) matches:(NSString*)elem classes:(NSSet*)cls uid:(NSString*)uid themeable:(NSObject<IQThemeable>*)themeable
{
    if(elementName) {
        if(!elem || ![elem isEqualToString:elementName] != 0) {
            return NO;
        }
    }
    if(classes) {
        if(!cls) return NO;
        for(NSString* c in classes) {
            if(![cls containsObject:c]) return NO;
        }
    }
    if(uniqueId) {
        if(!uid || ![uid isEqualToString:uniqueId] != 0) {
            return NO;
        }
    }
    if(parent) {
        _IQThemeDeclaration* pdecl = parent;
        NSObject<IQThemeable>* par = nil;
        if([themeable respondsToSelector:@selector(parentThemeable)]) {
            par = themeable.parentThemeable;
        }
        if(pdecl != nil) {
            if(par == nil) {
                return NO;
            }
            NSString* pElem = [par themeElementName];
            NSSet* pCls = [IQTheme themeClassesFor:par];
            NSString* pUid = [IQTheme themeUniqueIdentifierFor:par];
            if(![pdecl matches:pElem classes:pCls uid:pUid themeable:par]) {
                return NO;
            }
        }
    }
    return YES;
}

- (NSUInteger) hash
{
    return elementName.hash + uniqueId.hash + classes.hash + parent.hash;
}

- (BOOL) isEqual:(id)object
{
    if(![object isKindOfClass:[_IQThemeDeclaration class]]) {
        return NO;
    }
    _IQThemeDeclaration* other = object;
    if(elementName && (!other->elementName || ![elementName isEqual:other->elementName])) {
        return NO;
    } else if(!elementName && other->elementName) {
        return NO;
    }
    if(uniqueId && (!other->uniqueId || ![uniqueId isEqual:other->uniqueId])) {
        return NO;
    } else if(!uniqueId && other->uniqueId) {
        return NO;
    }
    if(classes && (!other->classes || ![classes isEqual:other->classes])) {
        return NO;
    } else if(!classes && other->classes) {
        return NO;
    }
    if(parent && (!other->parent || ![parent isEqual:other->parent])) {
        return NO;
    } else if(!parent && other->parent) {
        return NO;
    }
    return YES;
}

- (NSString*) valueString
{
    if(value == nil) {
        return @"default";
    }
    return [value description];
}

- (NSString*) description
{
    NSMutableString* str = [NSMutableString stringWithCapacity:32];
    if(parent) {
        [str appendString:[parent description]];
        [str appendString:@" "];
    }
    if(elementName) {
        [str appendString:elementName];
    } else if (parent) {
        [str appendString:@"*"];
    }
    
    if(classes) {
        for(NSString* cls in classes) {
            if(str.length > 0) [str appendString:@" "];
            [str appendString:@"."];
            [str appendString:cls];
        }
    }
    
    if(uniqueId) {
        if(str.length > 0) [str appendString:@" "];
        [str appendString:@"#"];
        [str appendString:uniqueId];
    }
    if(str.length == 0) [str appendString:@"*"];
    return str;
}
@end

@implementation IQThemeTextShadow
@synthesize offset, blur, color;

- (id) initWithCssString:(NSString*)cssString
{
    self = [super init];
    if(self) {
        if([cssString isEqualToString:@"none"]) {
            self.color = nil;
        }
    }
    return self;
}

@end