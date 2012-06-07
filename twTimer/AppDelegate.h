//
//  AppDelegate.h
//  twTimer
//
//  Created by Gints Murāns on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainController.h"
#import "MAAttachedWindow.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate>
{
    BOOL startup;
}

@property (nonatomic,retain) NSStatusItem *statusItem;
@property (nonatomic,retain) MAAttachedWindow *attachedWindow;
@property (nonatomic,retain) MainController *mainController;

- (void)iconClicked:(id)sender;

@end
