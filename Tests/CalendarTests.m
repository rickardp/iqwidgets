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

#import "CalendarTests.h"


NSDate* __D(SenTestCase* self, NSString* str)
{
    static NSDateFormatter* df = nil;
    if(df == nil) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm"];
    }
    NSDate* date = [df dateFromString:str];
    STAssertNotNil(date, @"Bad date format");
    return date;
}

@implementation CalendarTests

@end
