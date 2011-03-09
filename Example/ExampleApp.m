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
#import "IQWidgets.h"
#import <QuartzCore/QuartzCore.h>

#define NVIEWS 4
struct {
	UIView* view;
	UITableViewCell* cell;
} cells[NVIEWS];



@interface ExampleCalendarEntry : NSObject {
    NSDate* start, *end;
    NSString* text;
}

+ (ExampleCalendarEntry*) exampleEntryWithText:(NSString*)text start:(NSDate*)s end:(NSDate*)end;
- (NSString*) text;
- (NSDate*) startDate;
- (NSDate*) endDate;
@end

@implementation ExampleCalendarEntry
+ (ExampleCalendarEntry*) exampleEntryWithText:(NSString*)text start:(NSDate*)s end:(NSDate*)e
{
    ExampleCalendarEntry* ent = [[[ExampleCalendarEntry alloc] init] autorelease];
    if(ent == nil) return nil;
    ent->start = [s retain];
    ent->end = [e retain];
    ent->text = [text retain];
    return ent;
}
- (NSString*) text {
    return text;
}
- (NSDate*) startDate {
    return start;
}
- (NSDate*) endDate {
    return end;
}
- (UIColor*) color {
    return [UIColor redColor];
}
@end

@implementation IQScheduleView (ControlExtensions)
- (void) didSelectMode:(id) sender {
    UISegmentedControl* ctl = sender;
    switch(ctl.selectedSegmentIndex) {
        case 0:
            [self setStartDate:[NSDate date] numberOfDays:1];
            break;
        case 1:
            [self setStartDate:[[NSDate date] dateByAddingTimeInterval:1440*60] numberOfDays:1];
            break;
        case 2:
            [self setWeekWithDate:[NSDate date] workdays:YES];
            break;
        case 3:
            [self setWeekWithDate:[NSDate date] workdays:NO];
            break;
    }
}
@end

@implementation ExampleAppDelegate
@synthesize window;
@synthesize viewController;
- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return NVIEWS;
}

static UIViewController* WrapInController(UIView* view) {
	UIViewController* c = [[[UIViewController alloc] init] autorelease];
	c.view = [view autorelease];
	return c;
}

static UIViewController* GenerateRandomViewController() {
	UIViewController* c = [[[UIViewController alloc] init] autorelease];
	static int seed = 0;
	switch(seed++ % 3) {
		case 0:
			c.view.backgroundColor = [UIColor whiteColor];
			break;
		case 1:
			c.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
			break;
        default:
			c.view.backgroundColor = [UIColor lightGrayColor];
			break;
	}
    //c.view.layer.cornerRadius = 6.0;
    //c.view.opaque = NO;
	return c;
}

static UIViewController* CreateViewController(int idx) {
	switch(idx) {
		case 0:
        {
            IQScheduleView* v = [[IQScheduleView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            UISegmentedControl* selector = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Today",@"Tomorrow",@"Work week",@"Week",nil]] autorelease];
            selector.segmentedControlStyle = UISegmentedControlStyleBar;
            [v setStartDate:[NSDate date] numberOfDays:1];
            [v setZoom:NSMakeRange(18, 22)];
            selector.selectedSegmentIndex = 0;
            [selector addTarget:v action:@selector(didSelectMode:) forControlEvents:UIControlEventValueChanged];
            UIBarButtonItem* itm = [[[UIBarButtonItem alloc] initWithCustomView:selector] autorelease];
            UIViewController* vc = WrapInController(v);
            UIBarButtonItem* sys = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
            vc.toolbarItems = [NSArray arrayWithObjects:sys,itm,sys,nil];
            NSMutableSet* items = [NSMutableSet set];
            NSTimeInterval t1 = [[NSDate date] timeIntervalSinceReferenceDate];
            NSTimeInterval t = 0;
            [items addObject:[ExampleCalendarEntry exampleEntryWithText:@"Item 1" start:[NSDate dateWithTimeIntervalSinceReferenceDate:(int)t1 + 12*3600] end:[NSDate dateWithTimeIntervalSinceReferenceDate:(int)t1 + 15*3600]]];
            for(int i=0; i<10; i++) {
                t += 3600;
                [items addObject:[ExampleCalendarEntry exampleEntryWithText:@"Test" start:[NSDate dateWithTimeIntervalSinceNow:t] end:[NSDate dateWithTimeIntervalSinceNow:t+3600]]];
            }
            v.dataSource = [IQCalendarSimpleDataSource dataSourceWithSet:items];
            //vc.navigationItem.rightBarButtonItem = itm;
            return vc;
        }
		case 1:
            return WrapInController([[IQCalendarView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)]);
		case 2:
		case 3:
		{
			IQDrilldownController* drill = [[IQDrilldownController alloc] init];
			drill.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
			[drill pushViewController:GenerateRandomViewController() animated:NO];
			[drill pushViewController:GenerateRandomViewController() animated:NO];
			[drill pushViewController:GenerateRandomViewController() animated:NO];
			[drill setActiveIndex:0];
			if([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
				UILabel* lbl = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, drill.view.bounds.size.width, 100)] autorelease];
				lbl.text = @"Note: Designed for iPad";
				lbl.textAlignment = UITextAlignmentCenter;
				lbl.opaque = NO;
				lbl.textColor = [UIColor whiteColor];
				lbl.shadowColor = [UIColor darkGrayColor];
				lbl.shadowOffset = CGSizeMake(0, 2);
				lbl.backgroundColor = [UIColor clearColor];
				[drill.view addSubview:lbl];
			}
			drill.stopAtPartiallyVisibleNext = (idx == 2);
			return drill;
		}
		default:
			[NSException raise:@"Index out of bounds" format:@"Index %d out of bounds", idx];
			break;
	}
	return nil;
}

static UITableViewCell* CreateCell(int idx) {
	NSString* title = @"";
	switch(idx) {
		case 0:
			title = @"IQScheduleView";
			break;
		case 1:
			title = @"IQCalendarView";
			break;
		case 2:
			title = @"IQDrilldownController (mode 1)";
			break;
		case 3:
			title = @"IQDrilldownController (mode 2)";
			break;
		default:
			[NSException raise:@"Index out of bounds" format:@"Index %d out of bounds", idx];
			break;
	}
	UITableViewCell* c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:title];
	[c.textLabel setText:title];
	return c;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int idx = [indexPath indexAtPosition:1];
	if(idx < 0 || idx >= NVIEWS) [NSException raise:@"Index out of bounds" format:@"Index %d out of bounds", idx];
	if(cells[idx].cell == nil) {
		cells[idx].cell = CreateCell(idx);
	}
	return cells[idx].cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	int idx = [indexPath indexAtPosition:1];
	if(idx < 0 || idx >= NVIEWS) [NSException raise:@"Index out of bounds" format:@"Index %d out of bounds", idx];
	UIViewController* c = CreateViewController(idx);
    c.navigationItem.title = cells[idx].cell.textLabel.text;
	//c.view.bounds = viewController.view.bounds;
	[viewController pushViewController:c animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end

int main(int argc, char* argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	UIApplicationMain(argc, argv, nil, nil);
	[pool release];
}
