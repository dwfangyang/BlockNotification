//
//  BlockNotificationDefines.h
//  BlockNotification
//
//  Created by 方阳 on 2018/8/7.
//  Copyright © 2018年 yy. All rights reserved.
//

#ifndef BlockNotificationDefines_h
#define BlockNotificationDefines_h

#define CHECKINPUT(condition,faillogformat,...) do{                                             \
                                                    if(!(condition))                          \
                                                    {                                         \
                                                        NSLog(faillogformat,##__VA_ARGS__);             \
                                                        return ;                                \
                                                    }                                         \
                                                }while(0)
#define CHECKINPUTANDRET(condition,ret,faillogformat,...)  do{                                             \
                                                                if(!(condition))                          \
                                                                {                                         \
                                                                    NSLog(faillogformat,##__VA_ARGS__);             \
                                                                    return ret;                                \
                                                                }                                         \
                                                            }while(0)
#define CHECK(condition)                        do{                                             \
                                                    if(!(condition))                          \
                                                    {                                         \
                                                        return ;                                \
                                                    }                                         \
                                                }while(0)
#define CHECKANDRET(condition,ret)             do{                                             \
                                                    if(!(condition))                          \
                                                    {                                         \
                                                        return ret;                              \
                                                    }                                         \
                                                }while(0)

struct BNBlockDescriptor {
    unsigned long reserved;
    unsigned long size;
    void *rest[1];
};

struct BNBlock {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct BNBlockDescriptor *descriptor;
};

#pragma mark runtimekey
static void* keyBlockNotificationProtocolObservation = &keyBlockNotificationProtocolObservation;

#pragma mark typedef
typedef void(^BlockNativeNotificationCalllback)(id data);

#pragma mark BLNotificationAttachments implementation
@interface BNAttachments:NSObject
{
    dispatch_queue_t _targetQueue;
}
- (dispatch_queue_t)queue;
@end

#endif /* BlockNotificationDefines_h */
