//
//  SJCameraViewController.m
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/19/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJCameraViewController.h"

#import "SJCaptureManager.h"
#import "SJVideoRecorder.h"

#define kCaptureButtonSize 60.0

@interface SJCameraViewController ()<SJCaptureManagerVideoOutputDelegate, SJCaptureManagerAudioOutputDelegate>

@property (nonatomic, strong) SJCaptureManager *captureManager;
@property (nonatomic, strong) SJVideoRecorder *videoRecorder;

@property (nonatomic, strong) UIButton *dismissButton;
@property (nonatomic, strong) UIButton *captureButton;

@end


@implementation SJCameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        //
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.captureManager.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.captureManager.previewLayer];
    
    self.dismissButton.center = CGPointMake(100.0, 50.0);
    [self.view addSubview:self.dismissButton];
    
    self.captureButton.center = CGPointMake(160.0, 480.0);
    [self.view addSubview:self.captureButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.captureManager startRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.captureManager stopRunning];
}

- (SJCaptureManager *)captureManager {
    if (!_captureManager) {
        _captureManager = [[SJCaptureManager alloc] init];
        _captureManager.devicePosition = AVCaptureDevicePositionFront;
        _captureManager.videoOutputDelegate = self;
        _captureManager.audioOutputDelegate = self;
    }
    return _captureManager;
}

- (UIButton *)dismissButton {
    if (!_dismissButton) {
        _dismissButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_dismissButton setTitle:@"Dismiss" forState:UIControlStateNormal];
        [_dismissButton addTarget:self
                           action:@selector(onDismissButtonTapped)
                 forControlEvents:UIControlEventTouchUpInside];
        
        [_dismissButton sizeToFit];
    }
    return _dismissButton;
}

- (UIButton *)captureButton {
    if (!_captureButton) {
        CGRect captureButtonRect = CGRectMake(0.0, 0.0, kCaptureButtonSize, kCaptureButtonSize);
        _captureButton = [[UIButton alloc] initWithFrame:captureButtonRect];
        _captureButton.backgroundColor = [UIColor redColor];
        [_captureButton addTarget:self
                           action:@selector(onCaptureButtonBeganPress)
                 forControlEvents:UIControlEventTouchDown];
        [_captureButton addTarget:self
                           action:@selector(onCaptureButtonEndedPress)
                 forControlEvents:UIControlEventTouchUpInside];
        [_captureButton addTarget:self
                           action:@selector(onCaptureButtonCanceledPress)
                 forControlEvents:UIControlEventTouchUpOutside];
        [_captureButton addTarget:self
                           action:@selector(onCaptureButtonCanceledPress)
                 forControlEvents:UIControlEventTouchCancel];
    }
    return _captureButton;
}

- (void)didDropVideoBuffer:(CMSampleBufferRef)sampleBuffer {
    NSLog(@"Dropped video frame"); // TODO make optional?
}

- (SJVideoRecorder *)videoRecorder {
    if (!_videoRecorder) {
        NSString *filePath = [self newOutputFilePath];
        _videoRecorder = [[SJVideoRecorder alloc] initWithFilePath:filePath];
    }
    return _videoRecorder;
}

- (void)didOutputVideoBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.videoRecorder appendVideoSampleBuffer:sampleBuffer];
}

- (void)didOutputAudioBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.videoRecorder appendAudioSampleBuffer:sampleBuffer];
}

- (void)onDismissButtonTapped {
    [self.delegate cameraViewControllerWantsDismissal:self];
}

- (NSString *)newOutputFilePath {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *filename = [NSString stringWithFormat:@"%@.mov", uuid];
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    return outputPath;
}

- (void)onCaptureButtonBeganPress {
    CGAffineTransform transform = [SJVideoRecorder transformForInterfaceOrientation:self.interfaceOrientation
                                                                     devicePosition:self.captureManager.devicePosition];
    
    NSError *error = nil;
    BOOL startWritingSuccess =
    [self.videoRecorder startWritingWithTransform:transform error:&error];
    NSAssert(startWritingSuccess, error.localizedDescription);
}

- (void)onCaptureButtonEndedPress {
    [self.videoRecorder finishWritingWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate cameraViewController:self didCaptureVideoAtPath:self.videoRecorder.filePath];
            [[NSFileManager defaultManager] removeItemAtPath:self.videoRecorder.filePath error:nil];
            self.videoRecorder = nil;
        });
    }];
}

- (void)onCaptureButtonCanceledPress {
    [self.videoRecorder finishWritingWithCompletionHandler:^{
        [[NSFileManager defaultManager] removeItemAtPath:self.videoRecorder.filePath error:nil];
        self.videoRecorder = nil;
    }];
}

@end
