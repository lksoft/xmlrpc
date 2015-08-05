
#import <Foundation/Foundation.h>

@class XMLRPCEventBasedParserDelegate;

@interface XMLRPCEventBasedParser : NSObject<NSXMLParserDelegate>
@property (strong, readonly) NSError *parserError;
@property (assign, readonly) BOOL fault;

- (id)initWithData: (NSData *)data;

- (id)parse;
- (void)abortParsing;

@end
