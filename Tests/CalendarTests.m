//
//  CalendarTests.m
//  IQWidgets for iOS
//
//  Copyright 2011 EvolvIQ
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
#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "TestUtil.h"
#import "IQWidgets.h"

@interface CalendarTests : XCTestCase {

}
@end

@implementation CalendarTests

- (void)testMonthLogic
{
    IQCalendarView* cv = [[IQCalendarView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    [cv setCurrentDay:D(@"2011-03-06 00:00") display:YES animated:NO];
    
    BOOL isSwedish = [[[NSLocale currentLocale] localeIdentifier] isEqualToString:@"SV_se"];
    
    XCTAssertEqualObjects(cv.firstDayInDisplayMonth, D(@"2011-03-01 00:00"), @"Invalid start date");
    XCTAssertEqualObjects(cv.firstDisplayedDay, isSwedish ? D(@"2011-02-28 00:00") : D(@"2011-02-27 00:00"), @"Invalid start date");
    XCTAssertEqualObjects(cv.lastDayInDisplayMonth, D(@"2011-03-31 00:00"), @"Invalid start date");
    XCTAssertEqualObjects(cv.lastDisplayedDay, isSwedish ? D(@"2011-04-03 00:00") : D(@"2011-04-02 00:00"), @"Invalid start date");
}

- (void)testBasicDateLogic
{
    IQCalendarView* cv = [[IQCalendarView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    XCTAssertEqualObjects([cv dayForDate:D(@"2011-03-06 13:24")], D(@"2011-03-06 00:00"), @"Failed start-of-day");
    NSMutableSet* s = [NSMutableSet set];
    [s addObject:[cv dayForDate:D(@"2011-03-06 13:24")]];
    XCTAssertTrue([s containsObject:D(@"2011-03-06 00:00")], @"Date not suitable in set");
}

@end



NSDate* __D(XCTestCase* self, NSString* str)
{
    static NSDateFormatter* df = nil;
    if(df == nil) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm"];
    }
    NSDate* date = [df dateFromString:str];
    XCTAssertNotNil(date, @"Bad date format");
    return date;
}

void __NEED_UI()
{
    if([UIApplication sharedApplication] == nil) {
        printf("(Creating UIApplication loophole for unit testing. If you see this in the application things will go BAD)\n");
        static jmp_buf buf;
        if(!setjmp(buf)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                longjmp(buf, 0);
            });
            UIApplicationMain(2, (char*[]){"unittest","-RegisterForSystemEvents"}, nil, nil);
        }
    }
}
