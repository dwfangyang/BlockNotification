//
//  BlockNotificationCenter.m
//  BlockNotificationCenter
//
//  Created by 方阳 on 2018/8/7.
//  Copyright © 2018年 yy. All rights reserved.
//

#import "BlockNotificationCenter.h"
#import <objc/runtime.h>
#import "BlockNotificationDefines.h"
#import "BNLeakChecker.h"

NSString* const blockkey = @"BlockNotificationBlockKey";

#pragma mark blocksignature fetch method
static const char *BlockSig(id blockObj)
{
    struct BNBlock *block = (__bridge struct BNBlock *)blockObj;
    struct BNBlockDescriptor *descriptor = block->descriptor;
    
    int copyDisposeFlag = 1 << 25;
    int signatureFlag = 1 << 30;
    
    assert(block->flags & signatureFlag);
    if( !(block->flags & signatureFlag) )
    {
        NSLog(@"BlockNotification:fatal error:block no signatureflag");
        return NULL;
    }
    
    int index = 0;
    if(block->flags & copyDisposeFlag)
    {
        index += 2;
    }
    
    return (char*)(descriptor->rest[index]);
}

@implementation BNAttachments
- (instancetype)initWithQueue:(dispatch_queue_t)queue;
{
    if( self = [super init] )
    {
        _targetQueue = queue;
    }
    return self;
}
- (dispatch_queue_t)queue;
{
    return _targetQueue;
}
@end

@implementation BlockNotificationBlock
@end

@interface BlockNotificationCenter()
@property (nonatomic, strong) NSMutableDictionary<NSString*,NSMapTable*>*   observations;
@property (nonatomic, strong) NSMutableDictionary<NSString*,NSNumber*>*     nativeNotifications;
@property (nonatomic, strong) NSMutableDictionary<NSString*,NSMapTable*>*   observationAttachments;
@end

@implementation BlockNotificationCenter

+ (instancetype)sharedInstance;
{
    static BlockNotificationCenter* noticenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        noticenter = [BlockNotificationCenter new];
    });
    return noticenter;
}

- (instancetype)init
{
    if( self = [super init] )
    {
        _observations = [NSMutableDictionary<NSString*,NSMapTable*> new];
        _nativeNotifications = [NSMutableDictionary<NSString*,NSNumber*> new];
        _observationAttachments = [NSMutableDictionary<NSString*,NSMapTable*> new];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isNativeNotification:(NSString*)notificationname;
{
    @synchronized(self.nativeNotifications)
    {
        return ([self.nativeNotifications objectForKey:notificationname] != nil );
    }
}

- (void)setNativeNotification:(NSString*)notificationname;
{
    @synchronized(self.nativeNotifications)
    {
        [self.nativeNotifications setObject:@YES forKey:notificationname];
    }
}

- (BNAttachments*)getAttachmentForNotification:(NSString*)notificationname forObserver:(id)observer;
{
    CHECKANDRET(notificationname,nil);
    CHECKANDRET(observer,nil);
    @synchronized(self.observations)
    {
        return [[self.observationAttachments objectForKey:notificationname] objectForKey:observer];
    }
}

#pragma mark api
- (BOOL)addObserver:(id)observer forNotification:(NSString*)notificationname callback:(id)callback;
{
    return [self addObserver:observer forNotification:notificationname callbackBlock:callback queue:nil];
}

- (BOOL)addObserver:(id)observer forNotification:(NSString*)notificationname callback:(id)callback queue:(dispatch_queue_t)queue;
{
    return [self addObserver:observer forNotification:notificationname callbackBlock:callback queue:queue];
}

- (BOOL)addObserver:(id)observer forNotification:(NSString*)notificationname callbackBlock:(id)callback queue:(dispatch_queue_t)queue;
{
    CHECKINPUTANDRET(observer, NO, @"BlockNotification:nil input");
    CHECKINPUTANDRET(notificationname, NO, @"BlockNotification:nil notificationname");
    CHECKINPUTANDRET([[BNLeakChecker sharedChecker] isBlock:callback], NO, @"BlockNotification:invalid callback");
    
    BOOL isvalidCallback = [self isValidBlock:callback forNotification:notificationname];
    CHECKINPUTANDRET(isvalidCallback, NO, @"BlockNotification:invalid blocktype for %@",notificationname);
    
#ifdef DEBUG
    if( [[BNLeakChecker sharedChecker] isBlock:callback retainObserver:observer] )
    {
        NSLog(@"BlockNotification:callback for %@ retain the observer:%@",notificationname,observer);
        NSException* exception = [NSException exceptionWithName:@"BlockNotification" reason:[NSString stringWithFormat:@"callback retain observer:%@",notificationname] userInfo:nil];
        [exception raise];
    }
#endif
    
    @synchronized(self.observations)
    {
        NSMapTable* table = [self.observations objectForKey:notificationname];
        if( !table )
        {
            table = [NSMapTable weakToStrongObjectsMapTable];
            [self.observations setObject:table forKey:notificationname];
            if( [self isNativeNotification:notificationname] )
            {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationInvoked:) name:notificationname object:nil];
            }
        }
        [table setObject:[callback copy] forKey:observer];
    }
    
    NSArray* observedNotifications = nil;
    observedNotifications = [objc_getAssociatedObject(observer, keyBlockNotificationProtocolObservation) copy];
    if( !observedNotifications )
    {
        observedNotifications = [@[notificationname] mutableCopy];
    }
    else
    {
        NSMutableArray* arr = [observedNotifications mutableCopy];
        [arr addObject:notificationname];
        observedNotifications = arr;
    }
    objc_setAssociatedObject(observer, keyBlockNotificationProtocolObservation, observedNotifications, OBJC_ASSOCIATION_RETAIN);
    
    CHECKANDRET(queue, YES);
    @synchronized(self.observations)
    {
        NSMapTable* table = [self.observationAttachments objectForKey:notificationname];
        if( !table )
        {
            table = [NSMapTable weakToStrongObjectsMapTable];
            [self.observationAttachments setObject:table forKey:notificationname];
        }
        [table setObject:[[BNAttachments alloc] initWithQueue:queue] forKey:observer];
    }
    return YES;
}

- (BOOL)removeObserver:(id)observer forNotification:(NSString*)notificationname;
{
    CHECKINPUTANDRET(observer&&notificationname, NO, @"BlockNotification:nil input");
    
    @synchronized(self.observations)
    {
        NSMapTable* table = [self.observations objectForKey:notificationname];
        if( table && [table objectForKey:observer] )
        {
            [table removeObjectForKey:observer];
        }
        table = [self.observationAttachments objectForKey:notificationname];
        if( table && [table objectForKey:observer] )
        {
            [table removeObjectForKey:observer];
        }
    }
    return YES;
}

- (BOOL)removeObserver:(id)observer;
{
    CHECKINPUTANDRET(observer, NO, @"BlockNotification:nil input");
    
    NSArray* notifications = [objc_getAssociatedObject(observer, keyBlockNotificationProtocolObservation) copy];
    for( NSString* notification in notifications )
    {
        [self removeObserver:observer forNotification:notification];
    }
    return YES;
}

#pragma mark notification
- (void)callback:(dispatch_block_t)block withInfo:(NSDictionary*)info;
{
    CHECK(block);
    dispatch_queue_t queue = info[@"queue"];
    if( !queue || [self isInTargetQueue:queue] )
    {
        block();
    }
    else
    {
        dispatch_async(queue, block);
    }
}

- (NSArray*)callbacks:(NSString*)notification;
{
    CHECKANDRET(notification,nil);
    NSMapTable* table = nil;
    @synchronized(self.observations)
    {
        table = [self.observations objectForKey:notification];
        table = [table copy];
    }
    CHECKANDRET(table.count, nil);
    NSLog(@"BlockNotification:%@ observers for %@",@(table.count),notification);
    NSEnumerator* keyEnumerator = table.keyEnumerator;
    id observer = keyEnumerator.nextObject;
    NSMutableArray* arr = [NSMutableArray new];
    while ( observer ) {
        id callback = [table objectForKey:observer];
        if( callback )
        {
            BNAttachments* attachment = [self getAttachmentForNotification:notification forObserver:observer];
            if( attachment.queue )
            {
                [arr addObject:@{blockkey:callback,@"queue":attachment.queue}];
            }
            else
            {
                [arr addObject:@{blockkey:callback}];
            }
        }
        observer = keyEnumerator.nextObject;
    }
    return arr;
}

- (void)notificationInvoked:(NSNotification*)notification;
{
    CHECKINPUT(notification.name, @"nil notification name");
#ifdef DEBUG
    NSLog(@"BlockNotification:notification(%@) called",notification.name);
#endif
    NSMapTable* table = nil;
    @synchronized(self.observations)
    {
        table = [self.observations objectForKey:notification.name];
        table = [table copy];
    }
    CHECKINPUT(table.count, @"BlockNotification:no callback to invoke for:%@",notification.name);
    NSLog(@"BlockNotification:%@ observers for %@",@(table.count),notification.name);
    NSEnumerator* keyEnumerator = table.keyEnumerator;
    id observer = keyEnumerator.nextObject;
    CHECKINPUT([self isNativeNotification:notification.name], @"invalid native notifcation:%@",notification.name);
    while ( observer ) {
        BlockNativeNotificationCalllback callback = [table objectForKey:observer];
        if( callback )
        {
            dispatch_block_t handleNotification = ^{
                callback(notification);
            };
            
            BNAttachments* attachment = [self getAttachmentForNotification:notification.name forObserver:observer];
            [self callback:handleNotification withInfo:attachment.queue?@{@"queue":attachment.queue}:nil];
        }
        observer = keyEnumerator.nextObject;
    }
}

#pragma mark utility
- (BOOL)isInTargetQueue:(dispatch_queue_t)queue;
{
    if( queue == dispatch_get_main_queue() && [NSThread isMainThread] )
    {
        return YES;
    }
    return NO;
}

- (BOOL)isValidBlock:(id)callback forNotification:(NSString*)notificationname
{
    NSString* observerSignature = nil;
    const char* observerSig = BlockSig(callback);
    if( observerSig )
    {
        observerSignature = [NSString stringWithUTF8String:observerSig];
    }
    
    Class cls = [BlockNotificationBlock class];
    
    SEL callbackSel = NSSelectorFromString([NSString stringWithFormat:@"callbackBlock_%@",notificationname]);
    
    //native nsnotification observation
    if( ![cls respondsToSelector:callbackSel] && [[self getClassnameFromSignature:observerSignature] isEqualToString:@"NSNotification"] )
    {
        [self setNativeNotification:notificationname];
        return YES;
    }
    
    CHECKINPUTANDRET([cls respondsToSelector:callbackSel], NO, @"BlockNotification:callbackBlock method not correctly defined:%@",notificationname);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id blk = [cls performSelector:callbackSel];
    
    NSString* origSignature = nil;
#pragma clang diagnostic pop
    
    const char* origsig = BlockSig(blk);
    if( origsig )
    {
        origSignature = [NSString stringWithUTF8String:origsig];
    }
    
    BOOL isvalidCallback = [observerSignature isEqualToString:origSignature] /*|| [self isSignature:observerSignature containSubclassOf:origSignature]*/;
#ifdef DEBUG
    if( !isvalidCallback )
    {
        NSLog(@"BlockNotification:callback invalid for %@",notificationname);
        NSException* exception = [NSException exceptionWithName:@"NotificationService" reason:[NSString stringWithFormat:@"%@ callback invalid",notificationname] userInfo:nil];
        [exception raise];
    }
    NSLog(@"BlockNotification:callback sig:%@,%@valid for origsig:%@",origSignature,isvalidCallback?@"":@"in",observerSignature);
#endif
    return isvalidCallback;
}

- (NSString*)getClassnameFromSignature:(NSString*)signature;
{
    NSMethodSignature* methodSignature = [NSMethodSignature signatureWithObjCTypes:signature.UTF8String];
    CHECKANDRET(methodSignature.numberOfArguments==2, nil);
    
    const char* type = [methodSignature getArgumentTypeAtIndex:1];
    NSString* argtype = [NSString stringWithUTF8String:type];
    
    CHECKINPUTANDRET([argtype hasPrefix:@"@"], nil, @"arg not obj:%@",argtype);
    if( [argtype isEqualToString:@"@"] )
    {
        return @"NSObject";
    }
    CHECKINPUTANDRET([argtype hasPrefix:@"@\""]&&[argtype hasSuffix:@"\""]&&argtype.length>3, nil, @"arg not invalid obj:%@",argtype);
    return [argtype substringWithRange:NSMakeRange(2, argtype.length-3)];
}
/*
- (BOOL)isSignature:(NSString*)observerSignature containSubclassOf:(NSString*)origSignature;
{
    NSMethodSignature* observerMethodSignature = [NSMethodSignature signatureWithObjCTypes:observerSignature.UTF8String];
    NSMethodSignature* origMethodSignature = [NSMethodSignature signatureWithObjCTypes:origSignature.UTF8String];
    CHECKANDRET(observerMethodSignature.numberOfArguments == 2 && origMethodSignature.numberOfArguments == 2 , NO);
    
    NSString* observerClsName = [self getClassnameFromSignature:observerSignature];
    NSString* origClsName = [self getClassnameFromSignature:origSignature];
    CHECKINPUTANDRET(observerClsName && origClsName, NO, @"nil cls name");
    
    NSString* parsedObserverClsName = [self parseClassName:observerClsName];
    NSString* parsedOrigClsName = [self parseClassName:origClsName];
    NSString* parsedObserverProtocolName = [self parseProtocolName:observerClsName];
    NSString* parsedOrigProtocolName = [self parseProtocolName:origClsName];
    CHECKINPUTANDRET( parsedObserverClsName && parsedOrigClsName, NO, @"parsed nil cls name");
    
    Class observerCls = NSClassFromString([self parseClassName:observerClsName]);
    Class origCls = NSClassFromString([self parseClassName:origClsName]);
    CHECKINPUTANDRET(observerCls && origCls, NO, @"cant get cls");
    
    BOOL isSubClass = [observerCls isSubclassOfClass:origCls];
    CHECKINPUTANDRET(isSubClass, NO, @"not sub class");
    
    CHECKANDRET(parsedOrigProtocolName, YES);
    
    Protocol* origProtocol = NSProtocolFromString(parsedOrigProtocolName);
    CHECKANDRET(origProtocol, YES);
    
    CHECKANDRET(!class_conformsToProtocol(observerCls, origProtocol), YES);
    
    CHECKANDRET(parsedObserverProtocolName, NO);
    Protocol* observeProtocol = NSProtocolFromString(parsedObserverProtocolName);
    CHECKANDRET(observeProtocol, NO);
    
    return protocol_conformsToProtocol(observeProtocol, origProtocol);
}

- (NSString*)parseClassName:(NSString*)className;
{
    NSRange lprange = [className rangeOfString:@"<"];
    if( lprange.location != NSNotFound )
    {
        if( lprange.location > 0 )
        {
            return [className substringToIndex:lprange.location];
        }
        else
        {
            return @"NSObject";
        }
    }
    return className;
}

- (NSString*)parseProtocolName:(NSString*)className;
{
    NSRange lprange = [className rangeOfString:@"<"];
    NSRange rprange = [className rangeOfString:@">"];
    
    CHECKANDRET(lprange.location != NSNotFound && rprange.location != NSNotFound && className.length > 2 && lprange.location+1 < rprange.location, nil);
    return [className substringWithRange:NSMakeRange(lprange.location+1, rprange.location-lprange.location-1)];
}
 */
@end
