//
//  ExampleViewController.m
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-10-01.
//  Copyright (c) 2011 EvolvIQ. All rights reserved.
//

#import "ExampleViewController.h"
#import "IQWidgets.h"

@implementation ExampleViewController

+ (ExampleViewController*) exampleViewController
{
    return [[ExampleViewController alloc] init];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}

- (void) loadView
{
    //self.view = [[IQCalendarView alloc] init];
}

@end
