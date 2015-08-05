
#import "XMLRPCEventBasedParser.h"
#import "XMLRPCEventBasedParserDelegate.h"
#import "XMLRPCArc.h"


@interface XMLRPCEventBasedParser ()
@property (assign, readwrite) BOOL fault;
@property (strong) NSXMLParser *parser;
@property (strong) XMLRPCEventBasedParserDelegate *parserDelegate;
@end

@implementation XMLRPCEventBasedParser

- (id)initWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    if (self = [self init]) {
		self.parser = AUTORELEASE([[NSXMLParser alloc] initWithData:data]);
		self.parserDelegate = nil;
		self.fault = NO;
    }
    
    return self;
}

- (void)dealloc {
	self.parser = nil;
	self.parserDelegate = nil;
	DEALLOC(super);
}


#pragma mark - Actions

- (id)parse {
    [self.parser setDelegate:self];
    [self.parser parse];
    
    if ([self.parser parserError]) {
        return nil;
    }
    
    return [self.parserDelegate elementValue];
}

- (void)abortParsing {
    [self.parser abortParsing];
}

- (NSError *)parserError {
    return [self.parser parserError];
}


#pragma mark - Parser Delegation

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)element namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributes {
    if ([element isEqualToString:@"fault"]) {
        self.fault = YES;
    } else if ([element isEqualToString:@"value"]) {
        self.parserDelegate = [[XMLRPCEventBasedParserDelegate alloc] initWithParent: nil];
        [self.parser setDelegate:self.parserDelegate];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    [self abortParsing];
}

@end
