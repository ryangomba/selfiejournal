// Copyright 2014-present Ryan Gomba. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

@protocol SJCaptureManagerVideoOutputDelegate <NSObject>
@required
// TODO rename
- (void)didDropVideoBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)didOutputVideoBuffer:(CMSampleBufferRef)sampleBuffer;
@end
@protocol SJCaptureManagerAudioOutputDelegate <NSObject>
@required
- (void)didOutputAudioBuffer:(CMSampleBufferRef)sampleBuffer;
@end

@interface SJCaptureManager : NSObject

@property (nonatomic,assign,readonly) AVCaptureDevice *videoDevice;
@property (nonatomic,assign) AVCaptureDevicePosition devicePosition;
@property (nonatomic,strong) NSString *sessionPreset;

@property (nonatomic,strong,readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,weak) id<SJCaptureManagerVideoOutputDelegate> videoOutputDelegate;
@property (nonatomic,weak) id<SJCaptureManagerAudioOutputDelegate> audioOutputDelegate;

- (void)startRunning;
- (void)stopRunning;

#pragma mark - Metering

// Nestable. Wrap multiple metering calls between these for atomic & fast updates
- (BOOL)lockForConfiguration;
- (void)unlockForConfiguration;

@property (nonatomic,assign) AVCaptureExposureMode exposureMode;
- (void)setExposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point;

@property (nonatomic,assign) AVCaptureFocusMode focusMode;
- (void)setFocusMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point;

@property (nonatomic,assign) AVCaptureWhiteBalanceMode whiteBalanceMode;

- (void)resetMetring;

@property (nonatomic,assign,getter=isSmoothAutoFocusEnabled) BOOL smoothAutoFocusEnabled;

#pragma mark - Image capture

- (void)captureImageWithCompletionHandler:(void (^)(CMSampleBufferRef sampleBuffer, NSError *error))handler;

@end
