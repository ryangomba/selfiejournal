// Copyright 2014-present Ryan Gomba. All rights reserved.

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, RGFeedVideoPlayerState) {
    RGFeedVideoPlayerStateUninitialized,
    RGFeedVideoPlayerStateBuffering,
    RGFeedVideoPlayerStateBufferingAutoPlay,
    RGFeedVideoPlayerStateBuffered,
    RGFeedVideoPlayerStateBufferedAutoPlay,
    RGFeedVideoPlayerStatePaused,
    RGFeedVideoPlayerStateStopped,
    RGFeedVideoPlayerStatePlaying,
    RGFeedVideoPlayerStateError,
    RGFeedVideoPlayerStateEnded,
};

@protocol RGFeedVideoPlayerDelegate;
@protocol RGVideoPlayerViewProtocol <NSObject>

@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, assign, readonly) RGFeedVideoPlayerState state;
@property (nonatomic, strong, readonly) UIView *playerView;

@property (nonatomic, weak) id<RGFeedVideoPlayerDelegate> delegate;

- (void)loadVideoForURL:(NSURL *)URL;

- (void)playWhenReady;
- (void)playImmediately;
- (void)pause;
- (void)stop;
- (void)reset;
- (void)resetPlayer;
- (CGFloat)currentTime;
- (CGFloat)duration;

@end

@protocol RGFeedVideoPlayerDelegate <NSObject>

- (void)videoPlayerReadyToPlay:(id<RGVideoPlayerViewProtocol>)player;
- (void)videoPlayerWillReset:(id<RGVideoPlayerViewProtocol>)player;
- (void)videoPlayerStateDidChange:(id<RGVideoPlayerViewProtocol>)player
                         previous:(RGFeedVideoPlayerState)previous
                          current:(RGFeedVideoPlayerState)current;

@end

@interface RGFeedVideoPlayer : NSObject<RGVideoPlayerViewProtocol>

@property (nonatomic, assign) BOOL audioEnabled;
@property (nonatomic, assign) BOOL shouldLoop;
@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;

@end
