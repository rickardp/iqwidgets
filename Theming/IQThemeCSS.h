//
//  IQThemeCSS.h
//  DrilldownTest
//
//  Created by Rickard Petzäll on 2012-09-30.
//  Copyright (c) 2012 EvolvIQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IQTheme.h"

@interface IQMutableTheme (CSSParsing)
+ (IQMutableTheme*) themeFromCSS:(NSString*)css;
+ (IQMutableTheme*) themeFromCSSResource:(NSString*)cssResourcePath;

- (void) parseCSS:(NSString*)css;
@end
