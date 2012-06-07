//
//  FetchUri.h
//  Draugiem Pele
//
//  Created by Gints Murāns on 1/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define APP_CHECK_NETWORK_BY_DOMAIN "www.google.com"


typedef void (^CallbackBlock)(BOOL success, id data, id userInfo);


@interface FetchUri : NSObject <NSURLConnectionDelegate>
{
    NSMutableURLRequest *request;
	NSMutableData *responseData;
    NSData *postData;
}

@property (nonatomic, assign) int requestType;
@property (nonatomic, assign) BOOL debug;

@property (nonatomic, copy) CallbackBlock callback;
@property (nonatomic, retain) id userInfo;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;


+ (BOOL)isDataSourceAvailable;
+ (NSString *)escapePostData:(NSString *)value;

+ (BOOL)loadFile:(NSString *)uri withRequestType:(int)requestType withCallback:(CallbackBlock)callback withUserInfo:(id)userInfo withHeaders:(NSArray *)headers;

- (void)get:(NSString *)uri withHeaders:(NSArray *)headers;
- (void)post:(NSString *)uri withData:(id)data withHeaders:(NSArray *)headers;
- (void)restart;

@end


#pragma mark - Some variables

NSString *FetchUri_ValidDomain;
BOOL FetchUri_CheckNetwork;
BOOL FetchUri_Debug;

