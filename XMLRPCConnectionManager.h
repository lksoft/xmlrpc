
#import <Foundation/Foundation.h>
#import "XMLRPCConnectionDelegate.h"

@class XMLRPCConnection, XMLRPCRequest;

@interface XMLRPCConnectionManager : NSObject

@property (strong, readonly) NSArray *activeConnectionIdentifiers;
@property (assign, readonly) NSUInteger numberOfActiveConnections;
@property (assign) BOOL shouldLogConnections;

+ (XMLRPCConnectionManager *)sharedManager;

- (NSString *)spawnConnectionWithXMLRPCRequest: (XMLRPCRequest *)request delegate: (id<XMLRPCConnectionDelegate>)delegate;
- (XMLRPCConnection *)connectionForIdentifier: (NSString *)identifier;
- (void)closeConnectionForIdentifier: (NSString *)identifier;
- (void)closeConnections;

@end
