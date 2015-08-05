
#import "XMLRPCRequest.h"
#import "XMLRPCEncoder.h"
#import "XMLRPCDefaultEncoder.h"
#import "XMLRPCArc.h"

static const NSTimeInterval DEFAULT_TIMEOUT = 240;


@interface XMLRPCRequest ()
@property (strong) NSMutableURLRequest *internalRequest;
@end


@implementation XMLRPCRequest

@synthesize encoder = _encoder;

- (id)initWithURL:(NSURL *)aURL withEncoder:(id<XMLRPCEncoder>)anEncoder {
    self = [super init];
    if (self) {
        if (aURL) {
            self.internalRequest = AUTORELEASE([[NSMutableURLRequest alloc] initWithURL:aURL]);
        } else {
            self.internalRequest = AUTORELEASE([[NSMutableURLRequest alloc] init]);
        }
        
        self.encoder = anEncoder;
        self.timeout = DEFAULT_TIMEOUT;
		self.userAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)aURL {
    return [self initWithURL:aURL withEncoder:AUTORELEASE([[XMLRPCDefaultEncoder alloc] init])];
}

- (void)dealloc {
	self.internalRequest = nil;
	self.encoder = nil;
	self.extra = nil;
	DEALLOC(super);
}


#pragma mark - Accessors

- (id<XMLRPCEncoder>)encoder {
	return AUTORELEASE(RETAIN(_encoder));
}

- (void)setEncoder:(id<XMLRPCEncoder>)anEncoder {
	
	NSString *method = self.encoder.method;
	NSArray *parameters = self.encoder.parameters;
	id<XMLRPCEncoder> temp = _encoder;
	_encoder = RETAIN(anEncoder);
	RELEASE(temp);
	
    [_encoder setMethod:method withParameters:parameters];
}

- (NSString *)method {
	return self.encoder.method;
}

- (void)setMethod:(NSString *)theMethod {
    [self setMethod:theMethod withParameters:nil];
}

- (void)setMethod:(NSString *)theMethod withParameter:(id)aParameter {
    NSArray *parameters = nil;
    
    if (aParameter) {
        parameters = @[aParameter];
    }
    
    [self setMethod:theMethod withParameters:parameters];
}

- (void)setMethod:(NSString *)theMethod withParameters:(NSArray *)theParameters {
    [self.encoder setMethod:theMethod withParameters:theParameters];
}

- (NSArray *)parameters {
    return self.encoder.parameters;
}

- (NSString *)body {
    return [self.encoder encode];
}

- (NSURLRequest *)request {
    NSData *content = [self.body dataUsingEncoding:NSUTF8StringEncoding];
    NSNumber *contentLength = [NSNumber numberWithUnsignedInteger:[content length]];
    
    if (!self.internalRequest) {
        return nil;
    }
    
    [self.internalRequest setHTTPMethod:@"POST"];
	[self.internalRequest setURL:self.URL];
	
    if (![self.internalRequest valueForHTTPHeaderField: @"Content-Type"]) {
        [self.internalRequest addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    } else {
        [self.internalRequest setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    }
    
    if (![self.internalRequest valueForHTTPHeaderField:@"Content-Length"]) {
        [self.internalRequest addValue:[contentLength stringValue] forHTTPHeaderField:@"Content-Length"];
    } else {
        [self.internalRequest setValue:[contentLength stringValue] forHTTPHeaderField:@"Content-Length"];
    }
    
    if (![self.internalRequest valueForHTTPHeaderField:@"Accept"]) {
        [self.internalRequest addValue:@"text/xml" forHTTPHeaderField:@"Accept"];
    } else {
        [self.internalRequest setValue:@"text/xml" forHTTPHeaderField:@"Accept"];
    }
    
	if (self.userAgent) {
		if (![self.internalRequest valueForHTTPHeaderField:@"User-Agent"]) {
			[self.internalRequest addValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
		} else {
			[self.internalRequest setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
		}
	}
	
    [self.internalRequest setHTTPBody:content];
    
    return (NSURLRequest *)self.internalRequest;
}

- (void)setValue:(NSString *)aValue forHTTPHeaderField:(NSString *)aHeader {
    [self.internalRequest setValue:aValue forHTTPHeaderField:aHeader];
}

@end
