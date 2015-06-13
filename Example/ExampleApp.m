//
//  ExampleApp.m
//  IQWidgets for iOS
//
//  Copyright 2010 EvolvIQ
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
//

#import "ExampleApp.h"
#import "ExampleViewController.h"
#import "MonthCalendarExample.h"
#import <QuartzCore/QuartzCore.h>

@implementation ExampleAppDelegate
@synthesize window, rootViewController;

- (UIViewController*)webViewControllerWithURL:(NSURL*)url
{
    UIWebView* webview = [[UIWebView alloc] initWithFrame:self.window.bounds];
    webview.delegate = self;
    UIViewController* c = [[UIViewController alloc] init];
    [webview loadRequest:[NSURLRequest requestWithURL:url]];
    c.view = webview;
    return c;
}

- (UIViewController*)aboutViewController
{
    return [self webViewControllerWithURL:[[NSBundle mainBundle] URLForResource:@"about" withExtension:@"html"]];
}

- (void)navigateTo:(UIViewController*)c
{
    if([self.rootViewController isKindOfClass:[IQNavigationController class]]) {
        [(IQNavigationController*)self.rootViewController setViewControllers:[NSArray arrayWithObject:c] animated:YES];
    } else {
        [(IQDrilldownController*)self.rootViewController setViewController:c animated:YES];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if(navigationType == UIWebViewNavigationTypeLinkClicked) {
        [(UINavigationController*)self.rootViewController pushViewController:[self webViewControllerWithURL:request.URL] animated:YES];
        return NO;
    }
    return YES;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    IQMenuViewController* menu = [[IQMenuViewController alloc] init];
    IQMenuSection* infoSection = [IQMenuSection sectionWithTitle:@"Information"];
    [infoSection addItem:[IQMenuItem itemWithTitle:@"About this app" action:^{
        UIViewController* c = [self aboutViewController];
        [self navigateTo:c];
    }] animated:NO];
    [menu addSection:infoSection animated:NO];
    IQMenuSection* dateTimeSection = [IQMenuSection sectionWithTitle:@"Date and time"];
    [dateTimeSection addItem:[IQMenuItem itemWithTitle:@"Month Calendar" action:^{
        [self navigateTo:[[MonthCalendarExample alloc] init]];
    }] animated:NO];
    [menu addSection:dateTimeSection animated:NO];
    IQMenuSection* utilitySection = [IQMenuSection sectionWithTitle:@"Utilities"];
    [utilitySection addItem:[IQMenuItem itemWithTitle:@"Icon fonts" action:^{
        UITabBarController* vc = [UITabBarController new];
        UIViewController* tab1 = [UIViewController new];
        tab1.tabBarItem.title = @"Tab 1";
        tab1.tabBarItem.iconFontResource = @"LigatureSymbols";
        tab1.tabBarItem.iconSymbol = @"app";
        UIViewController* tab2 = [UIViewController new];
        tab2.tabBarItem.title = @"Tab 2";
        tab2.tabBarItem.iconFontResource = @"FontAwesome";
        tab2.tabBarItem.iconSymbol = @"0xf1ea";

        tab1.view.backgroundColor = tab2.view.backgroundColor = [UIColor whiteColor];
        vc.viewControllers = @[tab1, tab2];

        UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, 200, 30)];
        lbl.text = @"Static icon (UIImageView):";
        lbl.font = [UIFont systemFontOfSize:10];
        lbl.tintColor = [UIColor darkGrayColor];
        [tab1.view addSubview:lbl];

        UIImageView* l = [[UIImageView alloc] initWithFrame:CGRectMake(10, 90, 90, 40)];
        l.contentMode = UIViewContentModeScaleAspectFit;
        l.iconFontResource = @"LigatureSymbols";
        l.iconSymbol = @"tag";
        [tab1.view addSubview:l];
        l = [[UIImageView alloc] initWithFrame:CGRectMake(100, 90, 90, 40)];
        l.contentMode = UIViewContentModeScaleAspectFit;
        l.iconFontResource = @"FontAwesome";
        l.iconSymbol = @"0xf1e3";
        [tab1.view addSubview:l];

        lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 130, 200, 30)];
        lbl.text = @"Push button (UIButton):";
        lbl.font = [UIFont systemFontOfSize:10];
        lbl.tintColor = [UIColor darkGrayColor];
        [tab1.view addSubview:lbl];
        UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(10, 160, 90, 90);
        [btn setTitle:@"Hej" forState:UIControlStateNormal];
        [tab1.view addSubview:btn];

        lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 230, 200, 30)];
        lbl.text = @"Segmented (UISegmentedControl):";
        lbl.font = [UIFont systemFontOfSize:10];
        lbl.tintColor = [UIColor darkGrayColor];
        [tab1.view addSubview:lbl];
        UISegmentedControl* sc = [[UISegmentedControl alloc] initWithItems:@[@"A", @"B", @"C"]];
        sc.frame = CGRectMake(10, 260, 90, 26);
        [tab1.view addSubview:sc];

        [self navigateTo:vc];
    }] animated:NO];
    [menu addSection:utilitySection animated:NO];
    
    IQMenuSection* themeSection = [IQMenuSection sectionWithTitle:@"Themes"];
    [themeSection addItem:[IQMenuItem itemWithTitle:@"Default" action:^{
        [IQTheme setDefaultTheme:[[IQTheme alloc] init]];
    }] animated:NO];
    [themeSection addItem:[IQMenuItem itemWithTitle:@"social.css" action:^{
        [IQTheme setDefaultTheme:[IQMutableTheme themeFromCSSResource:@"social.css"]];
    }] animated:NO];
    [menu addSection:themeSection animated:NO];
    
    self.rootViewController = [[IQNavigationController alloc] initWithRootViewController:[self aboutViewController] sidebarViewController:menu];
    self.window.rootViewController = self.rootViewController;
    [self.window makeKeyAndVisible];
    //[[IQScreenRecorder screenRecorder] startSharingScreenWithPort:5900 password:nil];
    //[[IQScreenRecorder screenRecorder] performSelector:@selector(startMirroringScreen) withObject:NULL afterDelay:2000];
    //[[IQScreenRecorder screenRecorder] startMirroringScreen];
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}
- (void)applicationWillResignActive:(UIApplication *)application {
    //NSLog(@"I am resigning");
    //[[IQScreenRecorder screenRecorder] stopRecording];
}

@end

int main(int argc, char* argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([ExampleAppDelegate class]));
    }
}
