
#import <Foundation/Foundation.h>
#import "XMLRPCConnectionDelegate.h"

@class XMLRPCConnectionManager, XMLRPCRequest, XMLRPCResponse;

@interface XMLRPCConnection : NSObject

@property (strong, readonly) NSString *identifier;
@property (strong, readonly) id<XMLRPCConnectionDelegate> delegate;

+ (XMLRPCResponse *)sendSynchronousXMLRPCRequest:(XMLRPCRequest *)aRequest error:(NSError **)error;

- (id)initWithXMLRPCRequest:(XMLRPCRequest *)aRequest delegate:(id<XMLRPCConnectionDelegate>)aDelegate manager:(XMLRPCConnectionManager *)aManager;
- (void)cancel;

@end
