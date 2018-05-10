//
//  SJCameraViewController.h
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/19/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SJCameraViewController;
@protocol SJCameraViewControllerDelegate <NSObject>

- (void)cameraViewControllerWantsDismissal:(SJCameraViewController *)viewController;
- (void)cameraViewController:(SJCameraViewController *)viewController
       didCaptureVideoAtPath:(NSString *)videoPath;

@end

@interface SJCameraViewController : UIViewController

@property (nonatomic, weak) id<SJCameraViewControllerDelegate> delegate;

@end
