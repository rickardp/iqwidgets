//
//  IQThemeCSS.m
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

#import "IQThemeCSS.h"

@interface IQMutableTheme (PrivateMethods)
- (void) _setThemeValue:(NSObject*)value property:(NSString*)property forTokens:(NSArray*)tokens;
@end

// Tokenize a CSS selector (i.e. string before '{' specifying what to match)
// http://www.w3.org/TR/CSS2/selector.html
NSArray* _IQMutableTheme_TokenizeCSS(NSString* cssSelector, int* ioPos) {
    NSMutableArray* tokens = [NSMutableArray array];
    int len = cssSelector.length;
    int i = 0;
    if(ioPos) i = (*ioPos);
    int lastPos = i;
    BOOL stop = NO;
    char oc = 0;
    for(; i<len && !stop; i++) {
        char c = [cssSelector characterAtIndex:i];
        switch(c) {
            case '#':
            case '.':
                if(i>lastPos) {
                    [tokens addObject:[cssSelector substringWithRange:NSMakeRange(lastPos, i-lastPos)]];
                }
                lastPos = i;
                break;
            case '>':
                NSLog(@"Child element selectors not supported");
                lastPos = i+1;
                break;
            case ' ':
            case '\t':
            case '\r':
            case '\n':
                if(i>lastPos) {
                    [tokens addObject:[cssSelector substringWithRange:NSMakeRange(lastPos, i-lastPos)]];
                }
                lastPos = i+1;
                break;
            case ',':
            case '{':
            case '}':
            case '\"':
            case '\'':
            case ';':
                i--;
                stop = YES;
                break;
            case '*':
                if(oc == '/') {
                    if(i-1>lastPos) {
                        [tokens addObject:[cssSelector substringWithRange:NSMakeRange(lastPos, i-1-lastPos)]];
                    }
                    NSRange rng = [cssSelector rangeOfString:@"*/"];
                    if(rng.length == 0) {
                        i = -1;
                        stop = YES;
                    } else {
                        i = rng.location + rng.length;
                        for(;i<len && !stop;i++) {
                            c = [cssSelector characterAtIndex:i];
                            BOOL isWs = NO;
                            switch(c) {
                                case ' ':
                                case '\t':
                                case '\r':
                                case '\n':
                                    isWs = YES;
                                    break;
                            }
                            if(!isWs) break;
                        }
                        lastPos = i;
                    }
                } else {
                    if(i>lastPos) {
                        [tokens addObject:[cssSelector substringWithRange:NSMakeRange(lastPos, i-lastPos)]];
                    }
                    lastPos = i;
                }
                break;
            default:
                if(oc == '*') {
                    if(i>lastPos) {
                        [tokens addObject:[cssSelector substringWithRange:NSMakeRange(lastPos, i-lastPos)]];
                    }
                    lastPos = i;
                }
                break;
        }
        oc = c;
    }
    if(i>lastPos) {
        [tokens addObject:[cssSelector substringWithRange:NSMakeRange(lastPos, i-lastPos)]];
    }
    if(ioPos) {
        *ioPos = i;
    }
    return tokens;
}

NSObject* _IQMutableTheme_CSSValue(NSString* val)
{
    return val;
}

// Convert CSS values into a NSDictionary
NSDictionary* _IQMutableTheme_ParseCSSValues(NSString* css, int* ioPos) {
    NSMutableDictionary* values = [NSMutableDictionary dictionary];
    int i = 0;
    if(ioPos) i = (*ioPos);
    NSRange comment = [css rangeOfString:@"/*" options:NSLiteralSearch range:NSMakeRange(i, css.length-i)];
    int commentsSize = 0;
    BOOL error = NO;
    while(comment.length > 0) {
        NSRange endComment = [css rangeOfString:@"*/" options:NSLiteralSearch range:NSMakeRange(comment.location+2, css.length-(comment.location+2))];
        if(endComment.length == 0) {
            NSLog(@"CSS parse error: unterminated comment '%@'", [css substringFromIndex:comment.location]);
            css = [css substringWithRange:NSMakeRange(i, comment.location-i)];
            i = 0;
            error = YES;
            break;
        } else {
            NSString* before = [css substringWithRange:NSMakeRange(i, comment.location-i)];
            NSString* after = [css substringFromIndex:endComment.location + endComment.length];
            commentsSize += i;
            i = 0;
            commentsSize += (endComment.location - comment.location + endComment.length);
            css = [before stringByAppendingString:after];
            comment = [css rangeOfString:@"/*"];
        }
    }
    int lastPos = i;
    int len = css.length;
    BOOL stop = NO;
    NSString* key = nil;
    for(; i<len && !stop; i++) {
        char c = [css characterAtIndex:i];
        switch(c) {
            case ';':
                if(i<=lastPos || !key) {
                    NSLog(@"CSS parse error before ';'");
                    stop = YES;
                } else {
                    NSString* valStr = [css substringWithRange:NSMakeRange(lastPos, i-lastPos)];
                    [values setObject:_IQMutableTheme_CSSValue(valStr) forKey:key];
                    key = nil;
                    lastPos = i+1;
                }
                break;
            case ':':
                if(i<=lastPos || key) {
                    NSLog(@"CSS parse error before ':'");
                    stop = YES;
                } else {
                    key = [css substringWithRange:NSMakeRange(lastPos, i-lastPos)];
                    lastPos = i+1;
                }
                break;
            case ' ':
            case '\t':
            case '\r':
            case '\n':
                lastPos = i+1;
                break;
            case '}':
                if(i>lastPos && key) {
                    NSString* valStr = [css substringWithRange:NSMakeRange(lastPos, i-lastPos)];
                    [values setObject:_IQMutableTheme_CSSValue(valStr) forKey:key];
                }
                stop = YES;
                break;
        }
    }
    if(!stop && i>lastPos && key) {
        NSString* valStr = [css substringWithRange:NSMakeRange(lastPos, i-lastPos)];
        [values setObject:_IQMutableTheme_CSSValue(valStr) forKey:key];
    }
    
    if(ioPos) {
        if(error) *ioPos = -1;
        else *ioPos = i + commentsSize;
    }
    
    return values;
}
float _IQMutableTheme_SizeInPoints(NSString* cssSizeSpec, float refSize) {
    if(refSize == 0.0f) refSize = 17.0f;
    const char* ref = [cssSizeSpec cStringUsingEncoding:NSUTF8StringEncoding];
    char* e = NULL;
    float size = strtof(ref, &e);
    if(!e || e == ref) {
        return refSize;
    }
    if(strstr(e, "pt")) {
        return size;
    } else if(strstr(e, "px")) {
        return size*.75f;
    } else if (strstr(e, "in")) {
        return size * 72.0f;
    } else if (strstr(e, "mm")) {
        return size * 72.0f / 25.4f;
    } else if (strstr(e, "cm")) {
        return size * 72.0f / 2.54f;
    } else if (strstr(e, "pc")) {
        return size * 12.0f;
    } else if (strstr(e, "%")) {
        return size * refSize / 100.0f;
    } else {
        return size;
    }
}

UIColor* _IQMutableTheme_ParseCssColor(NSString* cssColorSpec) {
    if([cssColorSpec characterAtIndex:0] == '#') {
        NSScanner *scanner = [NSScanner scannerWithString:cssColorSpec];
        [scanner setScanLocation:1];
        NSUInteger result = 0;
        if([scanner scanHexInt:&result]) {
            result &= 0xFFFFFF;
            return [UIColor colorWithRed:((result>>16)&0xFF)/255.0f green:((result>>8)&0xFF)/255.0f blue:((result>>0)&0xFF)/255.0f alpha:1.0f];
        }
    } else if([[cssColorSpec substringToIndex:3] isEqualToString:@"rgb"]) {
        NSRange rng = [cssColorSpec rangeOfString:@"("];
        if(rng.length == 0) return nil;
        NSRange arng = [cssColorSpec rangeOfString:@")"];
        if(arng.length == 0 || arng.location < rng.location) return nil;
        float r=0,g=0,b=0,a=1;
        int cmpIndex = 0;
        for(NSString* cmpnt in [[cssColorSpec substringWithRange:NSMakeRange(rng.location+1, arng.location-rng.location-1)] componentsSeparatedByString:@","]) {
            NSString* c = [cmpnt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            float val;
            if([c rangeOfString:@"."].length > 0) {
                val = [c floatValue];
            } else {
                val = [c intValue] / 255.0f;
            }
            if(cmpIndex == 0) r = val;
            else if(cmpIndex == 1) g = val;
            else if(cmpIndex == 2) b = val;
            else a = val;
        }
        return [UIColor colorWithRed:r green:g blue:b alpha:a];
    } else {
        static NSDictionary* map = nil;
        if(!map) {
            map = [NSDictionary dictionaryWithObjectsAndKeys:
                   [UIColor clearColor], @"transparent",
                   [UIColor cyanColor], @"aqua",
                   [UIColor blackColor], @"black",
                   [UIColor blueColor], @"blue",
                   [UIColor magentaColor], @"fuchsia",
                   [UIColor magentaColor], @"magenta",
                   [UIColor grayColor], @"gray",
                   [UIColor grayColor], @"grey",
                   [UIColor colorWithRed:0 green:.5f blue:0 alpha:1], @"green",
                   [UIColor greenColor], @"lime",
                   [UIColor colorWithRed:0.5f green:0 blue:0 alpha:1], @"maroon",
                   [UIColor colorWithRed:0.5f green:0 blue:0 alpha:1], @"navy",
                   [UIColor colorWithRed:0.5f green:0.5f blue:0 alpha:1], @"olive",
                   [UIColor colorWithRed:0.5f green:0 blue:0.5f alpha:1], @"purple",
                   [UIColor redColor], @"red",
                   [UIColor colorWithRed:0.75f green:0.75 blue:0.75f alpha:1], @"silver",
                   [UIColor colorWithRed:0 green:0.5f blue:0.5f alpha:1], @"teal",
                   [UIColor whiteColor], @"white",
                   [UIColor yellowColor], @"yellow",
                   nil];
        }
        return [map objectForKey:[cssColorSpec lowercaseString]];
    }
    return nil;
}


@implementation IQMutableTheme (CSSParsing)

+ (IQMutableTheme*) themeFromCSS:(NSString*)css
{
    IQMutableTheme* theme = [[IQMutableTheme alloc] init];
    [theme parseCSS:css];
    return theme;
}

+ (IQMutableTheme*) themeFromCSSResource:(NSString*)cssResourcePath
{
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* baseName = [cssResourcePath stringByDeletingPathExtension];
    NSString* ext = [cssResourcePath pathExtension];
    NSString* path = [bundle pathForResource:baseName ofType:ext];
    if(path == nil) {
        NSLog(@"Unable to find CSS resource %@", cssResourcePath);
        return nil;
    }
    NSError* error = nil;
    NSString* css = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if(css == nil) {
        NSLog(@"Unable to read CSS file %@: %@", path, error);
        return nil;
    }
    return [IQMutableTheme themeFromCSS:css];
}

- (void) parseCSS:(NSString*)css
{
    int idx = 0, len = css.length;
    NSMutableArray* selectors = nil;
    while(idx < len) {
        NSArray* sel = _IQMutableTheme_TokenizeCSS(css, &idx);
        if(!sel || idx < 0 || idx >= len) break;
        if(!selectors) selectors = [NSMutableArray arrayWithCapacity:1];
        [selectors addObject:sel];
        sel = nil;
        for(;idx<len;idx++) {
            char c = [css characterAtIndex:idx];
            if(c == ',') {
                idx++;
                continue;
            } else if(c == '{' || c == '/') {
                idx++;
                NSDictionary* dict = _IQMutableTheme_ParseCSSValues(css, &idx);
                if(dict && selectors.count) {
                    for(NSArray* selector in selectors) {
                        for(NSString* prop in dict) {
                            [self _setThemeValue:[dict objectForKey:prop] property:prop forTokens:selector];
                        }
                    }
                }
                if(idx < 0 || idx >= len) return;
                selectors = nil;
                break;
            } else if(c != ' ' && c != '\t' && c != '\n' && c != '\r') {
                NSLog(@"CSS parse error at %@", [css substringFromIndex:idx]);
                return;
            }
        }
    }
}
@end
