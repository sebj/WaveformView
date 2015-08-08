
// HybridWaveformView.h

// Created by Seb Jachec on 20/11/2013.
// Copyright (c) 2013 Seb Jachec. All rights reserved.

#import "LiveWaveformView.h"

@class WaveformView;

/**
 * Bridges WaveformView, which just takes saved files, and LiveWaveformView, which plots sound live.
 */
@interface HybridWaveformView : LiveWaveformView

/**
 * Access the WaveformView (files only) to direct all trim, play, stop etc. commands to it.
 */
@property WaveformView *fileView;


/**
 * Properties and selectors from the file waveform view
 * (This view takes over responsibility for some things, forwarding back)
 * See WaveformView.h
 */

IBInspectable @property BOOL trimEnabled;

IBInspectable @property (strong) NSColor *trimHandleColor;
IBInspectable @property (strong) NSColor *inactiveColor;

@end
