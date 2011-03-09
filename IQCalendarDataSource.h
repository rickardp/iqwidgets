//
//  IQCalendarDataSource.h
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-03-09.
//  Copyright 2011 Jeppesen. All rights reserved.
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
}

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
@end