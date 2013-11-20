
// LiveWaveformView.h

// Created by Seb Jachec on 19/11/2013.
// Copyright (c) 2013 Seb Jachec. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

/**
 * Give it an AVAudioRecorder and watch it plot a waveform - live. Customise foreground and background colours. Redirects AVAudioRecorderDelegate methods back to "original" delegate.
 */
@interface LiveWaveformView : NSView <AVAudioRecorderDelegate> {
    NSMutableArray *samples;
    
    id originalDelegate;
    
    NSTimer *refreshTimer;
}

/**
 * Width to plot each sample - default is 2.0.
 */
@property float sampleWidth;

@property (strong) NSColor *foregroundColor;
@property (strong) NSColor *backgroundColor;
@property (strong) NSColor *inactiveColor;

@property (strong, setter = attachToRecorder:) AVAudioRecorder *recorder;

/**
 * The following methods take over from AVAudioRecorder, taking over from AVAudioRecorder:
 */

- (void)record;
- (void)recordForDuration:(NSTimeInterval)aDuration;

- (void)stop;

@end
