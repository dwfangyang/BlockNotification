//
//  BlockNotificationCenter.h
//  BlockNotificationCenter
//
//  Created by 方阳 on 2018/8/7.
//  Copyright © 2018年 yy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+BlockNotification.h"

extern NSString* const blockkey;
#define BN_Post(notification,...) for( NSDictionary* _BNInternal_info in [[BlockNotificationCenter sharedInstance] callbacks:@#notification] ) \
                                    {                                                                                                \
                                        BNBlock_##notification blk = _BNInternal_info[blockkey];\
                                        if( !blk ) continue;\
                                        [[BlockNotificationCenter sharedInstance] callback:^{\
                                            blk(__VA_ARGS__);\
                                        } withInfo:_BNInternal_info];\
                                    }

#define VOID void
#define BN_Dec(notification,...)       typedef void(^BNBlock_##notification)(__VA_ARGS__);\
                                        @interface NSObject (notification)\
                                        - (void)on##notification:(BNBlock_##notification)callback;\
                                        - (void)on##notification:(BNBlock_##notification)callback queue:(dispatch_queue_t)queue;\
                                        @end\
                                        extern NSString * const notification

#define BN_Def(notification,...)  @implementation BlockNotificationBlock (notification)                        \
                                    + (BNBlock_##notification)callbackBlock_##notification{                                    \
                                        return ^(__VA_ARGS__){};                            \
                                    }                                                       \
                                    @end\
                                    @implementation NSObject (notification)\
                                    - (void)on##notification:(BNBlock_##notification)callback;{\
                                        [self observeBlockNotification:notification callback:callback queue:nil];\
                                    }\
                                    - (void)on##notification:(BNBlock_##notification)callback queue:(dispatch_queue_t)queue;{\
                                        [self observeBlockNotification:notification callback:callback queue:queue];\
                                    }\
                                    @end\
                                    NSString * const notification = @#notification

@interface BlockNotificationBlock:NSObject
@end

@interface BlockNotificationCenter : NSObject

+ (instancetype)sharedInstance;
/*
 *  @brief 添加notification通知回调.
 *  @param observer 监听通知的监听者.
 *  @param notificationname 通知名.
 *  @param callback block回调.
 *  @ret   BOOL 监听是否成功.
 *  @see #addObserver:forNotification:callback:queue:.
 */
- (BOOL)addObserver:(id)observer forNotification:(NSString*)notificationname callback:(id)callback;

/*
 *  @brief 添加notification通知回调.
 *  @param observer 监听通知的监听者.
 *  @param notificationname 通知名.
 *  @param callback block回调.
 *  @param queue 回调的队列.
 *  @ret   BOOL 监听是否成功.
 *  @warning callback类型需为block，若notificationname定义为不带参数的通知，则block亦需为无参block.
 *                                若notificationname定义为带参数的通知，则block需为只带一个参数的block.
 *  @warning 若callback类型不合要求，会在DEBUG编译情况下崩溃.
 *  @warning 同一个observer对同一个notificationname，只可以注册一个回调，即若注册两个，则新回调会覆盖旧回调.
 */
- (BOOL)addObserver:(id)observer forNotification:(NSString*)notificationname callback:(id)callback queue:(dispatch_queue_t)queue;

/**
 * @brief 移除对notification的通知.
 * @param observer 监听者.
 * @param notificationname 通知名.
 */
- (BOOL)removeObserver:(id)observer forNotification:(NSString*)notificationname;

/**
 * @brief 移除监听都所有的notification监听.
 * @param observer 监听者.
 */
- (BOOL)removeObserver:(id)observer;

/**
 * @brief 发送通知
 * @param block 某个注册的回调
 * @param info  回调信息
 */
- (void)callback:(dispatch_block_t)block withInfo:(NSDictionary*)info;

/**
 * @param notification 某通知名notification
 * @ret 指定通知注册的回调
 */
- (NSArray*)callbacks:(NSString*)notification;

@end
