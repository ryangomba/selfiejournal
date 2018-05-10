// Copyright 2014-present Ryan Gomba. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@interface SJVideoRecorder : NSObject

- (id)initWithFilePath:(NSString *)filePath;
- (id)initWithFilePath:(NSString *)filePath pixelBufferAttributes:(NSDictionary*)attributes;

@property (nonatomic, copy, readonly) NSString *filePath;

// For use in conjunction with appendPixelBuffer:withPresentationTime:
// returns NULL if pixel attributes were not specified in the initializer
@property (nonatomic, readonly) CVPixelBufferPoolRef pixelBufferPool;

// this is a blocking call, execute on a background thread to prevent stalling the current thread
// Returns YES if writing has successfuly begun. Otherwise `error` will indicate the error.
- (BOOL)startWritingWithTransform:(CGAffineTransform)transform error:(NSError **)error;

// it's safe to call this even while simultaneously appending sample buffers on another queue
// insepct the return value of the append* functions to determine wheter a sample was appended or not
- (void)finishWritingWithCompletionHandler:(dispatch_block_t)completion;

// call these before [startWritingToURL:transform:error:] with the formatDescriptions of the samples to be
// appended to warm-up the encoding pipeline. Failing to prewarm may cause initial samples to be dropped
- (void)prewarmVideoInput:(CMFormatDescriptionRef)formatDescription;
- (void)prewarmAudioInput:(CMFormatDescriptionRef)formatDescription;

// audio and video samples can be safely appended from two different queues respectively
- (BOOL)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (BOOL)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)time;
- (BOOL)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

+ (CGAffineTransform)transformForInterfaceOrientation:(UIInterfaceOrientation)orientation
                                       devicePosition:(AVCaptureDevicePosition)position;

@end
