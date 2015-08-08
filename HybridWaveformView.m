
// HybridWaveformView.m

// Created by Seb Jachec on 20/11/2013.
// Copyright (c) 2013 Seb Jachec. All rights reserved.

#import "HybridWaveformView.h"
#import "WaveformView.h"

@implementation HybridWaveformView

@dynamic inactiveColor;

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addTrackingRect:_bounds owner:self userData:nil assumeInside:NO];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self addTrackingRect:_bounds owner:self userData:nil assumeInside:NO];
    }
    return self;
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if (_delegate && [_delegate respondsToSelector:@selector(mouseEntered:)]) {
        [_delegate mouseEntered:theEvent];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    if (_delegate && [_delegate respondsToSelector:@selector(mouseExited:)]) {
        [_delegate mouseExited:theEvent];
    }
}

#if TARGET_INTERFACE_BUILDER
- (void)drawRect:(NSRect)dirtyRect {
    [NSColor.whiteColor set];
    NSRectFill(_bounds);
}
#endif

//Overriding from LiveWaveformView superclass
- (void)finishedRecording {
    [_fileView loadURL:self.recorder.url];
    
    _fileView = [[WaveformView alloc] initWithFrame:_frame];
    _fileView.foregroundColor = self.foregroundColor;
    _fileView.backgroundColor = self.backgroundColor;
    _fileView.trimEnabled = self.trimEnabled;
    _fileView.trimHandleColor = self.trimHandleColor;
    _fileView.inactiveColor = self.inactiveColor;
    _fileView.drawsCenterLine = self.drawsCenterLine;
    
    [self.superview addSubview:_fileView positioned:NSWindowBelow relativeTo:self];
    [self.animator setAlphaValue:0];
    
    [self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.251];
}

@end
