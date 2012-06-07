//
//  MainController.m
//  twTimer
//
//  Created by Gints Murāns on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainController.h"
#import "MainControllerLoginItems.h"
#import "twApi.h"
#import "AppDelegate.h"
#import "SBJson.h"

#import "macros.h"



/*
 |--------------------------------------------------------------------------
 | Carbon stuff
 |--------------------------------------------------------------------------
 */

#import <Carbon/Carbon.h>
OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, MainController *userData);
OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, MainController *userData)
{
    EventHotKeyID hkRef;     
    GetEventParameter(anEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,sizeof(hkRef),NULL,&hkRef);

    switch (hkRef.id)
    {
        case 3:
            if ([NSApp isActive] == NO)
            {
                break;
            }
        case 1:
            [(AppDelegate *)[[NSApplication sharedApplication] delegate] iconClicked:nil]; 
            break;
            
        case 2:
            [userData startButtonAction:nil];
            break;
    }
    return noErr;
}




/*
 |--------------------------------------------------------------------------
 | MainController implementation
 |--------------------------------------------------------------------------
 */

@implementation MainController

@synthesize 

    statusItem = _statusItem,
    mainMenu = _mainMenu,

    settingsView = _settingsView, 
    apiKeyTextField = _apiKeyTextField, statusMark = _statusMark, 

    mainView = _mainView, 
    textView = _textView, startButton = _startButton,
    datePicker = _datePicker, timeTextField = _timeTextField, billableCheckbox = _billableCheckbox, 
    selectedProject = _selectedProject, projectsDropDownSource = _projectsDropDownSource,

    isStarted = _isStarted, isPaused = _isPaused;


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [NSEvent removeMonitor:self];
    
    [super dealloc];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        /*
         |--------------------------------------------------------------------------
         | Setup views, frames and superviews
         |--------------------------------------------------------------------------
         */
        [_mainView setFrame:self.view.frame];
        [self.view addSubview:_mainView];

        [_settingsView setFrame:self.view.frame];
        [_settingsView setHidden:YES];
        [self.view addSubview:_settingsView];
        
        [self.timeTextField setDelegate:self];

        /*NoodleLineNumberView *lineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:self.scrollView];
        [self.scrollView setVerticalRulerView:lineNumberView];
        [self.scrollView setHasHorizontalRuler:NO];
        [self.scrollView setHasVerticalRuler:YES];
        [self.scrollView setRulersVisible:YES];*/

        
        /*
         |--------------------------------------------------------------------------
         | Settings
         |--------------------------------------------------------------------------
         */
        settings = [NSUserDefaults standardUserDefaults];

        // Register defaults
        NSDictionary *defaults = [[NSDictionary alloc] initWithObjectsAndKeys:@"1", @"BillableChecked", @"00:00:00", @"TimeValue", nil];
        [settings registerDefaults:defaults];
        [defaults release];


        // Fill variables
        testPassed = [settings boolForKey:@"TestPassed"];
        apiKey = [[settings objectForKey:@"ApiKey"] copy];
        apiUrl = [[settings objectForKey:@"ApiUrl"] copy];
        apiPersonId = [[settings objectForKey:@"ApiPersonId"] copy];
        projects = [[settings objectForKey:@"Projects"] copy];


        // Fill fields
        self.startButton.title = @"Start";
        self.timeTextField.stringValue = [settings objectForKey:@"TimeValue"];
        self.textView.string = [settings objectForKey:@"TextValue"];
        self.datePicker.dateValue = [settings objectForKey:@"DateValue"];
        // self.selectedProject = [settings objectForKey:@"SelectedProject"];
        
        [self.billableCheckbox setState:[settings integerForKey:@"BillableChecked"]];

        self.isStarted = [settings boolForKey:@"IsStarted"];
        // self.isPaused = [settings boolForKey:@"isPaused"];

        if (self.isStarted == YES)
        {
            [self startButtonAction:nil];
        }
        else
        {
            self.datePicker.dateValue = [NSDate date];
        }


        /*
         |--------------------------------------------------------------------------
         | Take user to the settings page if there is no settings saved ortherwise load projects
         |--------------------------------------------------------------------------
         */
        if (apiUrl == nil)
        {
            [self infoButtonAction:nil];
        }
        else
        {
            [self fillProjects];
            [twApi loadProjects:^(BOOL success, id data, id userInfo) {
                if (success == YES)
                {
                    if ([[data objectForKey:@"STATUS"] isEqualToString:@"OK"] == YES)
                    {
                        projects = [[data objectForKey:@"projects"] copy];
                        [[NSUserDefaults standardUserDefaults] setObject:projects forKey:@"Projects"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [self fillProjects];
                    }
                }
                else
                {
                    [self setTest:success];
                }
            }];
        }


        /*
         |--------------------------------------------------------------------------
         | Register for some notifications
         |--------------------------------------------------------------------------
         */
        // NSApplicationWillBecomeActiveNotification
        // NSApplicationWillResignActiveNotification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidShow) name:@"windowDidShow" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidHide) name:@"windowDidHide" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:@"NSApplicationWillTerminateNotification" object:nil];
        
        
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(stopTimerEvent:) name:@"com.apple.screensaver.didstart" object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(stopTimerEvent:) name:@"com.apple.screenIsLocked" object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerEvent:) name:@"com.apple.screensaver.didstop" object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerEvent:) name:@"com.apple.screenIsUnlocked" object:nil];
        
        
        /*
         |--------------------------------------------------------------------------
         | Register Hotkeys
         |--------------------------------------------------------------------------
         */
        [NSApp setMainMenu:self.mainMenu];

        // Carbon
        EventHotKeyRef myHotKeyRef;
        EventHotKeyID myHotKeyID;
        EventTypeSpec eventType;
        
        eventType.eventClass = kEventClassKeyboard;
        eventType.eventKind = kEventHotKeyPressed;
        InstallApplicationEventHandler(&myHotKeyHandler,1,&eventType,self,NULL);
        
        myHotKeyID.signature = 'mhk1';
        myHotKeyID.id = 1;

        RegisterEventHotKey(47/*>*/, cmdKey+shiftKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
        
        myHotKeyID.signature = 'mhk2';
        myHotKeyID.id = 2;
        
        RegisterEventHotKey(10/*#*/, cmdKey+shiftKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);

        /*
        myHotKeyID.signature = 'mhk3';
        myHotKeyID.id = 3;
        
        RegisterEventHotKey(53, 0, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
        */
        // -- Carbon
    }
    
    return self;
}






#pragma mark - Custom methods

- (BOOL)test
{
    if (testPassed == YES)
    {
        return YES; 
    }

    NSAlert *myAlert = [[NSAlert alloc] init];
    [myAlert setMessageText:@"Api test have failed or haven't been done."];
    [myAlert addButtonWithTitle:@"Ok"];
    [myAlert addButtonWithTitle:@"Cancel"];
    
    switch ([myAlert runModal]) {
        case NSAlertFirstButtonReturn:
            [self infoButtonAction:nil];
            break;
        case NSAlertSecondButtonReturn:
            break;
    }
    [myAlert release];

    return NO;
}


- (void)setTest:(BOOL)success
{
    testPassed = success;
    [settings setBool:success forKey:@"TestPassed"];
}


- (void)fillProjects
{
    if (projects != nil)
    {
        self.selectedProject = [settings objectForKey:@"SelectedProject"];
        [self.projectsDropDownSource setContent:projects];
    }
}



- (void)setTestStatus:(BOOL)status
{
    if (status == YES)
    {
        [_statusMark setImage:[NSImage imageNamed:@"accept"]];
    }
    else
    {
        [_statusMark setImage:[NSImage imageNamed:@"error"]];
    }
}

- (void)clearTestStatus
{
    [_statusMark setImage:nil];
}



- (void)saveFields
{
    [self.view.window makeFirstResponder:nil];
    
    [settings setObject:self.timeTextField.stringValue forKey:@"TimeValue"];
    [settings setObject:self.textView.string forKey:@"TextValue"];
    [settings setObject:self.datePicker.dateValue forKey:@"DateValue"];

    [settings setBool:self.isStarted forKey:@"IsStarted"];
    // [settings setBool:self.isPaused forKey:@"isPaused"];

    [settings setObject:self.selectedProject forKey:@"SelectedProject"];
    [settings setInteger:self.billableCheckbox.state forKey:@"BillableChecked"];

    [settings synchronize];
}



- (void)updateTime:(NSTimer *)sender
{
    int hours = 0, minutes = 0, seconds = 0;
    NSArray *timeArray = [self.timeTextField.stringValue componentsSeparatedByString:@":"];    

    hours = [[timeArray objectAtIndex:0] intValue];
    
    if ([timeArray count] > 1)
    {
        minutes = [[timeArray objectAtIndex:1] intValue];
    }
    if ([timeArray count] > 2)
    {
        seconds = [[timeArray objectAtIndex:2] intValue];
    }

    seconds += 1;
    if (seconds == 60)
    {
        minutes += 1;
        seconds = 0;
    }
    if (minutes == 60)
    {
        hours += 1;
        minutes = 0;
    }

    self.timeTextField.stringValue = [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}





#pragma mark - NSNotifications

- (void)windowDidShow
{
    [self.view.window makeFirstResponder:self.textView];
}

- (void)windowDidHide
{
    [self saveFields];
}


- (void)appWillTerminate
{
    [self saveFields];
}


- (void)stopTimerEvent:(id)sender
{
    if (self.isStarted == YES && self.isPaused == NO)
    {
        [self startButtonAction:nil];
        startTimerAfterLockDown = YES;
    }
}


- (void)startTimerEvent:(id)sender
{
    if (startTimerAfterLockDown == YES)
    {
        [self startButtonAction:nil];
        startTimerAfterLockDown = NO;
    }
}



#pragma mark - MainView GUI IBActions


- (void)infoButtonAction:(NSButton *)sender
{
    // Set apiKey and apiUrl
    if (apiKey != nil)
    {
        [_apiKeyTextField setStringValue:apiKey];
    }

    // Set whether test has been passed or not
    [self setTestStatus:testPassed];

    // Do some position calculations and animations
    NSRect frame = _mainView.frame;
    frame.origin.x += frame.size.width;

    [_settingsView setFrame:frame];
    [_settingsView setHidden:NO];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.3f];

    frame.origin.x -= frame.size.width;
    [[_settingsView animator] setFrame:frame];

    frame.origin.x -= frame.size.width;
    [[_mainView animator] setFrame:frame];

    [NSAnimationContext endGrouping];
}


- (IBAction)startButtonAction:(NSButton *)sender
{
    if (self.isStarted == NO || self.isPaused == YES)
    {
        if (self.isPaused == NO)
        {
            self.datePicker.dateValue = [NSDate date];
        }

        mainTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];

        self.isPaused = NO;
        self.isStarted = YES;
        self.startButton.title = @"Pause";
        [self.statusItem setTitle:@"..."];
    }
    else
    {
        [mainTimer invalidate], mainTimer = nil;
        self.isPaused = YES;
        self.startButton.title = @"Resume";
        [self.statusItem setTitle:DEFAULT_STATUSBAR_CHAR];
    }
}


- (IBAction)cancelButtonAction:(NSButton *)sender
{
    if (sender != nil)
    {
        NSAlert *myAlert = [[NSAlert alloc] init];
        [myAlert setMessageText:@"Are you sure want to cancel the time"];
        [myAlert addButtonWithTitle:@"Ok"];
        [myAlert addButtonWithTitle:@"Cancel"];
        
        switch ([myAlert runModal]) {
            case NSAlertFirstButtonReturn:
                // Do nothing
                break;
            case NSAlertSecondButtonReturn:
                return;
                break;
        }
        [myAlert release];
    }

    if (mainTimer != nil)
    {
        [mainTimer invalidate];
    }

    self.datePicker.dateValue = [NSDate date];
    self.isStarted = NO;
    self.isPaused = NO;
    self.startButton.title = @"Start";
    self.textView.string = @"";
    self.timeTextField.stringValue = @"00:00:00";
    
    [self saveFields];
}


- (IBAction)logButtonAction:(NSButton *)sender
{
    if ([self test] == NO)
    {
        return;
    }

    
    if ([self.timeTextField.stringValue length] == 0)
    {
        return;
    }
    
    
    // Check if time field is valid
    NSString *hours = [self.timeTextField.stringValue substringWithRange:NSMakeRange(0, 2)];
    NSString *minutes = [self.timeTextField.stringValue substringWithRange:NSMakeRange(3, 2)];

    if ([hours intValue] + [minutes intValue] <= 0)
    {
        NSAlert *myAlert = [[NSAlert alloc] init];
        [myAlert setMessageText:@"There is no time to log"];
        [myAlert addButtonWithTitle:@"Ok"];
        [myAlert release];
        return;
    }

    // Get dates and times
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd"];
    NSString *date = [dateFormat stringFromDate:self.datePicker.dateValue];

    [dateFormat setDateFormat:@"hh:mm"];
    NSString *time = [dateFormat stringFromDate:self.datePicker.dateValue];
    [dateFormat release];

    // Make post data
    NSDictionary *post = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObjectsAndKeys:apiPersonId, @"person-id", self.textView.string, @"description", date, @"date", hours, @"hours", minutes, @"minutes", time, @"time", (self.billableCheckbox.state == NSOnState ? @"YES" : @"NO"), @"isbillable", @"0", @"todo-item-id", nil] forKey:@"time-entry"];
    
    // Post away
    [twApi logTime:self.selectedProject withData:[post JSONRepresentation] withCallback:^(BOOL success, id _data, id userInfo) 
    {
        if (success == YES)
        {
            NSString *status = [_data objectForKey:@"STATUS"];
            if (status == nil || [status isEqualToString:@"OK"] == NO)
            {
                NSAlert *myAlert = [[NSAlert alloc] init];
                [myAlert setMessageText:[NSString stringWithFormat:@"There was an error returned from api server: %@", [_data JSONRepresentation]]];
                [myAlert addButtonWithTitle:@"Ok"];
                [myAlert runModal];
                [myAlert release];
            }
            else 
            {
                [self cancelButtonAction:nil];
            }
        }
        else
        {
            [self setTest:success];
            [self test];
        }
    }];
}


- (IBAction)billableChecboxAction:(NSButton *)sender
{
    // NSLog(@"aa: %i", (int)sender.state);
}


- (void)projectsMenuAction:(NSPopUpButton *)sender
{
}


- (void)historyButtonAction:(NSButton *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@projects/%@/time", apiUrl, self.selectedProject]]];
}




#pragma mark - SettingsView GUI IBActions

- (void)testAction:(NSButton *)sender
{
    // Clear previous test status
    [sender setEnabled:NO];
    [self clearTestStatus];

    // Do some testing first
    if (_apiKeyTextField.stringValue.length <= 10)
    {
        [self setTestStatus:NO];
        return;
    }

    // Make a request
    [apiKey release];
    apiKey = [_apiKeyTextField.stringValue copy];
    [twApi autheticate:^(BOOL success, id data, id userInfo) {

        // Reenable button
        [sender setEnabled:YES];

        // Update settings for the test
        [settings setBool:success forKey:@"TestPassed"];
        testPassed = success;

        if (success == NO)
        {
            [self setTestStatus:NO];
            apiUrl = @"";
            apiPersonId = @"";
        }
        else
        {
            [self setTestStatus:YES];
            apiUrl = [[[data objectForKey:@"account"] objectForKey:@"URL"] copy];
            apiPersonId = [[[data objectForKey:@"account"] objectForKey:@"userId"] copy];
            [twApi loadProjects:^(BOOL success, id data, id userInfo) {
                if (success == YES)
                {
                    [self fillProjects];
                }                
            }];
        }
    }];
}


- (void)saveAction:(NSButton *)sender
{
    // Animate stuff
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.3f];

    NSRect frame = _settingsView.frame;
    frame.origin.x += frame.size.width;
    [[_settingsView animator] setFrame:frame];

    frame.origin.x -= frame.size.width;
    [[_mainView animator] setFrame:frame];

    [NSAnimationContext endGrouping];


    // While animating save settings
    [apiKey release];
    apiKey = [_apiKeyTextField.stringValue copy];

    [settings setObject:apiUrl forKey:@"ApiUrl"];
    [settings setObject:apiKey forKey:@"ApiKey"];
    [settings setObject:apiPersonId forKey:@"ApiPersonId"];
    [settings synchronize];
}


- (void)quitApplication:(NSButton *)sender
{
    [NSApp terminate:nil];
}


- (IBAction)toggleLoginItem:(NSButton *)sender
{
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) 
    {
		if ([sender state] == NSOnState)
        {
			[self enableLoginItemWithLoginItemsReference:loginItems ForPath:appPath];
        }
		else
        {
			[self disableLoginItemWithLoginItemsReference:loginItems ForPath:appPath];
        }
	}
	CFRelease(loginItems);
}



#pragma mark - NSTextField Delegate

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
    if (self.isPaused == NO)
    {
        [self startButtonAction:self.startButton];
    }
    return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if (self.isStarted == YES && self.isPaused == YES)
    {
        [self startButtonAction:self.startButton];
    }
    return YES;
}

@end
