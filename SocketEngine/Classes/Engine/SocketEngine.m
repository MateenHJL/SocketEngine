//
//  SocketEngine.m
//  CocoaAsyncSocket
//
//  Created by Mateen on 2022/11/25.
//

#import "SocketEngine.h"
#import "SocketConfig.h"
#import "GCDAsyncSocket.h"

#define kSocketTag 10086

@interface SocketEngine () <GCDAsyncSocketDelegate>

@property (nonatomic, strong  ) GCDAsyncSocket      *socketEngine; //socket引擎
@property (nonatomic, strong  ) SocketConfig        *config; //socket配置文件

@property (nonatomic, strong  ) dispatch_source_t   reConnectTimer;//重连计时器
@property (nonatomic, assign  ) NSInteger           reConnectTimerCount;//重连计时器值
@property (nonatomic, assign  ) BOOL                needAutoConnectSocket;//是否自动重连socket

@property (nonatomic, assign  ) SocketEngineStatus  currenStatus;

@property (nonatomic, strong  ) NSMutableData       *receivedData;

@end

@implementation SocketEngine

+ (SocketEngine *)sharedEngine
{
    static SocketEngine *engine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        engine = [[self alloc] init];
    });
    return engine;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.socketEngine = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        self.needAutoConnectSocket = YES;
        
        self.currenStatus = SocketEngineStatus_silence;
    }
    return self;
}

- (void)setupWithConfigFile:(SocketConfig *)config
{
    self.config = config;
}

- (void)applicationDidBecomeActive:(NSNotification *)nofity
{
    [self disconnectSocket];
    [self connectedSocket];
}

- (void)connectedSocket
{
    NSAssert(self.config, @"请先调用方法【setupWithConfigFile】");
    self.currenStatus = SocketEngineStatus_connecting;
    self.needAutoConnectSocket = NO;
    self.reConnectTimerCount = 0;
    NSError *error = nil;
    [self.socketEngine connectToHost:self.config.socketIpAddress onPort:self.config.socketPort error:&error];
    if (error)
    {
        self.needAutoConnectSocket = YES;
        [self connectedSocket];
    }
}

- (void)disconnectSocket
{
    self.needAutoConnectSocket = NO;
    [self.socketEngine disconnect];

    if (self.reConnectTimer)
    {
        dispatch_source_cancel(self.reConnectTimer);
        self.reConnectTimer = nil;
    }
    
    self.currenStatus = SocketEngineStatus_silence;
}

#pragma mark GCDAsyncSocketDelegate
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    //重置接受的数据
    self.receivedData = [[NSMutableData alloc] init];
    
    self.reConnectTimerCount = 0; // 重连次数
    
    NSMutableData *writeData = self.socketWriteDataWhenConnectingBlock();
    
    [self.socketEngine writeData:writeData withTimeout:-1 tag:kSocketTag];
    [self.socketEngine readDataWithTimeout:-1 tag:kSocketTag];
    
    self.currenStatus = SocketEngineStatus_connected;
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    self.currenStatus = SocketEngineStatus_silence;
    
    if (self.needAutoConnectSocket)
    {
        //如果需要自动重连
        [self connectedSocket];
    }
}

/// 数据成功發送到服务器
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    [self.socketEngine readDataWithTimeout:-1 tag:kSocketTag];
        
    if (self.sockeHastWriteDataCompletedBlock)
    {
        self.sockeHastWriteDataCompletedBlock(sock, tag);
    }
}

- (void)setCurrenStatus:(SocketEngineStatus)currenStatus
{
    _currenStatus = currenStatus;
    if (self.socketStatusHasChangedBlock)
    {
        self.socketStatusHasChangedBlock(currenStatus);
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    BOOL isCorrect = self.socketReceivedDataIsCorrectBlock(sock,data,tag);
    if (isCorrect)
    {
        @synchronized (self) {
            [self.receivedData appendData:data];
            if (self.socketHasReceivedDataBlock)
            {
                self.socketHasReceivedDataBlock(sock, self.receivedData, tag);
            }
        }
    }
}


@end
