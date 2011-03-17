//
//  IQCalendarDataSource.h
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

#import <Foundation/Foundation.h>

typedef void (^IQCalendarDataSourceEntryCallback)(id item, NSTimeInterval startDate, NSTimeInterval endDate);
typedef NSString* (^IQCalendarDataSourceTextExtractor)(id item);
typedef NSTimeInterval (^IQCalendarDataSourceTimeExtractor)(id item);

@protocol IQCalendarDataSource <NSObject>
@required
- (void) enumerateEntriesUsing:(IQCalendarDataSourceEntryCallback)enumerator from:(NSTimeInterval)startTime to:(NSTimeInterval)endTime;
@optional
- (NSString*) textForItem:(id)item;
- (NSString*) labelText;
@end

// IQCalendarDataSource implementation that uses a collection of objects
// and customizable callbacks to these. If no callback, selector or key is set,
// the default is to perform the following selectors on the object:
//  - (NSDate*) startDate;
//  - (NSDate*) endDate;
//  - (NSString*) text;
@interface IQCalendarSimpleDataSource : NSObject<IQCalendarDataSource> {
@private
    NSObject<NSFastEnumeration>* data;
    IQCalendarDataSourceTimeExtractor startDateOfItem, endDateOfItem;
    IQCalendarDataSourceTextExtractor textOfItem;
    NSString* labelText;
}

+ (IQCalendarSimpleDataSource*) dataSourceWithName:(NSString*)name set:(NSSet*)items;
+ (IQCalendarSimpleDataSource*) dataSourceWithName:(NSString*)name array:(NSArray*)items;
+ (IQCalendarSimpleDataSource*) dataSourceWithSet:(NSSet*)items;
+ (IQCalendarSimpleDataSource*) dataSourceWithArray:(NSArray*)items;

- (id) initWithSet:(NSSet*)items;
- (id) initWithArray:(NSArray*)items;

// Blocks (recommended)
- (void) setCallbacksForStartDate:(IQCalendarDataSourceTimeExtractor)startDateCallback endDate:(IQCalendarDataSourceTimeExtractor)endDateCallback;
- (void) setCallbackForText:(IQCalendarDataSourceTextExtractor)textCallback;

// Selectors (uses blocks internally)
// - (NSDate*)startEndDateSelector;
- (void) setSelectorsForStartDate:(SEL)startDateSelector endDate:(SEL)endDateSelector;
// - (NSString*)textSelector;
- (void) setSelectorForText:(SEL)textSelector;

// Key/value coding (uses blocks internally)
- (void) setKeysForStartDate:(NSString*)startDateKey endDate:(NSString*)endDateKey;
// - (NSString*)textSelector:(id)item;
- (void) setKeyForText:(NSString*)textKey;

@property (nonatomic, retain) NSString* labelText;
@end