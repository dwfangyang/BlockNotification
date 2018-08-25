//
//  NSObject+BlockNotification.h
//  BlockNotification
//
//  Created by 方阳 on 2018/8/7.
//  Copyright © 2018年 yy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (BlockNotification)

- (BOOL)observeBlockNotification:(NSString*)notification callback:(id)callback;
- (BOOL)observeBlockNotification:(NSString*)notification callback:(id)callback queue:(dispatch_queue_t)queue;

@end
