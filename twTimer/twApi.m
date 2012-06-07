//
//  twApi.m
//  twTimer
//
//  Created by Gints Murāns on 2/25/12.
//  Copyright (c) 2012 Swedbank. All rights reserved.
//

#import "twApi.h"

@implementation twApi


+ (void)autheticate:(CallbackBlock)callback
{
    FetchUri *tmp = [[FetchUri alloc] init];
    [tmp setRequestType:2];
    [tmp setUsername:apiKey];
    [tmp setPassword:@"none"];    
    [tmp setCallback:callback];

    [tmp get:@"http://authenticate.teamworkpm.net/authenticate.json" withHeaders:nil];
    [tmp release];
}


+ (void)loadProjects:(CallbackBlock)callback
{
    FetchUri *tmp = [[FetchUri alloc] init];
    [tmp setRequestType:2];
    [tmp setUsername:apiKey];
    [tmp setPassword:@"none"];    
    [tmp setCallback:callback];

    [tmp get:[NSString stringWithFormat:@"%@projects.json", apiUrl] withHeaders:nil];
    [tmp release];
}



+ (void)loadTimes:(CallbackBlock)callback
{
    
}



+ (void)logTime:(NSString *)projectId withData:(id)data withCallback:(CallbackBlock)callback
{
    FetchUri *tmp = [[FetchUri alloc] init];
    [tmp setRequestType:2];
    [tmp setUsername:apiKey];
    [tmp setPassword:@"none"];    
    [tmp setCallback:callback];

    NSArray *headers = [[NSArray alloc] initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Content-Type", @"name", @"text/plain;charset=utf-8", @"value", nil], nil];

    [tmp post:[NSString stringWithFormat:@"%@projects/%@/time_entries.json", apiUrl, projectId] withData:data withHeaders:headers];
    [tmp release];
    [headers release];
}


@end
