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
#import "IQWidgets.h"
#import <QuartzCore/QuartzCore.h>

#define NVIEWS 10
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
            [self setStartDate:[NSDate date] numberOfDays:1 animated:YES];
            break;
        case 1:
            [self setStartDate:[[NSDate date] dateByAddingTimeInterval:1440*60] numberOfDays:1 animated:YES];
            break;
        case 2:
            [self setWeekWithDate:[NSDate date] workdays:YES animated:YES];
            break;
        case 3:
            [self setWeekWithDate:[NSDate date] workdays:NO animated:YES];
            break;
    }
}
@end

@implementation IQCalendarView (ControlExtensions)
- (void) didSelectMode:(id) sender {
    UISegmentedControl* ctl = sender;
    switch(ctl.selectedSegmentIndex) {
        case 0:
            [self setSelectionMode:IQCalendarSelectionRange];
            break;
        case 1:
            [self setSelectionMode:IQCalendarSelectionRangeStart];
            break;
        case 2:
            [self setSelectionMode:IQCalendarSelectionRangeEnd];
            break;
    }
}

- (void) testMe:(id)sender {
    NSLog(@"Testing control event generation from %@", sender);
}
@end

@implementation UILabel (ControlExtensions)

- (void) exampleUpdateText {
    static int toggleCount = 0;
    NSLog(@"Toggled switch");
    self.text = [NSString stringWithFormat:@"Toggle is %s (%d)", (toggleCount&1)?"ON":"OFF", toggleCount];
    toggleCount++;
}

@end

@implementation ExampleAppDelegate
@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return NVIEWS;
}

static ExampleViewController* WrapInController(UIView* view) {
	ExampleViewController* c = [[[ExampleViewController alloc] init] autorelease];
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
            [v setStartDate:[NSDate date] numberOfDays:1 animated:NO];
            [v setZoom:NSMakeRange(18, 22)];
            UISegmentedControl* selector = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Today",@"Tomorrow",@"Work week",@"Week",nil]] autorelease];
            selector.segmentedControlStyle = UISegmentedControlStyleBar;
            selector.selectedSegmentIndex = 0;
            [selector addTarget:v action:@selector(didSelectMode:) forControlEvents:UIControlEventValueChanged];
            ExampleViewController* vc = WrapInController(v);
            UIBarButtonItem* sys = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
            vc.toolbarItems = [NSArray arrayWithObjects:sys,[[[UIBarButtonItem alloc] initWithCustomView:selector] autorelease],sys,nil];
            NSMutableSet* items = [NSMutableSet set];
            NSTimeInterval t = [[NSDate date] timeIntervalSinceReferenceDate];
            t -= 15*3600;
            for(int i=0; i<30; i++) {
                t += 3600;
                t = floor(t/3600)*3600;
                [items addObject:[ExampleCalendarEntry exampleEntryWithText:@"Test" start:[NSDate dateWithTimeIntervalSinceReferenceDate:t] end:[NSDate dateWithTimeIntervalSinceReferenceDate:t+3600]]];
            }
            v.dataSource = [IQCalendarSimpleDataSource dataSourceWithSet:items];
            //vc.navigationItem.rightBarButtonItem = itm;
            return vc;
        }
		case 1:
		case 2:
        {
            IQCalendarView* cal = [[IQCalendarView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            UIViewController* vc = WrapInController(cal);
            if(idx == 2) {
                cal.selectionMode = IQCalendarSelectionRange;
                UISegmentedControl* selector = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Range",@"Start",@"End",nil]] autorelease];
                selector.segmentedControlStyle = UISegmentedControlStyleBar;
                selector.selectedSegmentIndex = 0;
                [selector addTarget:cal action:@selector(didSelectMode:) forControlEvents:UIControlEventValueChanged];
                UIBarButtonItem* sys = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
                vc.toolbarItems = [NSArray arrayWithObjects:sys,[[[UIBarButtonItem alloc] initWithCustomView:selector] autorelease],sys,nil];
            } else {
                [cal addTarget:cal action:@selector(testMe:) forControlEvents:UIControlEventValueChanged];
                cal.headerTextColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.7 alpha:1.0];
                cal.selectionMode = IQCalendarSelectionMulti;
                [cal setActiveSelectionRangeFrom:cal.firstDayInDisplayMonth to:cal.lastDayInDisplayMonth];
            }
            return vc;
        }
		case 3:
		case 4:
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
        case 5:
        {
            IQScrollView* scroll = [[IQScrollView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            
            //UILabel* header = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 44, 44)] autorelease];
            
            UIView* rheader = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)] autorelease];
            rheader.backgroundColor = [UIColor redColor];
            scroll.rowHeaderView = rheader;
            
            UIView* header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)] autorelease];
            //[header setText:@"This is a header label"];
            header.backgroundColor = [UIColor yellowColor];
            scroll.columnHeaderView = header;
            
            UIView* corner = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)] autorelease];
            corner.backgroundColor = [UIColor blueColor];
            scroll.cornerView = corner;
            
            UIImageView* imgv = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"test.png"]] autorelease];
            scroll.contentSize = imgv.bounds.size;
            [scroll addSubview:imgv];
            
            return WrapInController(scroll);
        }
        case 6:
        {
            int modo = 3;
            IQGanttView* gantt = [[IQGanttView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            for(NSString* resource in [NSArray arrayWithObjects:@"Alice",@"Bob",@"Cecil",@"David",nil]) {
                modo++;
                NSTimeInterval t = [[NSDate date] timeIntervalSinceReferenceDate];
                t -= 18*3600;
                NSMutableSet* items = [NSMutableSet set];
                NSTimeInterval tOld = t;
                for(int i=0; i<100; i++) {
                    t += 24*3600;
                    if((i+7) % modo != 0) continue;
                    if((i%6)==0) t = tOld+12*3600;
                    tOld = t;
                    t = floor(t/3600)*3600;
                    [items addObject:[ExampleCalendarEntry exampleEntryWithText:@"Test" start:[NSDate dateWithTimeIntervalSinceReferenceDate:t] end:[NSDate dateWithTimeIntervalSinceReferenceDate:t+24*3600]]];
                }
                [gantt addRow:[IQCalendarSimpleDataSource dataSourceWithName:resource set:items]];
            }
            return WrapInController(gantt);
        }
        case 7:
        {
            IQViewTessellation* tess = [[IQViewTessellation alloc] initWithFrame:CGRectMake(0, 0, 100, 100) withTilesHorizontal:8 vertical:24];
            tess.backgroundImage = [UIImage imageNamed:@"test.png"];
            UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(30, 120, 140, 30)];
            lbl.text = @"Hello, GL World!";
            lbl.opaque = NO;
            lbl.backgroundColor = [UIColor clearColor];
            lbl.font = [UIFont boldSystemFontOfSize:24];
            lbl.textColor = [UIColor blueColor];
            lbl.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
            lbl.shadowOffset = CGSizeMake(0, 4);
            [tess addSubview:lbl];
            UISwitch* sw = [[UISwitch alloc] initWithFrame:CGRectMake(180, 180, 100, 40)];
            [sw addTarget:lbl action:@selector(exampleUpdateText) forControlEvents:UIControlEventValueChanged];
            [tess addSubview:sw];
            tess.transformation = ^(CGPoint pt, CGFloat t) {
                if(t > 1) t -= floor(t);
                return IQMakePoint3(pt.x*(1+0.1*sin(5*pt.y+4*M_PI*t)), pt.y, 0.1*sin(5*pt.y+4*M_PI*t));
            };
            return WrapInController(tess);
        }
        case 8:
        {
            UIViewController* vc = [[[UIViewController alloc] init] autorelease];
            UIImageView* view1 = [[[UIImageView alloc] initWithFrame:vc.view.bounds] autorelease];
            UITextView* view2 = [[[UITextView alloc] initWithFrame:vc.view.bounds] autorelease];
            view1.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            view2.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            view1.image = [UIImage imageNamed:@"test.png"];
            view2.text = @"\nHello, world of beautiful custom OpenGL view transitions.\n\nYou can customize me with a simple transformation block. \n\nYour imagination is the limit to what kind of transformation effects you can do...";
            view2.textAlignment = UITextAlignmentCenter;
            NSLog(@"Adding view to %@", vc.view);
            [vc.view addSubview:view2];
            [vc.view addSubview:view1];
            //view1.opaque = NO;
            //view2.hidden = YES;
            //view2.backgroundColor = [UIColor clearColor];
            IQViewTesselationTransformation trans = ^(CGPoint pt, CGFloat t) {
                return IQMakePoint3(pt.x, pt.y+t, 0);
            };
            static IQTransitionCompletionBlock again2 = nil;
            IQTransitionCompletionBlock again = ^(UIView* fromView, UIView *toView) {
                NSLog(@"Restarting transition %@ -> %@", fromView, toView);
                fromView.hidden = NO;
                toView.hidden = YES;
                [IQViewTransition transitionFrom:toView to:fromView duration:2.0 withTransformation:trans completion:again2];
            };
            again2 = Block_copy(again);
            [IQViewTransition transitionFrom:view2 to:view1 duration:2.0 withTransformation:trans completion:again2];
            //again();
            return vc;
        }
        case 9:
        {
            ExampleViewController* vc = [ExampleViewController exampleViewController];
            IQDrawerView* topDrawer = [[[IQDrawerView alloc] initWithStyle:IQDrawerViewStyleBarDefault align:IQDrawerViewAlignTop] autorelease];
            [vc.view addSubview:topDrawer];
            UILabel* topLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)] autorelease];
            topLabel.text = @"This is the top drawer";
            topLabel.shadowOpacity = 0.55;
            topDrawer.contentView = topLabel;
            IQDrawerView* bottomDrawer = [[[IQDrawerView alloc] initWithStyle:IQDrawerViewStyleBarDefault align:IQDrawerViewAlignBottom] autorelease];
            [vc.view addSubview:view];
            UILabel* bottomLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)] autorelease];
            bottomLabel.text = @"This is the bottom drawer";
            bottomLabel.textAlignment = UITextAlignmentCenter;   
            bottomDrawer.shadowOpacity = 0.55;
            bottomDrawer.contentView = bottomLabel;
            return vc;
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
			title = @"IQCalendarView (range)";
			break;
		case 3:
			title = @"IQDrilldownController (mode 1)";
			break;
		case 4:
			title = @"IQDrilldownController (mode 2)";
			break;
        case 5:
            title = @"IQScrollView";
            break;
        case 6:
            title = @"IQGanttView";
            break;
        case 7:
            title = @"IQViewTessellation";
            break;
        case 8:
            title = @"IQViewTransition";
            break;
        case 9:
            title = @"IQDrawerView";
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
    //viewController.navigationBar.tintColor = [UIColor blueColor];
    NSLog(@"Tint: %@", viewController.navigationBar.tintColor);
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
