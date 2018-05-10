// Copyright 2014-present Ryan Gomba. All rights reserved.

#import "SJCaptureManager.h"

#import <ImageIO/ImageIO.h>

#define kMaxStabilizableExposureTime 0.005

@interface SJCaptureManager () <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate> {
    AVCaptureSession *_captureSession;
    AVCaptureDeviceInput *_videoInput, *_audioInput;
    AVCaptureOutput *_videoOutput, *_audioOutput;
    AVCaptureVideoPreviewLayer *_previewLayer;
    dispatch_queue_t _captureQueue;

    BOOL _isSessionConfigured;
    BOOL _lockCount;
    BOOL _didLock;

    volatile double _exposureTime;
}

@end

@implementation SJCaptureManager

- (void)dealloc {
    //
}

- (id)init {
    if (self = [super init]) {
        // FIXME: hack for simulator
        if (![self videoDeviceForPosition:AVCaptureDevicePositionBack]) {
            return nil;
        }

        _sessionPreset = AVCaptureSessionPresetHigh;
        _devicePosition = AVCaptureDevicePositionBack;
        _captureSession = [AVCaptureSession new];
        _captureQueue = dispatch_queue_create("com.instagram.captureQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (AVCaptureDevice *)videoDevice {
    return _videoInput.device;
}

- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition {
    if (_devicePosition != devicePosition) {
        _devicePosition = devicePosition;
        if (_isSessionConfigured) {
            dispatch_async(_captureQueue, ^{
                [self configureVideoInputWithDevicePosition:devicePosition];
            });
        }
    }
}

- (void)setSessionPreset:(NSString *)sessionPreset {
    if (![_sessionPreset isEqualToString:sessionPreset]) {
        _sessionPreset = sessionPreset;
        if (_isSessionConfigured) {
            dispatch_async(_captureQueue, ^{
                [self configureSessionWithPreset:sessionPreset];
            });
        }
    }
}

// WARNING: This must be called on the capture queue
- (void)configureVideoInputWithDevicePosition:(AVCaptureDevicePosition)devicePosition {
    [_captureSession beginConfiguration];   // these can be nested
    if (_videoInput) {
        [_captureSession removeInput:_videoInput];
    }
    __autoreleasing NSError *error;
    _videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self videoDeviceForPosition:devicePosition] error:&error];
    NSAssert(!error, @"Could not initialize video input (%@)", error);
    if ([_captureSession canAddInput:_videoInput]) {
        [_captureSession addInput:_videoInput];
    }

    [_captureSession commitConfiguration];
}

// WARNING: This must be called on the capture queue
- (void)configureSessionWithPreset:(NSString*)sessionPreset {
    [_captureSession beginConfiguration];

    if (!_videoInput) {
        [self configureVideoInputWithDevicePosition:_devicePosition];
    }

    BOOL isPhotoMode = [sessionPreset isEqualToString:AVCaptureSessionPresetPhoto];
    if ([self lockForConfiguration]) {
        self.smoothAutoFocusEnabled = !isPhotoMode;
        [self unlockForConfiguration];
    }

    BOOL requiresAudio = !isPhotoMode && self.audioOutputDelegate;
    if (requiresAudio) {
        if (!_audioInput) {
            assert(!_audioOutput);
            __autoreleasing NSError *error;
            AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
            NSAssert(!error, @"Could not initialize audio input (%@)", error);
            if ([_captureSession canAddInput:_audioInput]) {
                [_captureSession addInput:_audioInput];
            }

            _audioOutput = [AVCaptureAudioDataOutput new];
            dispatch_queue_t audioQueue = dispatch_queue_create("com.instagram.audioQueue", DISPATCH_QUEUE_SERIAL);
            [(id)_audioOutput setSampleBufferDelegate:self queue:audioQueue];
            if ([_captureSession canAddOutput:_audioOutput]) {
                [_captureSession addOutput:_audioOutput];
            }
        }
    } else {
        if (_audioInput) {
            [_captureSession removeInput:_audioInput];
            _audioInput = nil;
        }
        if (_audioOutput) {
            [_captureSession removeOutput:_audioOutput];
            _audioOutput = nil;
        }
    }

    BOOL isPhoto = [sessionPreset isEqualToString:AVCaptureSessionPresetPhoto];
    BOOL videoOutputChanged = !_videoOutput || ([_captureSession.sessionPreset isEqualToString:AVCaptureSessionPresetPhoto] != isPhoto);
    if (videoOutputChanged) {
        if (_videoOutput) {
            [_captureSession removeOutput:_videoOutput];
        }
        if (!isPhoto) {
            _videoOutput = [AVCaptureVideoDataOutput new];
            dispatch_queue_t videoQueue = dispatch_queue_create("com.instagram.videoQueue", DISPATCH_QUEUE_SERIAL);
            [(id)_videoOutput setSampleBufferDelegate:self queue:videoQueue];
        } else {
            _videoOutput = [AVCaptureStillImageOutput new];
        }
        if ([_captureSession canAddOutput:_videoOutput]) {
            [_captureSession addOutput:_videoOutput];
        }
    }
    if (![_captureSession.sessionPreset isEqualToString:sessionPreset]) {
        _captureSession.sessionPreset = sessionPreset;
    }
    [_captureSession commitConfiguration];

}

- (AVCaptureDevice*)videoDeviceForPosition:(AVCaptureDevicePosition)position {
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        // dispatch on the capture queue to prevent session configuration races
        dispatch_sync(_captureQueue, ^{
            _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        });
    }
    return _previewLayer;
}

- (void)startRunning {
    NSString *preset = self.sessionPreset;
    BOOL shouldConfigure = !_isSessionConfigured;
    _isSessionConfigured = YES;

    dispatch_async(_captureQueue, ^{
        if (shouldConfigure) {
            [self configureSessionWithPreset:preset];
        }
        if (![_captureSession isRunning]) {
            [_captureSession startRunning];
        }
    });
}

- (void)stopRunning {
    dispatch_async(_captureQueue, ^{
        if ([_captureSession isRunning]) {
            [_captureSession stopRunning];
        }
    });
}

#pragma mark - Metring

- (BOOL)lockForConfiguration {
    _lockCount++;
    if (_lockCount == 1) {
        _didLock = [self.videoDevice lockForConfiguration:nil];
    }
    return _didLock;
}

- (void)unlockForConfiguration {
    _lockCount--;
    if (_lockCount == 0 && _didLock) {
        [self.videoDevice unlockForConfiguration];
    }
}

- (void)setExposureMode:(AVCaptureExposureMode)exposureMode {
    if ([self.videoDevice isExposureModeSupported:exposureMode]) {
        if ([self lockForConfiguration]) {
            [self.videoDevice setExposureMode:exposureMode];
            [self unlockForConfiguration];
        }
    } else if (exposureMode == AVCaptureExposureModeAutoExpose) {
        [self setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    }
}

- (void)setExposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point {
    if ([self lockForConfiguration]) {
        if ([self.videoDevice isExposurePointOfInterestSupported]) {
            self.videoDevice.exposurePointOfInterest = point;
        }
        self.exposureMode = exposureMode;
        [self unlockForConfiguration];
    }
}

- (AVCaptureExposureMode)exposureMode {
    return self.videoDevice.exposureMode;
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode {
    if ([self.videoDevice isFocusModeSupported:focusMode]) {
        if ([self lockForConfiguration]) {
            [self.videoDevice setFocusMode:focusMode];
            [self unlockForConfiguration];
        }
    } else if (focusMode == AVCaptureFocusModeAutoFocus) {
        [self setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    }
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point {
    if ([self lockForConfiguration]) {
        if ([self.videoDevice isFocusPointOfInterestSupported]) {
            self.videoDevice.focusPointOfInterest = point;
        }
        self.focusMode = focusMode;
        [self unlockForConfiguration];
    }
}

- (AVCaptureFocusMode)focusMode {
    return self.videoDevice.focusMode;
}

- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode {
    if ([self.videoDevice isWhiteBalanceModeSupported:whiteBalanceMode]) {
        if ([self lockForConfiguration]) {
            [self.videoDevice setWhiteBalanceMode:whiteBalanceMode];
            [self unlockForConfiguration];
        }
    } else if (whiteBalanceMode == AVCaptureWhiteBalanceModeAutoWhiteBalance) {
        [self setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
    }
}

- (AVCaptureWhiteBalanceMode)whiteBalanceMode {
    return self.videoDevice.whiteBalanceMode;
}

- (void)resetMetring {
    if ([self lockForConfiguration]) {
        [self setExposureMode:AVCaptureExposureModeContinuousAutoExposure atPoint:CGPointMake(0.5, 0.5)];
        [self setFocusMode:AVCaptureFocusModeContinuousAutoFocus atPoint:CGPointMake(0.5, 0.5)];
        [self setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        [self unlockForConfiguration];
    }
}

- (void)setSmoothAutoFocusEnabled:(BOOL)smoothAutoFocusEnabled {
    if ([self.videoDevice respondsToSelector:@selector(isSmoothAutoFocusSupported)] &&    // iOS 6 compatibility
        [self.videoDevice isSmoothAutoFocusSupported])
    {
        self.videoDevice.smoothAutoFocusEnabled = smoothAutoFocusEnabled;
    }
}

- (BOOL)isSmoothAutoFocusEnabled {
    return ([self.videoDevice respondsToSelector:@selector(isSmoothAutoFocusEnabled)] &&  // iOS 6 compatibility
            [self.videoDevice isSmoothAutoFocusEnabled]);
}

#pragma mark - Image capture

- (void)captureImageWithCompletionHandler:(void (^)(CMSampleBufferRef sampleBuffer, NSError *error))handler {
    AVCaptureStillImageOutput *output = (id)_videoOutput;
    if ([output respondsToSelector:@selector(captureStillImageAsynchronouslyFromConnection:completionHandler:)]) {
        [output captureStillImageAsynchronouslyFromConnection:[output.connections firstObject] completionHandler:handler];
    } else if (handler) {
        handler(NULL, [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorInvalidSourceMedia userInfo:nil]);
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [self.videoOutputDelegate didDropVideoBuffer:sampleBuffer];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    id output = _videoOutput;   // copy atomically here, so that we can check for nil & equality without races
    if (output == nil) {
        return;
    } else if (captureOutput == output) {
        NSDictionary *exif = (__bridge id)CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary, NULL);
        @synchronized(self) {
            _exposureTime = [exif[(id)kCGImagePropertyExifExposureTime] doubleValue];
        }
        [self.videoOutputDelegate didOutputVideoBuffer:sampleBuffer];
    } else {
        [self.audioOutputDelegate didOutputAudioBuffer:sampleBuffer];
    }
}

@end
