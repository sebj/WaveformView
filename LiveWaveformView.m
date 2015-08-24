
// LiveWaveformView.m

// Created by Seb Jachec on 19/11/2013.
// Copyright (c) 2013 Seb Jachec. All rights reserved.

#import "LiveWaveformView.h"
#import "math.h"
#import "WaveformViewShared.h"

@implementation LiveWaveformView

//Style inspired by Arduino's map function
double map(double x, double in_min, double in_max, double out_min, double out_max) {
    //Math from http://stackoverflow.com/a/5732390/447697
    double slope = 1.0 * (out_max - out_min) / (in_max - in_min);
    return out_min + slope * (x - in_min);
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setup];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self setup];
    return self;
}

- (void)setup {
    _sampleWidth = 2.0f;
    _backgroundColor = DefaultBackgroundColor;
    _foregroundColor = DefaultForegroundColor;
    _inactiveColor = DefaultInactiveColor;
}

#pragma mark Recording

- (void)prepareToRecord {
    samples = [NSMutableArray new];
    
    _recorder.meteringEnabled = YES;
    
    if (_recorder.delegate) originalDelegate = _recorder.delegate;
    
    _recorder.delegate = self;
}

- (void)record {
    [self recordForDuration:0.0 FinishBlock:nil];
}

- (void)recordForDuration:(NSTimeInterval)aDuration {
    [self recordForDuration:aDuration FinishBlock:nil];
}

- (void)recordForDuration:(NSTimeInterval)aDuration FinishBlock:(nullable void (^)())aBlock {
    [self prepareToRecord];
    
    if (aDuration > 0.0) {
        [_recorder recordForDuration:aDuration];
        
    } else {
        [_recorder record];
    }
    
    // 40/s
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.025 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    
    finishBlock = aBlock;
}

- (void)stop {
    [_recorder stop];
}

#pragma mark Delegate Methods

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    //Redirect to original delegate
    
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(audioRecorderEncodeErrorDidOccur:error:)]) {
        SEL aSelector = NSSelectorFromString(@"audioRecorderEncodeErrorDidOccur:error:");
        
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[originalDelegate methodSignatureForSelector:aSelector]];
        [inv setSelector:aSelector];
        [inv setTarget:originalDelegate];
        
        [inv setArgument:&(_recorder) atIndex:2]; //Arguments 0 and 1 are self and _cmd, automatically set
        [inv setArgument:&(error) atIndex:3]; //Arguments 0 and 1 are self and _cmd, automatically set
        
        [inv invoke];
    }
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    //Redirect to original delegate
    
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(audioRecorderDidFinishRecording:successfully:)]) {
        SEL aSelector = NSSelectorFromString(@"audioRecorderDidFinishRecording:successfully:");
        
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[originalDelegate methodSignatureForSelector:aSelector]];
        [inv setSelector:aSelector];
        [inv setTarget:originalDelegate];
        
        [inv setArgument:&(_recorder) atIndex:2]; //Arguments 0 and 1 are self and _cmd, automatically set
        [inv setArgument:&(flag) atIndex:3]; //Arguments 0 and 1 are self and _cmd, automatically set        
        [inv invoke];
    }
    
    [refreshTimer invalidate];
    refreshTimer = nil;
    
    if (finishBlock) finishBlock();
    
    [self finishedRecording];
}

- (void)finishedRecording {
    //Can be overridden by subclasses
}

#pragma mark Other

- (void)refresh {
    
    if (_recorder && _recorder.isRecording) {
        if (floor(samples.count*_sampleWidth) > ceil(_bounds.size.width)) [samples removeObjectAtIndex:0];
        
        [_recorder updateMeters];
        [samples addObject:@(round([_recorder averagePowerForChannel:0]))];
        
        self.needsDisplay = YES;
    }
}

- (void)viewDidEndLiveResize {
    #ifdef DEBUG
    NSLog(@"LiveWaveformView: Resize ended");
    #endif
    
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [_backgroundColor? _backgroundColor : DefaultBackgroundColor set];
    NSRectFill(_bounds);
    
    if (self.window && !(self.window.occlusionState & NSWindowOcclusionStateVisible)) {
        return;
    }
    
    if (samples.count>1) {
        [_foregroundColor? _foregroundColor : DefaultForegroundColor set];
        
        for (u_int16_t i = 0; i<samples.count-1; i++) {
            float sample = [samples[i] floatValue];
            
            u_int16_t height = 0;
            
            //Testing suggests less than -57 is inaudible
            //Map 0 to -60 scale to a 1 to 0 scale
            if (sample >= -60) {
                height = (map(sample, -60, 0, 0, 1))*_bounds.size.height;
            }
            
            NSRect rect = NSMakeRect(i*_sampleWidth, (_bounds.size.height-height)/2, _sampleWidth, height);
            NSRectFillUsingOperation(rect, NSCompositeSourceOver);
        }
        
        if (_drawsCenterLine) {
            //[_foregroundColor? _foregroundColor : DefaultForegroundColor setFill];
            
            NSBezierPath *centerLine = [NSBezierPath bezierPathWithRect:NSMakeRect(0, round((_bounds.size.height/2)-1), _bounds.size.width, 2)];
            [centerLine fill];
        }
        
        float x = round(samples.count*_sampleWidth);
        NSRect darken = NSMakeRect(x, 0, _bounds.size.width-x, _bounds.size.height);
        [_inactiveColor? _inactiveColor : DefaultInactiveColor set];
        NSRectFill(darken);
    }
}

@end
