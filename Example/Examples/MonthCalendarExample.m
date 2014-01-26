//
//  MonthCalendarExample.m
//  IQWidgets
//
//  Created by Rickard Petzäll on 2012-10-12.
//
//

#import "MonthCalendarExample.h"
#import "IQWidgets.h"

@interface MonthCalendarExample ()

@end

@implementation MonthCalendarExample

- (void)loadView
{
    self.view = [[IQCalendarView alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
