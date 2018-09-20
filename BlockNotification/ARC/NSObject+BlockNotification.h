//
//  NSObject+BlockNotification.h
//  BlockNotification
//
//  Created by 方阳 on 2018/8/7.
//  Copyright © 2018年 yy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (BlockNotification)

/*
 * 为自身添加特定通知的监听
 * @param notification 通知名
 * @param callback 通知回调
 */
- (BOOL)observeBlockNotification:(NSString*)notification callback:(id)callback;

/*
 * 为自身在指定队列添加特定通知的监听
 * @param notification 通知名
 * @param callback 通知回调
 * @param queue 回调发生的队列
 */
- (BOOL)observeBlockNotification:(NSString*)notification callback:(id)callback queue:(dispatch_queue_t)queue;

/*
 * 为自身移除特定通知的监听
 * @param notification 通知名
 */
- (BOOL)removeBlockNotification:(NSString*)notification;

/*
 * 为自身移除所有通知的监听
 */
- (BOOL)removeBlockNotifications;

@end
