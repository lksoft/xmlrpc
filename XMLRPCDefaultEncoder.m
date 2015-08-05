
#import "XMLRPCDefaultEncoder.h"
#import "NSStringAdditions.h"
#import "NSData+Base64.h"
#import "XMLRPCArc.h"

@interface XMLRPCDefaultEncoder ()
@property (strong) NSString *method;
@property (strong) NSArray *parameters;
@end


@implementation XMLRPCDefaultEncoder

- (id)init {
    if (self = [super init]) {
        self.method = @"";
        self.parameters = @[];
    }
    return self;
}

- (void)dealloc {
	self.method = nil;
	self.parameters = nil;
	DEALLOC(super);
}

- (NSString *)encode {
    NSMutableString *buffer = [NSMutableString stringWithString:@"<?xml version=\"1.0\"?><methodCall>"];
    
    [buffer appendFormat:@"<methodName>%@</methodName>", [self encodeString:self.method omitTag:YES]];
    [buffer appendString:@"<params>"];
	
	for (id param in self.parameters) {
		[buffer appendString: @"<param>"];
		[buffer appendString: [self encodeObject:param]];
		[buffer appendString: @"</param>"];
	}
	
    [buffer appendString:@"</params>"];
    [buffer appendString:@"</methodCall>"];
    
    return buffer;
}

- (void)setMethod:(NSString *)aMethod withParameters:(NSArray *)theParameters {
	self.method = aMethod;
	self.parameters = theParameters;
}


- (NSString *)valueTag:(NSString *)tag value:(NSString *)value {
    return [NSString stringWithFormat: @"<value><%@>%@</%@></value>", tag, value, tag];
}

- (NSString *)replaceTarget:(NSString *)target withValue:(NSString *)value inString:(NSString *)string {
    return [[string componentsSeparatedByString:target] componentsJoinedByString:value];
}

#pragma mark - Encodings

- (NSString *)encodeObject:(id)object {
    if (!object) {
        return nil;
    }
    
    if ([object isKindOfClass:[NSArray class]]) {
        return [self encodeArray:object];
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        return [self encodeDictionary:object];
#if ! __has_feature(objc_arc)
    } else if (((CFBooleanRef)object == kCFBooleanTrue) || ((CFBooleanRef)object == kCFBooleanFalse)) {
#else
    } else if (((__bridge CFBooleanRef)object == kCFBooleanTrue) || ((__bridge CFBooleanRef)object == kCFBooleanFalse)) {
#endif
        return [self encodeBoolean:(CFBooleanRef)object];
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return [self encodeNumber:object];
    } else if ([object isKindOfClass:[NSString class]]) {
        return [self encodeString:object omitTag:NO];
    } else if ([object isKindOfClass:[NSDate class]]) {
        return [self encodeDate:object];
    } else if ([object isKindOfClass:[NSData class]]) {
        return [self encodeData:object];
    } else {
        return [self encodeString:object omitTag:NO];
    }
}

- (NSString *)encodeArray:(NSArray *)array {
    NSMutableString *buffer = [NSMutableString string];
	
    [buffer appendString:@"<value><array><data>"];
	for (id object in array) {
		[buffer appendString:[self encodeObject:object]];
	}
    [buffer appendString: @"</data></array></value>"];
    
    return [NSString stringWithString:buffer];
}

- (NSString *)encodeDictionary:(NSDictionary *)dictionary {
    NSMutableString * buffer = [NSMutableString string];
	
    [buffer appendString:@"<value><struct>"];
	for (NSString *key in [dictionary allKeys]) {
		[buffer appendString:@"<member>"];
		[buffer appendFormat:@"<name>%@</name>", [self encodeString:key omitTag:YES]];
		NSObject *val = dictionary[key];
		if (val != [NSNull null]) {
			[buffer appendString:[self encodeObject:val]];
		} else {
			[buffer appendString:@"<value><nil/></value>"];
		}
		[buffer appendString:@"</member>"];
	}
    [buffer appendString: @"</struct></value>"];
    
    return [NSString stringWithString:buffer];
}

- (NSString *)encodeBoolean:(CFBooleanRef)boolean {
    if (boolean == kCFBooleanTrue) {
        return [self valueTag:@"boolean" value:@"1"];
    } else {
        return [self valueTag:@"boolean" value:@"0"];
    }
}

- (NSString *)encodeNumber:(NSNumber *)number {
    NSString *numberType = [NSString stringWithCString:[number objCType] encoding:NSUTF8StringEncoding];
    
    if ([numberType isEqualToString: @"d"]) {
        return [self valueTag:@"double" value:[number stringValue]];
    } else {
        return [self valueTag:@"i4" value:[number stringValue]];
    }
}

- (NSString *)encodeString:(NSString *)string omitTag:(BOOL)omitTag {
    return omitTag ? [string escapedString] : [self valueTag:@"string" value:[string escapedString]];
}

- (NSString *)encodeDate:(NSDate *)date {
    unsigned components = kCFCalendarUnitYear | kCFCalendarUnitMonth | kCFCalendarUnitDay | kCFCalendarUnitHour | kCFCalendarUnitMinute | kCFCalendarUnitSecond;
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:components fromDate:date];
    NSString *buffer = [NSString stringWithFormat:@"%.4ld%.2ld%.2ldT%.2ld:%.2ld:%.2ld", (long)[dateComponents year], (long)[dateComponents month], (long)[dateComponents day], (long)[dateComponents hour], (long)[dateComponents minute], (long)[dateComponents second], nil];
    
    return [self valueTag:@"dateTime.iso8601" value:buffer];
}

- (NSString *)encodeData:(NSData *)data {
    return [self valueTag:@"base64" value:[data base64EncodedString]];
}

@end
