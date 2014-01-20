
//  AppDelegate.m
//  Demo

//  Created by Seb Jachec on 20/01/2014.
//  Copyright (c) 2014 Seb Jachec. All rights reserved.

#import "AppDelegate.h"
#import "LiveWaveformView.h"

#import <AVFoundation/AVFoundation.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //Setup the waveform view's colors..
    _waveformView.backgroundColor = [NSColor colorWithCalibratedRed:0.21 green:0.49 blue:0.89 alpha:1.00];
    _waveformView.foregroundColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.2];
    _waveformView.inactiveColor = [NSColor colorWithCalibratedRed:0.07 green:0.11 blue:0.20 alpha:1.00];
    
    
    //Setup an AVAudioRecorder with the save URL and recording settings
    NSURL *saveURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@.wav",NSTemporaryDirectory(),[NSDate date].description]];
    NSLog(@"Saving to %@",saveURL.path);
    
    NSDictionary *settings = @{AVSampleRateKey:@(44100.0),
                               AVFormatIDKey:@(kAudioFormatLinearPCM),
                               AVNumberOfChannelsKey:@2.0};
    
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:saveURL settings:settings error:nil];
    
    //Attach the recorder to the waveform view
    _waveformView.recorder = recorder;
    //Alternatively:
    //[_waveformView attachToRecorder:recorder];
    
    
    //Start recording
    [_waveformView recordForDuration:15.0 FinishBlock:^{
        //Note: following lines are not the best way to do things..
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[saveURL]];
        [_window close];
        NSLog(@"Finished recording!");
    }];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return TRUE;
}

@end
