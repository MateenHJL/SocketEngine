//
//  SocketConfig.h
//  CocoaAsyncSocket
//
//  Created by Mateen on 2022/11/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SocketConfig : NSObject

@property (nonatomic, copy  ) NSString  *socketIpAddress;
@property (nonatomic, assign) NSInteger socketPort;

@end

NS_ASSUME_NONNULL_END
