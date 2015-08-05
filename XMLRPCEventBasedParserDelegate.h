
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, XMLRPCElementType) {
	XMLRPCElementTypeArray,
	XMLRPCElementTypeDictionary,
	XMLRPCElementTypeMember,
	XMLRPCElementTypeName,
	XMLRPCElementTypeInteger,
	XMLRPCElementTypeDouble,
	XMLRPCElementTypeBoolean,
	XMLRPCElementTypeString,
	XMLRPCElementTypeDate,
	XMLRPCElementTypeData
};


@interface XMLRPCEventBasedParserDelegate : NSObject<NSXMLParserDelegate>

@property (assign) XMLRPCEventBasedParserDelegate *parent;
@property (assign) XMLRPCElementType elementType;
@property (strong) NSString *elementKey;
@property (strong) id elementValue;

- (id)initWithParent:(XMLRPCEventBasedParserDelegate *)parent;

@end
