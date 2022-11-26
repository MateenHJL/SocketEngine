//
//  SocketEngine.h
//  CocoaAsyncSocket
//
//  Created by Mateen on 2022/11/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SocketConfig;
@class GCDAsyncSocket;

typedef NS_ENUM(NSInteger , SocketEngineStatus) {
    SocketEngineStatus_silence,//暂无连接
    SocketEngineStatus_connecting,//连接中
    SocketEngineStatus_connected,//已连接
};


typedef void(^socketStatusHasChangedBlock)(SocketEngineStatus stauts);
typedef void(^sockeHastWriteDataCompletedBlock)(GCDAsyncSocket *socketEngine, NSInteger tag);
typedef NSMutableData *_Nonnull(^socketWriteDataWhenConnectingBlock)(void);
typedef void(^socketHasReceivedDataBlock)(GCDAsyncSocket *socketEngine, NSData *receivedData, NSInteger tag);
typedef BOOL(^socketReceivedDataIsCorrectBlock)(GCDAsyncSocket *socketEngine, NSData *receivedData, NSInteger tag);

@interface SocketEngine : NSObject

/// 单例对象
+ (SocketEngine *)sharedEngine;

/// 加入配置项
- (void)setupWithConfigFile:(SocketConfig *)config;

/// 开始连接socket
- (void)connectedSocket;

/// 断开链接
- (void)disconnectSocket;

//连接状态有改变block
@property (nonatomic, copy  ) socketStatusHasChangedBlock socketStatusHasChangedBlock;

//发送数据完成后block
@property (nonatomic, copy  ) sockeHastWriteDataCompletedBlock sockeHastWriteDataCompletedBlock;

//连接时需要添加的额外校验数据
@property (nonatomic, copy  ) socketWriteDataWhenConnectingBlock socketWriteDataWhenConnectingBlock;

//接受到socket信息
@property (nonatomic, copy  ) socketHasReceivedDataBlock socketHasReceivedDataBlock;

//校验收到的信息是否是正确的
@property (nonatomic, copy  ) socketReceivedDataIsCorrectBlock socketReceivedDataIsCorrectBlock;

@end

NS_ASSUME_NONNULL_END
