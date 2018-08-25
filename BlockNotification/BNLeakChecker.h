//
//  BNLeakChecker.h
//  BlockNotification
//
//  Created by 方阳 on 2018/8/7.
//  Copyright © 2018年 yy. All rights reserved.
//

#import <Foundation/Foundation.h>

enum { // Flags from BlockLiteral
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE =     (1 << 30),
};

struct Block_descriptor_BN {
    unsigned long int reserved;                     // NULL
    unsigned long int size;                         // sizeof(struct Block_literal_BL)
    // optional helper functions
    void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
    void (*dispose_helper)(void *src);             // IFF (1<<25)
    // required ABI.2010.3.16
    const char *signature;                         // IFF (1<<30)
};

struct Block_literal_BN {
    void *isa;                                      // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct Block_descriptor_BN* descriptor;
    // imported variables
};

struct _block_byref_block;
@interface BNStrongReferenceDetector:NSObject
{
    // __block fakery
    void *forwarding;
    int flags;   //refcount;
    int size;
    void (*byref_keep)(struct _block_byref_block *dst, struct _block_byref_block *src);
    void (*byref_dispose)(struct _block_byref_block *);
    void *captured[16];
}
@property (nonatomic, assign, getter=isStrong) BOOL strong;
- (oneway void)trueRelease;

- (void *)forwarding;
@end

@interface BNLeakChecker : NSObject

+ (instancetype)sharedChecker;

- (BOOL)isBlock:(id)block retainObserver:(id)observer;

@end
