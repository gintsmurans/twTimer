//
//  MainController.h
//  twTimer
//
//  Created by Gints Murāns on 2/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainController : NSViewController <NSTextFieldDelegate>
{
    NSUserDefaults *settings;
    BOOL testPassed;
    NSTimer *mainTimer;

    NSString *apiPersonId;
    NSArray *projects;
    
    BOOL startTimerAfterLockDown;
}


/*
 |--------------------------------------------------------------------------
 | Various methods
 |--------------------------------------------------------------------------
 */

- (BOOL)test;
- (void)setTest:(BOOL)success;
- (void)fillProjects;

- (void)setTestStatus:(BOOL)status;
- (void)clearTestStatus;

- (void)saveFields;


@property (assign) NSStatusItem *statusItem;
@property (assign) IBOutlet NSMenu *mainMenu;

/*
 |--------------------------------------------------------------------------
 | Settings View
 |--------------------------------------------------------------------------
 */

@property (assign) IBOutlet NSView *settingsView;
@property (assign) IBOutlet NSTextField *apiKeyTextField;
@property (assign) IBOutlet NSImageView *statusMark;

- (IBAction)testAction:(NSButton *)sender;
- (IBAction)saveAction:(NSButton *)sender;
- (IBAction)quitApplication:(NSButton *)sender;
- (IBAction)toggleLoginItem:(NSButton *)sender;


/*
 |--------------------------------------------------------------------------
 | Main View
 |--------------------------------------------------------------------------
 */

@property (assign) BOOL isStarted;
@property (assign) BOOL isPaused;

@property (nonatomic,retain) NSString *selectedProject;
@property (assign) IBOutlet NSArrayController *projectsDropDownSource;

@property (assign) IBOutlet NSView *mainView;
@property (assign) IBOutlet NSDatePicker *datePicker;
@property (assign) IBOutlet NSTextField *timeTextField;
@property (assign) IBOutlet NSButton *billableCheckbox;

@property (assign) IBOutlet NSTextView *textView;
@property (assign) IBOutlet NSButton *startButton;


- (IBAction)infoButtonAction:(NSButton *)sender;
- (IBAction)startButtonAction:(NSButton *)sender;
- (IBAction)cancelButtonAction:(NSButton *)sender;
- (IBAction)logButtonAction:(NSButton *)sender;
- (IBAction)billableChecboxAction:(NSButton *)sender;
- (IBAction)projectsMenuAction:(NSPopUpButton *)sender;

- (IBAction)historyButtonAction:(NSButton *)sender;

@end
