
// WaveformView.h

// Created by Seb Jachec on 16/11/2013.
// Copyright (c) 2013 Seb Jachec. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

/**
 * Give it a .wav and watch it plot - customise all colours, and enable trimming handles
 */
@interface WaveformView : NSView {
    AVURLAsset *currentAsset;
    
    NSMutableArray *points;
    NSImage *cacheImage;
    
    float secondInPixels;
    NSSlider *trimSlider;
    
    AVAudioPlayer *player;
    NSTimer *stopTimer;
}

/**
 * Returns sound duration in seconds
 */
@property (readonly) double duration;

@property BOOL trimEnabled;
/**
 * Returns time range using trimming handle. If trimming is disabled, trimRange is kkCMTimeZero, kCMTimePositiveInfinity
 */
@property (readonly) CMTimeRange trimRange;

@property (strong) NSColor *foregroundColor;
@property (strong) NSColor *backgroundColor;
@property (strong) NSColor *trimHandleColor;
@property (strong) NSColor *inactiveColor;


- (BOOL)loadFileWithPath:(NSString*)filePath;
- (BOOL)loadURL:(NSURL*)aURL;

- (void)play;
- (void)stop;

/**
 * Returns an NSImage with the waveform, the same size as this view's bounds
 */
- (NSImage*)waveformImage;

@end
