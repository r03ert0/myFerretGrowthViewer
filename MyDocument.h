//
//  MyDocument.h
//  myGrowthViewer
//
//  Created by roberto on 05/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MyView.h"


@interface MyDocument : NSDocument
{
	IBOutlet MyView		*view;
}
-(IBAction)setStandardRotation:(id)sender;
-(IBAction)addRotation:(id)sender;
@end
