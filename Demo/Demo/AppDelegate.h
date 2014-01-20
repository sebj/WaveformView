
//  AppDelegate.h
//  Demo

//  Created by Seb Jachec on 20/01/2014.
//  Copyright (c) 2014 Seb Jachec. All rights reserved.

#import <Cocoa/Cocoa.h>

@class LiveWaveformView;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet LiveWaveformView *waveformView;

@end
