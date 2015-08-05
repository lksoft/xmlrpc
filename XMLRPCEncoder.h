#import <Foundation/Foundation.h>

@protocol XMLRPCEncoder <NSObject>

- (NSString *)encode;

- (void)setMethod:(NSString *)method withParameters:(NSArray *)parameters;

- (NSString *)method;
- (NSArray *)parameters;

@end
