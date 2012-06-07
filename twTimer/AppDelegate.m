//
//  AppDelegate.m
//  twTimer
//
//  Created by Gints Murāns on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
// #import "NSWindow.h"
#import "macros.h"

@implementation AppDelegate

@synthesize attachedWindow = _attachedWindow, statusItem = _statusItem, mainController = _mainController;




- (void)dealloc
{
    [_mainController release], _mainController = nil;
    [_attachedWindow release], _attachedWindow = nil;
    [_statusItem release], _statusItem = nil;
    [super dealloc];
}




- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /*
     |--------------------------------------------------------------------------
     | Init status item
     |--------------------------------------------------------------------------
     */
    self.statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:20] retain];
    [_statusItem setAction:@selector(iconClicked:)];
    [_statusItem setHighlightMode:YES];
    [_statusItem setTarget:self];
    [_statusItem setTitle:DEFAULT_STATUSBAR_CHAR];

    
    /*
     |--------------------------------------------------------------------------
     | Init main controller
     |--------------------------------------------------------------------------
     */
    self.mainController = [[MainController alloc] init];
    [_mainController setStatusItem:_statusItem];


    /*
     |--------------------------------------------------------------------------
     | Create attached window
     |--------------------------------------------------------------------------
     */
    self.attachedWindow = [[MAAttachedWindow alloc] initWithView:_mainController.view attachedToPoint:CGPointZero inWindow:nil onSide:MAPositionBottom atDistance:5.0];
    [_attachedWindow setArrowHeight:10];
    [_attachedWindow setArrowBaseWidth:15];
    [_attachedWindow setBorderWidth:1];
    [_attachedWindow setBorderColor:[NSColor darkGrayColor]];
    [_attachedWindow setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"Background"]]];
    [_attachedWindow setDelegate:self];
    [_attachedWindow setHidesOnDeactivate:YES];

    
    /*
     |--------------------------------------------------------------------------
     | Hide app
     |--------------------------------------------------------------------------
     */    
    startup = YES;
}


- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (startup == YES)
    {
        [NSApp hide:nil];
        startup = NO;
    }
}



#pragma mark - Icon Actions

- (void)iconClicked:(id)sender
{
    if ([NSApp isActive] == NO)
    {
        startup = NO;

        NSPoint statusItemPoint = [[_statusItem _window] frame].origin;
        statusItemPoint.y += 5;
        statusItemPoint.x += (20 / 2);

        [_attachedWindow setPoint:statusItemPoint];
        [_attachedWindow redisplay];

        [NSApp activateIgnoringOtherApps:YES];
        [_attachedWindow makeKeyAndOrderFront:nil];
    }
    else 
    {
        [NSApp hide:self];
    }
}



#pragma mark - NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"windowDidShow" object:self userInfo:nil];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"windowDidHide" object:self userInfo:nil];
}

- (void)applicationDidResignActive:(NSNotification *)notification
{
    [NSApp hide:self];
}


@end
