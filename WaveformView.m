
// WaveformView.m

// Created by Seb Jachec on 16/11/2013.
// Copyright (c) 2013 Seb Jachec. All rights reserved.

#import "WaveformView.h"
#import <AVFoundation/AVFoundation.h>


#pragma mark - Trim Slider

#define kTrimSliderKnobHeight 22
#define kTrimSliderKnobWidth 6

#define kDefaultTrimHandleColor [NSColor grayColor]

@interface TrimSliderCell : NSSliderCell
@property (strong) NSColor *color;
@end

@implementation TrimSliderCell

//Solution to out-of-sync slider: http://stackoverflow.com/a/8617184/447697
- (NSRect)knobRectFlipped:(BOOL)flipped {
    CGFloat value = (self.doubleValue-_minValue)/(_maxValue-_minValue);
    NSRect defaultRect = [super knobRectFlipped:flipped];
    NSRect myRect = NSMakeRect(0, 0, kTrimSliderKnobWidth, kTrimSliderKnobHeight);
    
    //Added abs() to round/crispen pixels - even if it is slightly off
    myRect.origin.x = round(value * (self.controlView.frame.size.width - kTrimSliderKnobWidth));
    myRect.origin.y = round(defaultRect.origin.y + defaultRect.size.height/2.0 - myRect.size.height/2.0);
    
    return myRect;
}

- (void)drawKnob:(NSRect)knobRect {
    [_color set];
    NSRectFillUsingOperation(knobRect, NSCompositeSourceOver);
}

- (void)drawBarInside:(NSRect)frame flipped:(BOOL)flipped { }

- (BOOL)isOpaque {
    return NO;
}

@end


#define mark - WaveformView

#define absX(x) (x<0?0-x:x)
#define minMaxX(x,mn,mx) (x<=mn?mn:(x>=mx?mx:x))
#define noiseFloor (-50.0)
#define decibel(amplitude) (20.0 * log10(absX(amplitude)/32767.0))

#define kSettings @{AVFormatIDKey:@(kAudioFormatLinearPCM), AVNumberOfChannelsKey:@2.0}

#define kDefaultBackgroundColor [NSColor whiteColor]
#define kDefaultForegroundColor [NSColor blackColor]
#define kDefaultInactiveColor [NSColor colorWithCalibratedWhite:0.1 alpha:1.0]

@implementation WaveformView

@synthesize duration = _duration;
@synthesize trimRange = _trimRange;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addObserver:self forKeyPath:@"trimEnabled" options:0 context:NULL];
        
        trimSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(0, (_bounds.size.height-21)/2, 1, 21)];
        trimSlider.cell = [TrimSliderCell new];
        trimSlider.target = self;
        trimSlider.action = @selector(sliderChanged);
        
        _backgroundColor = kDefaultBackgroundColor;
        _foregroundColor = kDefaultForegroundColor;
        _inactiveColor = kDefaultInactiveColor;
    }
    return self;
}

#pragma mark Load files

- (BOOL)loadFileWithPath:(NSString*)filePath {
    return [self loadURL:[NSURL fileURLWithPath:filePath]];
}

- (BOOL)loadURL:(NSURL*)aURL{
    currentAsset = [AVURLAsset URLAssetWithURL:aURL options:nil];
    return [self processWaveformForAsset:currentAsset];
}

#pragma mark Player

- (void)play {
    [self stop];
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:currentAsset.URL error:NULL];
    
    [player play];
    
    float durationToPlay = trimSlider.doubleValue;
    float remainder = durationToPlay-player.currentTime;
    
    [stopTimer invalidate];
    stopTimer = nil;
    
    stopTimer = [NSTimer scheduledTimerWithTimeInterval:remainder target:player selector:@selector(stop) userInfo:NULL repeats:NO];
}

- (void)stop {
    if (player && player.isPlaying) [player stop];
}

#pragma mark React to Changes

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self && [keyPath isEqualToString:@"trimEnabled"])
        [self updateTrimSlider];
}

- (void)sliderChanged {
    //Constrain slider
    if (trimSlider.doubleValue <= 0.5) [trimSlider setDoubleValue:0.5];
    
    self.needsDisplay = YES;
    _trimRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(trimSlider.doubleValue, 1));
}

- (void)viewDidEndLiveResize {
    #ifdef DEBUG
    NSLog(@"Resize ended");
    #endif
    
    cacheImage = nil;
    [self processWaveformForAsset:currentAsset];
}

#pragma mark Drawing, Processing

- (void)drawRect:(NSRect)dirtyRect {
    [_backgroundColor? _backgroundColor : kDefaultBackgroundColor set];
    NSRectFill(_bounds);
    
    if (currentAsset) {
        if (points) {
            if (!cacheImage) cacheImage = [self waveformImage];
            
            //Stretch image vertically
            if (!NSEqualSizes(_bounds.size, cacheImage.size)) {
                NSImage *image = [[NSImage alloc] initWithSize:_bounds.size];
                [image lockFocus];
                NSGraphicsContext *ctxt = NSGraphicsContext.currentContext;
                ctxt.shouldAntialias = NO;
                ctxt.imageInterpolation = NSImageInterpolationNone;
                
                [cacheImage drawInRect:NSMakeRect(0, 0, cacheImage.size.width, _bounds.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
                
                ctxt.shouldAntialias = YES;
                ctxt.imageInterpolation = NSImageInterpolationDefault;
                [image unlockFocus];
                
                cacheImage = image;
            }
            
            [cacheImage drawAtPoint:NSMakePoint(0, (_bounds.size.height-cacheImage.size.height)/2) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
            
            //Visualise trim
            if (_trimEnabled) {
                int x = (secondInPixels*trimSlider.doubleValue);
                NSRect shadeRect = NSMakeRect(x, 0, _bounds.size.width-x, _bounds.size.height);
                [_inactiveColor? _inactiveColor : kDefaultInactiveColor set];
                NSRectFill(shadeRect);
            }
        }
    }
}

- (NSImage*)waveformImage {
    NSImage *image = [[NSImage alloc] initWithSize:_bounds.size];
    [image lockFocus];
    [self drawWaveform];
    [image unlockFocus];
    
    return image;
}

- (void)drawWaveform {
    if (points) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        
        int i = 0;
        for (NSValue *val in points) {
            if ((i%2)==0 || i == 0) {
                [path moveToPoint:val.pointValue];
            } else {
                [path lineToPoint:val.pointValue];
            }
            
            i++;
        }
        [path closePath];
        //Setup vars (important!)
        secondInPixels = ((NSValue*)points.lastObject).pointValue.x/(float)_duration;
        [self updateTrimSlider];
        
        [_foregroundColor? _foregroundColor : kDefaultForegroundColor setStroke];
        [path setLineWidth:2.0f];
        
        NSGraphicsContext *ctxt = NSGraphicsContext.currentContext;
        ctxt.shouldAntialias = NO;
        
        [path stroke];
        
        ctxt.shouldAntialias = YES;
    }
}

- (void)updateTrimSlider {
    if (_trimEnabled) {
        float furthestX = ((NSValue*)points.lastObject).pointValue.x;
        [trimSlider setFrame:NSMakeRect(0, (_bounds.size.height-21)/2, furthestX, 21)];
        trimSlider.maxValue = _duration;
        trimSlider.doubleValue = _duration;
        ((TrimSliderCell*)trimSlider.cell).color = _trimHandleColor? _trimHandleColor : kDefaultTrimHandleColor;
    }
    
    if (!_trimEnabled && trimSlider.superview == self) {
        [trimSlider removeFromSuperview];
        _trimRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
        
    } else if (_trimEnabled && trimSlider.superview != self) {
        [self addSubview:trimSlider];
        _trimRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(_duration, 1));
        self.needsDisplay = YES;
    }

}

//From FDWaveformView by William Entriken - https://github.com/fulldecent/FDWaveformView/blob/master/FDWaveformView/FDWaveformView.m
- (BOOL)processWaveformForAsset:(AVURLAsset *)songAsset {
    if (!currentAsset) return NO;
    
    #ifdef DEBUG
    NSLog(@"WaveformView: Started processing");
    #endif
    
    NSError *error;
    
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
    
    if (error) {
        NSLog(@"WaveformView Error: %@",error);
        return NO;
    }
    
    AVAssetTrack *songTrack = (songAsset.tracks)[0];
    _duration = CMTimeGetSeconds(songTrack.timeRange.duration);
    
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:kSettings];
    
    [reader addOutput:output];
    
    UInt32 sampleRate, channelCount;
    
    NSArray *formatDesc = songTrack.formatDescriptions;
    for (unsigned int i = 0; i < formatDesc.count; ++i) {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)formatDesc[i];
        const AudioStreamBasicDescription *fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item);
        if (fmtDesc) {
            sampleRate = fmtDesc->mSampleRate;
            channelCount = fmtDesc->mChannelsPerFrame;
        }
    }
    
    UInt32 bytesPerSample = 2*channelCount;
    Float32 normalizeMax = noiseFloor;
    NSMutableData *fullSongData = [NSMutableData new];
    [reader startReading];
    
    UInt64 totalBytes = 0;
    
    Float64 totalLeft = 0;
    Float64 totalRight = 0;
    Float32 sampleTally = 0;
    
    NSInteger samplesPerPixel = sampleRate/50;
    
    while (reader.status == AVAssetReaderStatusReading){
        AVAssetReaderTrackOutput *trackOutput = (AVAssetReaderTrackOutput*)(reader.outputs)[0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef){
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            totalBytes += length;
            
            @autoreleasepool {
                NSMutableData *data = [NSMutableData dataWithLength:length];
                CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
                
                
                SInt16 *samples = (SInt16 *)data.mutableBytes;
                unsigned long sampleCount = length/bytesPerSample;
                for (int i = 0; i < sampleCount; i++) {
                    
                    Float32 left = (Float32) *samples++;
                    left = decibel(left);
                    left = minMaxX(left,noiseFloor,0);
                    
                    totalLeft += left;
                    
                    
                    Float32 right;
                    if (channelCount == 2) {
                        right = (Float32) *samples++;
                        right = decibel(right);
                        right = minMaxX(right,noiseFloor,0);
                        
                        totalRight += right;
                    }
                    
                    sampleTally++;
                    
                    if (sampleTally > samplesPerPixel) {
                        
                        left  = totalLeft/sampleTally;
                        if (left > normalizeMax) normalizeMax = left;
                        
                        [fullSongData appendBytes:&left length:sizeof(left)];
                        
                        if (channelCount==2) {
                            right = totalRight / sampleTally;
                            
                            if (right > normalizeMax) normalizeMax = right;
                            
                            [fullSongData appendBytes:&right length:sizeof(right)];
                        }
                        
                        totalLeft   = 0;
                        totalRight  = 0;
                        sampleTally = 0;
                        
                    }
                }
            }
            
            CMSampleBufferInvalidate(sampleBufferRef);
            
            CFRelease(sampleBufferRef);
        }
    }
    
    if (reader.status == AVAssetReaderStatusCompleted){
        Float32 *samples = (Float32*)fullSongData.bytes;
        NSInteger sampleCount = fullSongData.length/(sizeof(Float32)*2);
        
        //Actually just taking left channel values to plot
        
        float centerLeft = _bounds.size.height/2;
        float sampleAdjustmentFactor = fabs((_bounds.size.height/(normalizeMax-noiseFloor)/2));
        
        points = [NSMutableArray new];
        
        for (NSInteger intSample = 0; intSample < sampleCount; intSample++) {
            Float32 left = *samples++;
            float pixels = (left - noiseFloor) * sampleAdjustmentFactor;
            [points addObject:[NSValue valueWithPoint:NSMakePoint(intSample, centerLeft-pixels)]];
            [points addObject:[NSValue valueWithPoint:NSMakePoint(intSample, centerLeft+pixels)]];
        }
        
#ifdef DEBUG
        NSLog(@"WaveformView: Finished processing");
#endif
        
        self.needsDisplay = YES;
        
        return YES;
        
    } else if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown){
        NSLog(@"WaveformView AVAssetReader%@",reader.error? [NSString stringWithFormat:@" Error: %@",reader.error] : @"");
        
        return NO;
    } else {
        return NO;
    }
}

@end
