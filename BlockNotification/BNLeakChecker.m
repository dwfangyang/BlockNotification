//
//  BNLeakChecker.m
//  BlockNotification
//
//  Created by 方阳 on 2018/8/7.
//  Copyright © 2018年 yy. All rights reserved.
//

#import "BNLeakChecker.h"

//dispose_helper dealloc the objects that block retains according to their memory address
//So we can fake an array of objects and use dispose_helper to dealloc our objects, and then we can find out which object of the array is not existed. So we can get indexed and retrieve all the objects which block has retained
//we are faking objects that would otherwise be captured by block and we try to figure out which one the block will hold strongly. The way we do it is by using dispose helper which will take care of sending release message to objects it captured strongly

#import <objc/runtime.h>

static void byref_keep_nop(struct _block_byref_block *dst, struct _block_byref_block *src) {}
static void byref_dispose_nop(struct _block_byref_block *param) {}

@implementation BNStrongReferenceDetector

- (oneway void)release
{
    _strong = YES;
}

- (id)retain
{
    return self;
}

+ (id)alloc
{
    BNStrongReferenceDetector *obj = [super alloc];
    
    // Setting up block fakery
    obj->forwarding = obj;
    obj->byref_keep = byref_keep_nop;
    obj->byref_dispose = byref_dispose_nop;
    
    return obj;
}

- (oneway void)trueRelease
{
    [super release];
}

- (void *)forwarding
{
    return self->forwarding;
}

@end

static NSIndexSet *_GetBlockStrongLayout(void *block)
{
    struct Block_literal_BN* blockLiteral = block;
    
    /**
     BLOCK_HAS_CTOR - Block has a C++ constructor/destructor, which gives us a good chance it retains
     objects that are not pointer aligned, so omit them.
     !BLOCK_HAS_COPY_DISPOSE - Block doesn't have a dispose function, so it does not retain objects and
     we are not able to blackbox it.
     */
    if ((blockLiteral->flags & BLOCK_HAS_CTOR)
        || !(blockLiteral->flags & BLOCK_HAS_COPY_DISPOSE)) {
        return nil;
    }
    
    void (*dispose_helper)(void *src) = blockLiteral->descriptor->dispose_helper;
    const size_t ptrSize = sizeof(void *);
    
    // Figure out the number of pointers it takes to fill out the object, rounding up.
    const size_t elements = (blockLiteral->descriptor->size + ptrSize - 1) / ptrSize;
    
    // Create a fake object of the appropriate length.
    void *obj[elements];
    void *detectors[elements];
    
    for (size_t i = 0; i < elements; ++i) {
        BNStrongReferenceDetector *detector = [BNStrongReferenceDetector new];
        obj[i] = detectors[i] = detector;
    }
    
    @autoreleasepool {
        dispose_helper(obj);
    }
    
    // Run through the release detectors and add each one that got released to the object's
    // strong ivar layout.
    NSMutableIndexSet *layout = [NSMutableIndexSet indexSet];
    
    for (size_t i = 0; i < elements; ++i) {
        BNStrongReferenceDetector *detector = (BNStrongReferenceDetector *)(detectors[i]);
        if (detector.isStrong) {
            [layout addIndex:i];
        }
        
        // Destroy detectors
        [detector trueRelease];
    }
    return layout;
}

@implementation BNLeakChecker

+ (instancetype)sharedChecker;
{
    static BNLeakChecker* checker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        checker = [BNLeakChecker new];
    });
    return checker;
}

- (BOOL)isBlock:(id)block retainObserver:(id)observer
{
    NSMutableArray *results = [NSMutableArray new];
    
    void **blockReference = (void**)block;
    NSIndexSet *strongLayout = _GetBlockStrongLayout(block);
    [strongLayout enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        void **reference = &blockReference[idx];
        
        if (reference && (*reference)) {
            id object = (id)(*reference);
            
            if (object) {
                [results addObject:object];
            }
        }
    }];
    if( [results containsObject:observer] )
    {
        return YES;
    }
    [results release];
    return NO;
}
@end
