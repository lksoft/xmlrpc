
#import "XMLRPCConnectionManager.h"
#import "XMLRPCConnection.h"
#import "XMLRPCRequest.h"
#import "XMLRPCArc.h"

@interface XMLRPCConnectionManager ()
@property (strong) NSMutableDictionary *connections;
@end

@implementation XMLRPCConnectionManager


- (id)init {
    self = [super init];
    if (self) {
        self.connections = AUTORELEASE([[NSMutableDictionary alloc] init]);
		self.shouldLogConnections = NO;
    }
    
    return self;
}

- (void)dealloc {
	[self closeConnections];
	self.connections = nil;
	DEALLOC(super);
}


#pragma mark - Accessors

- (NSArray *)activeConnectionIdentifiers {
    return [self.connections allKeys];
}

- (NSUInteger)numberOfActiveConnections {
    return [self.connections count];
}

#pragma mark - Methods

- (NSString *)spawnConnectionWithXMLRPCRequest: (XMLRPCRequest *)request delegate: (id<XMLRPCConnectionDelegate>)delegate {
	XMLRPCConnection *newConnection = AUTORELEASE([[XMLRPCConnection alloc] initWithXMLRPCRequest:request delegate:delegate manager:self]);
	[self.connections setObject:newConnection forKey:newConnection.identifier];
	if (self.shouldLogConnections) {
		NSLog(@"Connection information:\n\tConnection ID: %@\n\tMethod: '%@'\n\tParameters: %@", newConnection.identifier, request.method, request.parameters);
	}
	return newConnection.identifier;
}

- (XMLRPCConnection *)connectionForIdentifier:(NSString *)identifier {
    return [self.connections objectForKey:identifier];
}

- (void)closeConnectionForIdentifier:(NSString *)identifier {
    XMLRPCConnection *selectedConnection = [self connectionForIdentifier:identifier];
    if (selectedConnection) {
        [selectedConnection cancel];
        [self.connections removeObjectForKey:identifier];
    }
}

- (void)closeConnections {
    [[self.connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [self.connections removeAllObjects];
}


#pragma mark - Class Methods

+ (XMLRPCConnectionManager *)sharedManager {
	
	static XMLRPCConnectionManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	
	return sharedInstance;
}



@end
