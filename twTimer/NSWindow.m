//
//  NSWindow.m
//  twTimer
//
//  Created by Gints Murāns on 2/17/12.
//  Copyright (c) 2012 Swedbank. All rights reserved.
//

#import "NSWindow.h"

@implementation NSWindow (canBecomeKeyWindow)

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end