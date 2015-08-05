

#import "XMLRPCConnection.h"
#import "XMLRPCConnectionManager.h"
#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "NSStringAdditions.h"
#import "XMLRPCArc.h"


@interface XMLRPCConnection ()
@property (strong, readwrite) NSString *identifier;
@property (strong, readwrite) id<XMLRPCConnectionDelegate> delegate;
@property (strong) XMLRPCConnectionManager *manager;
@property (strong) XMLRPCRequest *request;
@property (strong) NSMutableData *data;
@property (strong) NSURLConnection *connection;
@end


@implementation XMLRPCConnection

- (id)initWithXMLRPCRequest:(XMLRPCRequest *)aRequest delegate:(id<XMLRPCConnectionDelegate>)aDelegate manager:(XMLRPCConnectionManager *)aManager {
	
	self = [super init];
    if (self) {
		
		self.manager = aManager;
		self.request = aRequest;
		self.delegate = aDelegate;
		self.identifier = [NSString stringByGeneratingUUID];
		
        self.data = AUTORELEASE([[NSMutableData alloc] init]);
        
        self.connection = AUTORELEASE([[NSURLConnection alloc] initWithRequest:aRequest.request delegate:self startImmediately:NO]);
        [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [self.connection start];
        
        if (self.connection) {
            NSLog(@"The connection, %@, has been established!", self.identifier);
            [self performSelector:@selector(timeoutExpired) withObject:nil afterDelay:[self.request timeout]];
        }
		else {
            NSLog(@"The connection, %@, could not be established!", self.identifier);
			RELEASE(self);
            return nil;
        }
    }
    
    return self;
}

- (void)cancel {
    [self.connection cancel];
    [self invalidateTimer];
}

#pragma mark - Class Methods

+ (XMLRPCResponse *)sendSynchronousXMLRPCRequest:(XMLRPCRequest *)aRequest error:(NSError **)error {

	NSHTTPURLResponse *response = nil;
	
	NSData	*theData = [NSURLConnection sendSynchronousRequest:aRequest.request returningResponse:&response error:error];
    if (response) {
        NSInteger statusCode = [response statusCode];
        
        if ((statusCode < 400) && theData) {
			return AUTORELEASE([[XMLRPCResponse alloc] initWithData: theData]);
        }
    }
    
    return nil;
}

#pragma mark -

- (void)dealloc {
	self.identifier = nil;
	self.delegate = nil;
	self.request = nil;
	self.manager = nil;
	self.connection = nil;
	self.data = nil;

    DEALLOC(super);
}


#pragma mark - Connection Delegation

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if([response respondsToSelector: @selector(statusCode)]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        
        if (statusCode >= 400) {
            NSError *error = [NSError errorWithDomain:@"HTTP" code:statusCode userInfo:nil];
            [self.delegate request:self.request didFailWithError:error];
        }
		else if (statusCode == 304) {
            [self.manager closeConnectionForIdentifier:self.identifier];
        }
    }
    
    [self.data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData {
    [self.data appendData:theData];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	
	if ([self.delegate respondsToSelector: @selector(request:didSendBodyData:)]) {
        float percent = totalBytesWritten / (float)totalBytesExpectedToWrite;
        
        [self.delegate request:self.request didSendBodyData:percent];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

	NSLog(@"The connection, %@, failed with the following error: %@", self.identifier, [error localizedDescription]);

    [self invalidateTimer];

    [self.delegate request:self.request didFailWithError:error];
    [self.manager closeConnectionForIdentifier:self.identifier];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [self.delegate request:self.request canAuthenticateAgainstProtectionSpace:protectionSpace];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self.delegate request:self.request didReceiveAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self.delegate request:self.request didCancelAuthenticationChallenge:challenge];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self invalidateTimer];
    if (self.data && ([self.data length] > 0)) {

		NSData __block *theData = self.data;
		XMLRPCRequest __block *request = self.request;
		XMLRPCConnectionManager __block *theManager = self.manager;
		id<XMLRPCConnectionDelegate> __block theDelegate = self.delegate;
		
		[[XMLRPCConnection parsingQueue] addOperationWithBlock:^{
			XMLRPCResponse *response = AUTORELEASE([[XMLRPCResponse alloc] initWithData:theData]);
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[theDelegate request:request didReceiveResponse:response];
				[theManager closeConnectionForIdentifier:self.identifier];
			}];
		}];
    }
    else {
        [self.manager closeConnectionForIdentifier:self.identifier];
    }
}

#pragma mark - Timeout Handling

- (void)timeoutExpired {

	NSDictionary *userInfo = @{NSURLErrorFailingURLErrorKey: self.request.URL, NSURLErrorFailingURLStringErrorKey: [self.request.URL absoluteString], NSLocalizedDescriptionKey: @"The request timed out."};
	
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:userInfo];
    [self connection:self.connection didFailWithError:error];
}

- (void)invalidateTimer {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutExpired) object:nil];
}

#pragma mark -

+ (NSOperationQueue *)parsingQueue {
	static NSOperationQueue *parsingQueue = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		parsingQueue = [[NSOperationQueue alloc] init];
	});
    return parsingQueue;
}

@end
