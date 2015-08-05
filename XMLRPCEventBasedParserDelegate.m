
#import "XMLRPCEventBasedParserDelegate.h"
#import "NSData+Base64.h"
#import "XMLRPCArc.h"


@interface XMLRPCEventBasedParserDelegate ()
@property (strong) NSMutableSet *children;
@end

@implementation XMLRPCEventBasedParserDelegate

- (id)initWithParent: (XMLRPCEventBasedParserDelegate *)parent {
    self = [super init];
    if (self) {
        self.parent = parent;
        self.children = [NSMutableSet set];
        self.elementType = XMLRPCElementTypeString;
        self.elementKey = nil;
        self.elementValue = [NSMutableString string];
    }
    
    return self;
}

- (void)dealloc {
	self.children = nil;
	self.elementKey = nil;
	self.elementValue = nil;
    DEALLOC(super);
}


#pragma mark - Parser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)element namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributes {
	
    if ([element isEqualToString:@"value"] || [element isEqualToString:@"member"] || [element isEqualToString:@"name"]) {
        XMLRPCEventBasedParserDelegate *parserDelegate = AUTORELEASE([[XMLRPCEventBasedParserDelegate alloc] initWithParent:self]);
        
        if ([element isEqualToString:@"member"]) {
            [parserDelegate setElementType:XMLRPCElementTypeMember];
        } else if ([element isEqualToString:@"name"]) {
            [parserDelegate setElementType:XMLRPCElementTypeName];
        }
        
        [self.children addObject:parserDelegate];
        [parser setDelegate:parserDelegate];
        return;
    }
    
    if ([element isEqualToString:@"array"]) {
        [self setElementValue:[NSMutableArray array]];
        [self setElementType:XMLRPCElementTypeArray];
    } else if ([element isEqualToString:@"struct"]) {
        [self setElementValue:[NSMutableDictionary dictionary]];
        [self setElementType: XMLRPCElementTypeDictionary];
    } else if ([element isEqualToString:@"int"] || [element isEqualToString:@"i4"]) {
        [self setElementType:XMLRPCElementTypeInteger];
    } else if ([element isEqualToString:@"double"]) {
        [self setElementType:XMLRPCElementTypeDouble];
    } else if ([element isEqualToString:@"boolean"]) {
        [self setElementType:XMLRPCElementTypeBoolean];
    } else if ([element isEqualToString:@"string"]) {
        [self setElementType:XMLRPCElementTypeString];
    } else if ([element isEqualToString:@"dateTime.iso8601"]) {
        [self setElementType:XMLRPCElementTypeDate];
    } else if ([element isEqualToString:@"base64"]) {
        [self setElementType:XMLRPCElementTypeData];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)element namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName {
	
    if ([element isEqualToString:@"value"] || [element isEqualToString:@"member"] || [element isEqualToString:@"name"]) {
        NSString *elementValue = nil;
        
		if ((self.elementType != XMLRPCElementTypeArray) && ![self isDictionaryElementType:self.elementType]) {
			elementValue = [self parseString:self.elementValue];
			self.elementValue = nil;
		}
		
		switch (self.elementType) {
			case XMLRPCElementTypeInteger:
				self.elementValue = [self parseInteger:elementValue];
				break;
				
			case XMLRPCElementTypeDouble:
				self.elementValue = [self parseDouble:elementValue];
				break;
				
			case XMLRPCElementTypeBoolean:
				self.elementValue = [self parseBoolean:elementValue];
				break;
				
			case XMLRPCElementTypeString:
			case XMLRPCElementTypeName:
				self.elementValue = elementValue;
				break;
				
			case XMLRPCElementTypeDate:
				self.elementValue = [self parseDate:elementValue];
				break;
				
			case XMLRPCElementTypeData:
				self.elementValue = [self parseData:elementValue];
				break;
				
			default:
				break;
		}
		
		if (self.parent && self.elementValue) {
			[self addElementValueToParent];
		}
		
		[parser setDelegate:self.parent];
		
		if (self.parent) {
			XMLRPCEventBasedParserDelegate *parent = self.parent;
			
			// Set it to nil explicitly since it's not __weak but __unsafe_unretained.
			// We're doing it here because if we'll do it after removal from myChildren
			// self can already be deallocated, and accessing field of deallocated object
			// causes memory corruption.
			self.parent = nil;
			
			[parent.children removeObject:self];
		}
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if ((self.elementType == XMLRPCElementTypeArray) || [self isDictionaryElementType:self.elementType]) {
        return;
    }
    
    if (!self.elementValue) {
        self.elementValue = [[NSMutableString alloc] initWithString:string];
    } else {
        [self.elementValue appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    [parser abortParsing];
}


#pragma mark - Helper Methods

- (BOOL)isDictionaryElementType:(XMLRPCElementType)elementType {
    if ((self.elementType == XMLRPCElementTypeDictionary) || (self.elementType == XMLRPCElementTypeMember)) {
        return YES;
    }
    
    return NO;
}

- (void)addElementValueToParent {
    id parentElementValue = self.parent.elementValue;
    
	switch (self.parent.elementType) {
		case XMLRPCElementTypeArray:
			[parentElementValue addObject:self.elementValue];
			break;
			
		case XMLRPCElementTypeDictionary:
			if ([self.elementValue isEqual:[NSNull null]]) {
				[parentElementValue removeObjectForKey:self.elementKey];
			} else {
				[parentElementValue setObject:self.elementValue forKey:self.elementKey];
			}
			break;
			
		case XMLRPCElementTypeMember:
			if (self.elementType == XMLRPCElementTypeName) {
				[self.parent setElementKey:self.elementValue];
			} else {
				[self.parent setElementValue:self.elementValue];
			}
			break;
			
		default:
			break;
	}
}

#pragma mark - Value Parsers

- (NSDate *)parseDateString:(NSString *)dateString withFormat:(NSString *)format {
	
    NSDateFormatter *dateFormatter = AUTORELEASE([[NSDateFormatter alloc] init]);
    [dateFormatter setDateFormat:format];
    return [dateFormatter dateFromString:dateString];;
}

- (NSNumber *)parseInteger:(NSString *)value {
    return @([value integerValue]);
}

- (NSNumber *)parseDouble:(NSString *)value {
    return @([value doubleValue]);
}

- (NSNumber *)parseBoolean:(NSString *)value {
    if ([value isEqualToString:@"1"]) {
        return @YES;
    }
    return @NO;
}

- (NSString *)parseString:(NSString *)value {
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSDate *)parseDate:(NSString *)value {
    NSDate *result = nil;
    
    result = [self parseDateString:value withFormat:@"yyyyMMdd'T'HH:mm:ss"];
    
    if (!result) {
        result = [self parseDateString:value withFormat:@"yyyy'-'MM'-'dd'T'HH:mm:ss"];
    }
    
    if (!result) {
        result = [self parseDateString:value withFormat:@"yyyy'-'MM'-'dd'T'HH:mm:ssZ"];
    }
    
    if (!result) {
        result = (NSDate *)[NSNull null];
    }

    return result;
}

- (NSData *)parseData: (NSString *)value {
    return [NSData dataFromBase64String:value];
}

@end
