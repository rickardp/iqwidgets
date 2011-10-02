//
//  ExampleViewController.m
//  IQWidgets
//
//  Created by Rickard Petzäll on 2011-10-01.
//  Copyright (c) 2011 EvolvIQ. All rights reserved.
//

#import "ExampleViewController.h"

@implementation ExampleViewController

+ (ExampleViewController*) exampleViewController
{
    return [[[ExampleViewController alloc] init] autorelease];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}

@end
