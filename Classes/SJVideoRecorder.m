// Copyright 2014-present Ryan Gomba. All rights reserved.

#import "SJVideoRecorder.h"
#import <CoreImage/CoreImage.h>

@interface SJVideoRecorder () {
    AVAssetWriter *_assetWriter;

    AVAssetWriterInput *_videoInput;
    AVAssetWriterInput *_audioInput;

    AVAssetWriterInputPixelBufferAdaptor *_pixelBufferAdaptor;
    NSDictionary *_pixelBufferAttributes;

    NSLock *_audioLock, *_videoLock;

    BOOL _didSetSessionStartTime, _didFinishWriting;
    CMTime _lastFrameTime;
}

@property (nonatomic, copy, readwrite) NSString *filePath;

@end


@implementation SJVideoRecorder

- (id)initWithFilePath:(NSString *)filePath {
    return [self initWithFilePath:filePath pixelBufferAttributes:nil];
}

- (id)initWithFilePath:(NSString *)filePath pixelBufferAttributes:(NSDictionary *)attributes {
    if ((self = [super init])) {
        _filePath = filePath;
        _pixelBufferAttributes = attributes;
        _audioLock = [NSLock new];
        _videoLock = [NSLock new];
    }
    return self;
}

- (CVPixelBufferPoolRef)pixelBufferPool {
    if (!_pixelBufferAttributes) {
        return NULL;
    }
    if (!_pixelBufferAdaptor) {
        if (!_videoInput) {
            [self prewarmVideoInput:NULL];
        }
        _pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_videoInput
                                                                         sourcePixelBufferAttributes:_pixelBufferAttributes];
    }
    return _pixelBufferAdaptor.pixelBufferPool;
}

- (void)prewarmVideoInput:(CMFormatDescriptionRef)formatDescription {
    [_videoLock lock];
    if (!_videoInput || !CMFormatDescriptionEqual(_videoInput.sourceFormatHint, formatDescription)) {
        const float bitsPerPixel = 8;
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
        int numPixels = dimensions.width * dimensions.height;
        int bitsPerSecond = numPixels * bitsPerPixel;

        NSDictionary *outputSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                         AVVideoWidthKey: @(dimensions.width),
                                         AVVideoHeightKey: @(dimensions.height),
                                         AVVideoCompressionPropertiesKey: @{AVVideoAverageBitRateKey: @(bitsPerSecond),
                                                                            AVVideoMaxKeyFrameIntervalKey: @30}};
        if (!formatDescription) {
            _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
        } else {
            _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                             outputSettings:outputSettings
                                                           sourceFormatHint:formatDescription];
        }
        _videoInput.expectsMediaDataInRealTime = YES;
    }
    [_videoLock unlock];
}

- (void)prewarmAudioInput:(CMFormatDescriptionRef)formatDescription {
    if (!formatDescription) {
        return;
    }
    [_audioLock lock];
    if (!_audioInput) {
        const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);

        size_t aclSize = 0;
        const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, &aclSize);
        NSData *currentChannelLayoutData = nil;

        // AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
        if (currentChannelLayout && aclSize > 0) {
            currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
        } else {
            currentChannelLayoutData = [NSData data];
        }
        NSDictionary *outputSettings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                         AVSampleRateKey: @(currentASBD->mSampleRate),
                                         AVEncoderBitRatePerChannelKey: @64000,
                                         AVNumberOfChannelsKey: @(currentASBD->mChannelsPerFrame),
                                         AVChannelLayoutKey: currentChannelLayoutData};

        _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                         outputSettings:outputSettings
                                                       sourceFormatHint:formatDescription];
        _audioInput.expectsMediaDataInRealTime = YES;
    }
    [_audioLock unlock];
}

- (BOOL)startWritingWithTransform:(CGAffineTransform)transform error:(NSError *__autoreleasing *)outError {
    if (!_videoInput && !_audioInput) {
        if (outError) {
            // FIXME: add userInfo
            *outError = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorUnknown userInfo:nil];
        }
        return NO;
    }

    __autoreleasing NSError *error;
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:self.filePath];
    _assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
        _assetWriter = nil;
        if (outError) {
            *outError = error;
        }
        return NO;
    }

    [_audioLock lock];
    if (_audioInput) {
        if ([_assetWriter canAddInput:_audioInput]) {
            [_assetWriter addInput:_audioInput];
        } else {
            if (outError) {
                // FIXME: add userInfo
                *outError = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorUnknown userInfo:nil];
            }
            [_audioLock unlock];
            return NO;
        }
    }
    [_audioLock unlock];

    [_videoLock lock];
    _videoInput.transform = transform;
    if ([_assetWriter canAddInput:_videoInput]) {
        [_assetWriter addInput:_videoInput];
    } else {
        if (outError) {
            // FIXME: add userInfo
            *outError = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorUnknown userInfo:nil];
        }
        [_videoLock unlock];
        return NO;
    }
    [_videoLock unlock];

    _didSetSessionStartTime = NO;
    _didFinishWriting = NO;
    return [_assetWriter startWriting];
}

- (void)finishWritingWithCompletionHandler:(dispatch_block_t)completion {
    [_videoLock lock];
    [_audioLock lock];
    _didFinishWriting = YES;    // no more samples will be appended after this
    [_audioLock unlock];
    [_videoLock unlock];

    __block SJVideoRecorder *s = self;
    __block dispatch_block_t block = [completion copy];
    [_assetWriter endSessionAtSourceTime:_lastFrameTime];   // cuts off audio samples past the last frame
    [_assetWriter finishWritingWithCompletionHandler:^{
        if (block) {
            block();
            block = nil;    // release the block here
        }
        s->_videoInput = nil;
        s->_audioInput = nil;
        s->_assetWriter = nil;
        s = nil;    // prevents deallocation of self until this point
    }];
}

- (void)startSessionAtSourceTime:(CMTime)time {
    [_audioLock lock];
    [_assetWriter startSessionAtSourceTime:time];
    _didSetSessionStartTime = YES;
    [_audioLock unlock];
}

- (BOOL)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // TODO all the time?
    [self prewarmVideoInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
    
    [_videoLock lock];
    if (!_didSetSessionStartTime) {
        [self startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
    }
    BOOL success = _didFinishWriting || ![_videoInput isReadyForMoreMediaData] ? NO : [_videoInput appendSampleBuffer:sampleBuffer];
    if (success) {
        _lastFrameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    }
    [_videoLock unlock];

    return success;
}

- (BOOL)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)time {
    [_videoLock lock];
    if (!_didSetSessionStartTime) {
        [self startSessionAtSourceTime:time];
    }
    BOOL success = _didFinishWriting || ![_videoInput isReadyForMoreMediaData] ? NO : [_pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
    if (success) {
        _lastFrameTime = time;
    }
    [_videoLock unlock];

    return success;
}

- (BOOL)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // TODO all the time?
    [self prewarmAudioInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
    
    [_audioLock lock];
    BOOL success = YES;
    if (_didSetSessionStartTime) {
        success = _didFinishWriting || ![_audioInput isReadyForMoreMediaData] ? NO : [_audioInput appendSampleBuffer:sampleBuffer];
    }
    [_audioLock unlock];

    return success;
}

+ (CGAffineTransform)transformForInterfaceOrientation:(UIInterfaceOrientation)orientation
                                       devicePosition:(AVCaptureDevicePosition)position
{
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            return CGAffineTransformMakeRotation(position == AVCaptureDevicePositionFront ? 0 : M_PI);
        case UIInterfaceOrientationLandscapeRight:
            return CGAffineTransformMakeRotation(position == AVCaptureDevicePositionFront ? M_PI : 0);
        case UIInterfaceOrientationPortrait:
            return CGAffineTransformMakeRotation(M_PI_2);
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGAffineTransformMakeRotation(-M_PI_2);
        default:
            return CGAffineTransformIdentity;
    }
}

@end
