
// LiveWaveformView.h

// Created by Seb Jachec on 19/11/2013.
// Copyright (c) 2013 Seb Jachec. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

/**
 * Give it an AVAudioRecorder and watch it plot a waveform - live. Customise foreground and background colours. Redirects AVAudioRecorderDelegate methods back to "original" delegate.
 */
IB_DESIGNABLE
@interface LiveWaveformView : NSView <AVAudioRecorderDelegate> {
    NSMutableArray *samples;
    
    id originalDelegate;
    
    NSTimer *refreshTimer;
    
    void(^finishBlock)();
}

/**
 * Width to plot each sample - default is 2.0.
 */
IBInspectable @property float sampleWidth;

IBInspectable @property (strong) NSColor *foregroundColor;
IBInspectable @property (strong) NSColor *backgroundColor;
IBInspectable @property (strong) NSColor *inactiveColor;

IBInspectable @property BOOL drawsCenterLine;

/*
 * View takes control of the recorder. Recommended to use methods below.
 */
@property (strong, setter = attachToRecorder:) AVAudioRecorder *recorder;

/**
 * The following methods take over from AVAudioRecorder:
 */

- (void)record;
- (void)recordForDuration:(NSTimeInterval)aDuration;
- (void)recordForDuration:(NSTimeInterval)aDuration FinishBlock:(void (^)())aBlock;

- (void)stop;

@end
