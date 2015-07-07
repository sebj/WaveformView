
// HybridWaveformView.m

// Created by Seb Jachec on 20/11/2013.
// Copyright (c) 2013 Seb Jachec. All rights reserved.

#import "HybridWaveformView.h"
#import "WaveformView.h"

#define observe(x) [self addObserver:self forKeyPath:x options:NSKeyValueObservingOptionNew context:NULL]

@implementation HybridWaveformView

@dynamic inactiveColor;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _fileView = [[WaveformView alloc] initWithFrame:_frame];
        
        observe(@"foregroundColor");
        observe(@"backgroundColor");
        observe(@"trimEnabled");
        observe(@"trimHandleColor");
        observe(@"inactiveColor");
    }
    return self;
}

#if TARGET_INTERFACE_BUILDER
- (void)drawRect:(NSRect)dirtyRect {
    [NSColor.whiteColor set];
    NSRectFill(_bounds);
}
#endif

//Not the best..
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self && _fileView) {
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"set%@:",[keyPath stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[keyPath substringToIndex:1].uppercaseString]]);
        
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_fileView methodSignatureForSelector:selector]];
        [inv setSelector:selector];
        [inv setTarget:_fileView];
        
        id obj = change[@"new"];
        
        //Arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [keyPath isEqualToString:@"trimEnabled"]? [inv setArgument:&_trimEnabled atIndex:2] : [inv setArgument:&(obj) atIndex:2];
        
        [inv invoke];
    }
}

//Overriding from LiveWaveformView superclass
- (void)finishedRecording {
    [_fileView loadURL:self.recorder.url];
    
    [self.superview addSubview:_fileView positioned:NSWindowBelow relativeTo:self];
    [self.animator setAlphaValue:0];
    
    [self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.251];
}

@end
