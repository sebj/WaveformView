
// LiveWaveformView.m

// Created by Seb Jachec on 19/11/2013.
// Copyright (c) 2013 Seb Jachec. All rights reserved.

#import "LiveWaveformView.h"
#import "math.h"

#define kDefaultBackgroundColor [NSColor whiteColor]
#define kDefaultForegroundColor [NSColor blackColor]
#define kDefaultInactiveColor [NSColor colorWithCalibratedWhite:0.1 alpha:1.0]

@implementation LiveWaveformView

//Style inspired by Arduino's map function
double map(double x, double in_min, double in_max, double out_min, double out_max) {
    //Math from http://stackoverflow.com/a/5732390/447697
    double slope = 1.0 * (out_max - out_min) / (in_max - in_min);
    return out_min + slope * (x - in_min);
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _sampleWidth = 2.0f;
    }
    
    return self;
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

- (void)recordForDuration:(NSTimeInterval)aDuration FinishBlock:(void (^)())aBlock {
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
        
        [inv setArgument:&(_recorder) atIndex:2]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv setArgument:&(error) atIndex:3]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        
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
        
        [inv setArgument:&(_recorder) atIndex:2]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv setArgument:&(flag) atIndex:3]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        
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
        if (samples.count*_sampleWidth > _bounds.size.width)
            [samples removeObjectAtIndex:0];
        
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
    [_backgroundColor? _backgroundColor : kDefaultBackgroundColor set];
    NSRectFill(_bounds);
    
    if (samples.count>1) {
        [_foregroundColor? _foregroundColor : kDefaultForegroundColor set];
        
        for (u_int16_t i = 0; i<samples.count-1; i++) {
            float sample = [samples[i] floatValue];
            
            u_int16_t height = 0;
            
            //When I checked, roughly less than -57 was inaudible
            if (sample > -57) {
                //Map the 0 to -60 scale to a 1 to 0 scale
                height = (map(sample, -60, 0, 0, 1))*_bounds.size.height;
            }
            
            NSRect rect = NSMakeRect(i*_sampleWidth, (_bounds.size.height-height)/2, _sampleWidth, height);
            NSRectFillUsingOperation(rect, NSCompositeSourceOver);
        }
        
        NSRect darken = NSMakeRect(samples.count*_sampleWidth, 0, _bounds.size.width-(samples.count*_sampleWidth), _bounds.size.height);
        [_inactiveColor? _inactiveColor : kDefaultInactiveColor set];
        NSRectFill(darken);
    }
}

@end
