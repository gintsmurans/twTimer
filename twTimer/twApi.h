//
//  twApi.h
//  twTimer
//
//  Created by Gints Murāns on 2/25/12.
//  Copyright (c) 2012 Swedbank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FetchUri.h"

@interface twApi : NSObject

+ (void)autheticate:(CallbackBlock)callback;

+ (void)loadProjects:(CallbackBlock)callback;
+ (void)loadTimes:(CallbackBlock)callback;

+ (void)logTime:(NSString *)projectId withData:(id)data withCallback:(CallbackBlock)callback;

@end

NSString *apiUrl;
NSString *apiKey;
