//
//  MainControllerLoginItems.h
//  twTimer
//
//  Created by Gints Murāns on 3/7/12.
//  Copyright (c) 2012 Swedbank. All rights reserved.
//

#import "MainController.h"

@interface MainController (LoginItems)

- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(NSString *)appPath;
- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(NSString *)appPath;

@end
