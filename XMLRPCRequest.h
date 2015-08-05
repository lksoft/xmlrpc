
#import <Foundation/Foundation.h>

#import "XMLRPCEncoder.h"

@interface XMLRPCRequest : NSObject

@property (strong) NSString *userAgent;
@property (strong) NSString *method;
@property (strong) NSURL *URL;
@property (assign) NSTimeInterval timeout;
@property (strong) id<XMLRPCEncoder> encoder;
@property (strong) id extra;
@property (strong, readonly) NSArray *parameters;
@property (strong, readonly) NSString *body;
@property (strong, readonly) NSURLRequest *request;

- (id)initWithURL:(NSURL *)aURL;

#pragma mark -

- (void)setMethod:(NSString *)aMethod withParameter:(id)aParameter;
- (void)setMethod:(NSString *)aMethod withParameters:(NSArray *)theParameters;

- (void)setValue:(NSString *)aValue forHTTPHeaderField:(NSString *)aHeader;


@end
