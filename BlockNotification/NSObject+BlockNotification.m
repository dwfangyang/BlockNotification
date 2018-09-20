//
//  NSObject+BlockNotification.m
//  BlockNotification
//
//  Created by 方阳 on 2018/8/7.
//  Copyright © 2018年 yy. All rights reserved.
//

#import "NSObject+BlockNotification.h"
#import "BlockNotificationCenter.h"

@implementation NSObject (BlockNotification)

- (BOOL)observeBlockNotification:(NSString*)notification callback:(id)callback;
{
    return [[BlockNotificationCenter sharedInstance] addObserver:self forNotification:notification callback:callback];
}

- (BOOL)observeBlockNotification:(NSString*)notification callback:(id)callback queue:(dispatch_queue_t)queue;
{
    return [[BlockNotificationCenter sharedInstance] addObserver:self forNotification:notification callback:callback queue:queue];
}

- (BOOL)removeBlockNotification:(NSString*)notification;
{
    return [[BlockNotificationCenter sharedInstance] removeObserver:self forNotification:notification];
}

- (BOOL)removeBlockNotifications;
{
    return [[BlockNotificationCenter sharedInstance] removeObserver:self];
}

@end
