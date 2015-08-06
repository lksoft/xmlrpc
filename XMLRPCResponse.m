
#import "XMLRPCResponse.h"
#import "XMLRPCEventBasedParser.h"
#import "XMLRPCArc.h"


@interface XMLRPCResponse ()
@property (strong, readwrite) NSString *body;
@property (strong, readwrite) id object;
@property (assign, readwrite) BOOL fault;
@end


@implementation XMLRPCResponse

- (id)initWithData:(NSData *)theData {
    if (!theData) {
        return nil;
    }

    self = [super init];
    if (self) {
        XMLRPCEventBasedParser *parser = AUTORELEASE([[XMLRPCEventBasedParser alloc] initWithData:theData]);
        
        if (!parser) {
			RELEASE(self);
            return nil;
        }
    
		self.body = AUTORELEASE([[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding]);
		self.object = [parser parse];
		self.fault = parser.fault;
		
    }
    
    return self;
}

- (void)dealloc {
	self.body = nil;
	self.object = nil;
	DEALLOC(super);
}

#pragma mark - Accessors

- (NSNumber *)faultCode {
    if (self.fault) {
        return [self.object objectForKey:@"faultCode"];
    }
    return nil;
}

- (NSString *)faultString {
    if (self.fault) {
        return [self.object objectForKey:@"faultString"];
    }
    return nil;
}

#pragma mark - debugging

- (NSString *)description {
	NSMutableString	*result = [NSMutableString stringWithCapacity:128];
    
	[result appendFormat:@"%@ (%p) [\n\tfault = '%@'", [self className], self, (self.fault)];
	if (self.fault) {
		[result appendFormat:@"\n\tfaultCode = '%@'", self.faultCode];
		[result appendFormat:@"\n\tfauleString = %@", self.faultString];
	}
	else {
		[result appendFormat:@"\n\tObject's class = '%@'", [self.object className]];
		[result appendFormat:@"\n\tObject = %@", self.object];
	}
	[result appendFormat:@"\n\tbody = %@", self.body];
	[result appendString:@"\n]"];
	
    
	return [NSString stringWithString:result];
}

@end
