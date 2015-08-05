
#import <Foundation/Foundation.h>

@interface XMLRPCResponse : NSObject

@property (strong, readonly) NSString *body;
@property (strong, readonly) id object;
@property (assign, readonly) BOOL fault;
@property (strong, readonly) NSNumber *faultCode;
@property (strong, readonly) NSString *faultString;


- (id)initWithData:(NSData *)theData;

@end
