#import <Foundation/Foundation.h>

@class XMLRPCConnection, XMLRPCRequest, XMLRPCResponse;

@protocol XMLRPCConnectionDelegate<NSObject>

@required
- (void)request:(XMLRPCRequest *)request didReceiveResponse:(XMLRPCResponse *)response;

@optional
- (void)request:(XMLRPCRequest *)request didSendBodyData:(CGFloat)percent;

@required
- (void)request:(XMLRPCRequest *)request didFailWithError:(NSError *)error;

@required
- (BOOL)request:(XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;

@required
- (void)request:(XMLRPCRequest *)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@required
- (void)request:(XMLRPCRequest *)request didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end
