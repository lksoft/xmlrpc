#import <Foundation/Foundation.h>

@interface NSString (NSStringAdditions)

+ (NSString *)stringByGeneratingUUID;

- (NSString *)unescapedString;
- (NSString *)escapedString;

@end
