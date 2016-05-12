//
//  AppDelegate.m
//  myGrowthViewer
//
//  Created by roberto on 05/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate
-(void)applicationDidFinishLaunching:(NSNotification*)n
{
	printf("blip!\n");
}
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

@end
