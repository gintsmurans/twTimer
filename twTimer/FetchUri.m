//
//  FetchUri.m
//  Draugiem Pele
//
//  Created by Gints Murāns on 1/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import "FetchUri.h"
#import "SBJSON.h"

@implementation FetchUri

@synthesize callback = _callback, requestType = _requestType, userInfo = _userInfo, debug = _debug, username = _username, password = _password;



#pragma mark - Memory stuff

- (void)dealloc
{
    [_userInfo release];
    [_callback release];
    [_username release];
    [_password release];
    
    [responseData release];
    [request release];
    [postData release];
    [super dealloc];
}


#pragma mark - Request

+ (BOOL)isDataSourceAvailable
{
	static BOOL _isDataSourceAvailable = NO;

    // Check internet connection
    if (FetchUri_CheckNetwork == NO)
	{
        return YES;
    }
    
    /*SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, APP_CHECK_NETWORK_BY_DOMAIN);
    SCNetworkReachabilityFlags flags;

    BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
    _isDataSourceAvailable = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);

    CFRelease(reachability);

    // For caching the result
    checkNetwork = NO;*/

    // Show alert if there is no internet
    if (_isDataSourceAvailable == NO)
    {
    }		
    
    return _isDataSourceAvailable;
}


+ (NSString *)escapePostData:(NSString *)value
{
    return (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)value, NULL, (CFStringRef)@"!’\"();:@&=+$,/?%#[]% ", kCFStringEncodingUTF8);
}


+ (BOOL)loadFile:(NSString *)uri withRequestType:(int)requestType withCallback:(CallbackBlock)callback withUserInfo:(id)userInfo withHeaders:(NSArray *)headers
{
	if ([FetchUri isDataSourceAvailable] == NO)
	{
        if (callback != nil)
        {
            callback(NO, @"No internet connection", nil);
        }
        return NO;
    }

    FetchUri *tmp = [[FetchUri alloc] init];
    [tmp setCallback:callback];
    [tmp setDebug:FetchUri_Debug];
    [tmp setUserInfo:userInfo];
    [tmp setRequestType:requestType];
    [tmp get:uri withHeaders:headers];
    [tmp release];

    return YES;
}





#pragma mark - Load methods

- (void)get:(NSString *)uri withHeaders:(NSArray *)headers
{
    /*
     |--------------------------------------------------------------------------
     | Check for network
     |--------------------------------------------------------------------------
     */
	if ([FetchUri isDataSourceAvailable] == NO)
	{
        if (_callback != nil)
        {
            _callback(NO, @"No internet connection", _userInfo);
        }
        return;
    }

    
    /*
     |--------------------------------------------------------------------------
     | Create a request object
     |--------------------------------------------------------------------------
     */
    request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:uri] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];


    /*
     |--------------------------------------------------------------------------
     | Add aditional headers
     |--------------------------------------------------------------------------
     */
    if (headers != nil)
    {
        for (NSDictionary *header in headers)
        {
            [request setValue:[header objectForKey:@"value"] forHTTPHeaderField:[header objectForKey:@"name"]];
        }
    }

    
    /*
     |--------------------------------------------------------------------------
     | Make a connection
     |--------------------------------------------------------------------------
     */
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection release];
}



- (void)post:(NSString *)uri withData:(id)data withHeaders:(NSArray *)headers;
{
    /*
     |--------------------------------------------------------------------------
     | Check for network
     |--------------------------------------------------------------------------
     */
    if ([FetchUri isDataSourceAvailable] == NO)
    {
        if (_callback != nil)
        {
            _callback(NO, @"No internet connection", _userInfo);
        }
        return;
    }


    /*
     |--------------------------------------------------------------------------
     | Make post data
     |--------------------------------------------------------------------------
     */
    NSMutableString *postDataString = [[NSMutableString alloc] init];
    if ([data isKindOfClass:[NSString class]])
    {
        [postDataString appendString:data];
    }
    else
    {
        NSArray *allKeys = [data allKeys];
        for (NSString* key in allKeys)
        {
            if ([postDataString length] > 0)
            {
                [postDataString appendString:@"&"];
            }

            NSString *value = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[data objectForKey:key], NULL, (CFStringRef)@"!’\"();:@&=+$,/?%#[]% ", kCFStringEncodingUTF8);
            [postDataString appendFormat:@"%@=%@", key, value];
            [value release];
        }
        [postDataString appendFormat:@"&device=ios"];
    }


    /*
     |--------------------------------------------------------------------------
     | Make post NSData from NSString
     |--------------------------------------------------------------------------
     */
    postData = [[postDataString dataUsingEncoding:NSUTF8StringEncoding] retain];
    [postDataString release];


    /*
     |--------------------------------------------------------------------------
     | Create a request object
     |--------------------------------------------------------------------------
     */
    request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:uri] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody:postData];
    [request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];

    
    /*
     |--------------------------------------------------------------------------
     | Set additional headers
     |--------------------------------------------------------------------------
     */
    if (headers != nil)
    {
        for (NSDictionary *header in headers)
        {
            [request setValue:[header objectForKey:@"value"] forHTTPHeaderField:[header objectForKey:@"name"]];
        }
    }

    
    /*
     |--------------------------------------------------------------------------
     | Make a connection
     |--------------------------------------------------------------------------
     */
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection release];
}



- (void)restart
{
    if ([FetchUri isDataSourceAvailable] == NO)
    {
        if (_callback != nil)
        {
            _callback(NO, @"No internet connection", _userInfo);
        }
        return;
    }

    if (request == nil)
    {
        return;
    }
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection release];
}




#pragma mark - NSURLConnection Delegates

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (responseData != nil)
    {
        [responseData release];
    }
	responseData = [[NSMutableData alloc] init];

    if (_debug == YES)
    {
        NSLog(@"FetchUri Debug (headers): %ld %@", [(NSHTTPURLResponse *)response statusCode], [(NSHTTPURLResponse *)response allHeaderFields]);
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (_debug == YES)
    {
        NSLog(@"FetchUri Debug (error): %@", error);
    }
    
    if (self.callback != nil)
    {
        self.callback(NO, [error description], _userInfo);
    }
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (_debug == YES)
    {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"FetchUri Debug (success): %@", responseString);
        [responseString release];
    }

    if (self.callback != nil)
    {
        if (_requestType == 1)
        {
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            self.callback(YES, responseString, _userInfo);
            [responseString release];
        }
        else if (_requestType == 2)
        {
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            self.callback(YES, (responseString.length == 0 ? nil : [responseString JSONValue]), _userInfo);
            [responseString release];
        }
        else
        {
            self.callback(YES, responseData, _userInfo);
        }
    }
}



#pragma mark - Authetification and SSL stuff

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] || [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault]);
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] > 0)
    {
        if (self.callback != nil)
        {
            self.callback(NO, @"Bad Username Or Password", _userInfo);
        }
        return;
    }

	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		// We only trust our own domain
		if (FetchUri_ValidDomain != nil && [challenge.protectionSpace.host isEqualToString:FetchUri_ValidDomain])
		{
			NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
			[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
		}
	}
    else if ([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodDefault) 
    {
        NSURLCredential *newCredential = [NSURLCredential credentialWithUser:_username password:_password persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    }
}


@end