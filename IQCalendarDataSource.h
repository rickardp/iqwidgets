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

@protocol IQCalendarActivity <NSObject>
@optional
// IQCalendarActivity can be a simple string...
- (NSUInteger)length;
- (unichar)characterAtIndex:(NSUInteger)index;
// Note that none of the calender-widgets require an IQCalendarActivity to understand
// its start and end times.
@end

typedef void (^IQCalendarDataSourceEntryCallback)(NSTimeInterval startDate, NSTimeInterval endDate, NSObject<IQCalendarActivity>* value);
typedef NSObject<IQCalendarActivity>* (^IQCalendarDataSourceValueExtractor)(id item);
typedef NSTimeInterval (^IQCalendarDataSourceTimeExtractor)(id item);

@protocol IQCalendarDataSource <NSObject>
@required
- (void) enumerateEntriesUsing:(IQCalendarDataSourceEntryCallback)enumerator from:(NSTimeInterval)startTime to:(NSTimeInterval)endTime;
@optional
- (NSString*) labelText;
- (NSString*) themeClassName;
@end

@protocol IQCalendarSimpleDataItem <NSObject>
@required
- (NSDate*) startDate;
- (NSDate*) endDate;
@optional
- (NSObject<IQCalendarActivity>*) value;
@end

// IQCalendarDataSource implementation that uses a collection of objects
// and customizable callbacks to these. If no callbacks are set,
// the default is to assume the item implements the IQCalendarSimpleDataItem
// protocol.
@interface IQCalendarSimpleDataSource : NSObject<IQCalendarDataSource>

+ (IQCalendarSimpleDataSource*) dataSourceWithLabel:(NSString*)label set:(NSSet*)items;
+ (IQCalendarSimpleDataSource*) dataSourceWithLabel:(NSString*)label array:(NSArray*)items;
+ (IQCalendarSimpleDataSource*) dataSourceWithSet:(NSSet*)items;
+ (IQCalendarSimpleDataSource*) dataSourceWithArray:(NSArray*)items;

- (id) initWithSet:(NSSet*)items;
- (id) initWithArray:(NSArray*)items;

// Key/value coding (uses blocks internally)
- (void) setKeysForStartDate:(NSString*)startDateKey endDate:(NSString*)endDateKey;
// - (NSString*)textSelector:(id)item;
- (void) setKeyForValue:(NSString*)valueKey;

@property (nonatomic, retain) NSString* labelText;
@property (nonatomic, retain) NSString* themeClassName;

@property (nonatomic, copy) IQCalendarDataSourceTimeExtractor startDateCallback;
@property (nonatomic, copy) IQCalendarDataSourceTimeExtractor endDateCallback;
@property (nonatomic, copy) IQCalendarDataSourceValueExtractor valueCallback;
@end