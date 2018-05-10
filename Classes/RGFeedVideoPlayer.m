// Copyright 2014-present Ryan Gomba. All rights reserved.

#import "RGFeedVideoPlayer.h"

#import "RGMacros.h"

@interface RGFeedVideoPlayerView : UIView

@property (nonatomic, strong) CALayer *playerLayer;

@end

@implementation RGFeedVideoPlayerView

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.playerLayer setFrame:self.bounds];
}

- (void)setPlayerLayer:(CALayer *)playerLayer {
    if (_playerLayer != playerLayer) {
        [_playerLayer removeFromSuperlayer];
        [self.layer addSublayer:playerLayer];
        _playerLayer = playerLayer;
    }
}

@end


NSString * const kPlayerItemStatusKey = @"status";
NSString * const kPlayerItemPlaybackLikelyToKeepUpKey = @"playbackLikelyToKeepUp";
NSString * const kPlayerItemPlaybackBufferEmptyKey = @"playbackBufferEmpty";
NSString * const kPlayerItemPlaybackBufferFullKey = @"playbackBufferFull";
NSString * const kPlayerRateKey = @"rate";

static void *RGVideoPlayerItemStatusObservationContext = &RGVideoPlayerItemStatusObservationContext;
static void *RGVideoPlayerItemPlaybackLikelyToKeepUpContext = &RGVideoPlayerItemPlaybackLikelyToKeepUpContext;
static void *RGVideoPlayerItemPlaybackBufferEmptyContext = &RGVideoPlayerItemPlaybackBufferEmptyContext;
static void *RGVideoPlayerItemPlaybackBufferFullContext = &RGVideoPlayerItemPlaybackBufferFullContext;
static void *RGVideoPlayerRateContext = &RGVideoPlayerRateContext;


@interface RGFeedVideoPlayer ()

@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, strong, readwrite) RGFeedVideoPlayerView *playerView;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong, readwrite) AVPlayerLayer *playerLayer;

@property (nonatomic, assign) BOOL playerDidPlayFirstFrame;
@property (nonatomic, strong) id startTimeObserver;

@end


@implementation RGFeedVideoPlayer

@synthesize state = _state;
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    AVPlayerItem *currentPlayerItem = _player.currentItem;
    if (currentPlayerItem) {
        [currentPlayerItem removeObserver:self forKeyPath:kPlayerItemStatusKey];
        [currentPlayerItem removeObserver:self forKeyPath:kPlayerItemPlaybackLikelyToKeepUpKey];
        [currentPlayerItem removeObserver:self forKeyPath:kPlayerItemPlaybackBufferEmptyKey];
        [currentPlayerItem removeObserver:self forKeyPath:kPlayerItemPlaybackBufferFullKey];
    }
}

- (id)init {
    if (self = [super init]) {
        _playerLayer = [[AVPlayerLayer alloc] init];
    }
    return self;
}


#pragma mark -
#pragma mark Public

- (void)loadVideoForURL:(NSURL *)URL {
#if TARGET_IPHONE_SIMULATOR
    // prevent crashing from playing a video in simulator
    // FIXME later we should fix the real cause
    return;
#endif
    if (!URL) {
        [self setState:RGFeedVideoPlayerStateError];
        return;
    }

    [self setURL:URL];

    [self prepareToPlayURL:URL];

    [self setState:RGFeedVideoPlayerStateBuffering];
}

- (RGFeedVideoPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [[RGFeedVideoPlayerView alloc] initWithFrame:self.playerLayer.bounds];
        [_playerView setPlayerLayer:self.playerLayer];
    }
    return _playerView;
}


#pragma mark -
#pragma mark Properties

- (void)setAudioEnabled:(BOOL)audioEnabled {
    if (_player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        [self setPlaybackAudio:audioEnabled];
    }

    _audioEnabled = audioEnabled;
}

- (void)setPlaybackAudio:(BOOL)withAudio {
    // TODO
//    CGFloat maxVolume = withAudio ? 1.f : 0.f;
//    AVAudioMixInputParameters *mixParams = [_player.currentItem.asset audioFadeInOutWithRampDuration:kIGAudioVolumeRampDuration
//                                                                                           maxVolume:maxVolume];
//    if (mixParams) {
//        AVMutableAudioMix *audioMix = [AVMutableAudioMix new];
//        audioMix.inputParameters = @[mixParams];
//        [_player.currentItem setAudioMix:audioMix];
//    }
}


#pragma mark -
#pragma mark Playback

- (void)playWhenReady {
    switch (_state) {
        case RGFeedVideoPlayerStateBuffering:
            [self setState:RGFeedVideoPlayerStateBufferingAutoPlay];
            break;
        case RGFeedVideoPlayerStateBufferedAutoPlay:
        case RGFeedVideoPlayerStateBuffered:
        case RGFeedVideoPlayerStatePaused:
        case RGFeedVideoPlayerStateStopped:
            [_player play];
            break;
        default:
            return;
    }
}

- (void)playImmediately {
    [_player play];
}

- (void)pause {
    if (_state == RGFeedVideoPlayerStatePlaying) {
        [_player pause];
        [self setState:RGFeedVideoPlayerStatePaused];

    } else if (_state == RGFeedVideoPlayerStateBufferingAutoPlay) {
        [self setState:RGFeedVideoPlayerStateBuffering];
    }
}

- (void)stop {
    [_player pause];

    [self setState:RGFeedVideoPlayerStateStopped];
}

- (void)reset {
    [_player pause];

    [self setState:RGFeedVideoPlayerStateUninitialized];
    [_delegate videoPlayerWillReset:self];

    [self.playerView removeFromSuperview];

    _URL = nil;
    _delegate = nil;
}

- (void)resetPlayer {
    [_player pause];

    [self setState:RGFeedVideoPlayerStateUninitialized];
    [_delegate videoPlayerWillReset:self];

    [self.playerView removeFromSuperview];
    [_playerLayer setPlayer:nil];

    _URL = nil;
    _delegate = nil;

    if (_player) {
        [_player removeObserver:self forKeyPath:kPlayerRateKey];
        [_player removeTimeObserver:_startTimeObserver];
        _player = nil;
    }
}

- (CGFloat)currentTime {
    return CMTimeGetSeconds(_player.currentItem.currentTime);
}

- (CGFloat)duration {
    return CMTimeGetSeconds(_player.currentItem.duration);
}


#pragma mark -
#pragma mark Player Events

- (void)playerRateChange:(float)rate {
    if (rate == 1.0f) {
        if (_playerDidPlayFirstFrame) {
            [self setState:RGFeedVideoPlayerStatePlaying];
        }
    }
}


#pragma mark -
#pragma mark PlayerItem Events

- (void)playbackLikelyToKeepUp:(BOOL)likelyToKeepUp {
    if (likelyToKeepUp) {
        if (_state == RGFeedVideoPlayerStateBufferingAutoPlay) {
            [self setState:RGFeedVideoPlayerStateBufferedAutoPlay];
            [_player play];
        } else if (_state == RGFeedVideoPlayerStateBuffering) {
            [self setState:RGFeedVideoPlayerStateBuffered];
        }
    }
}

- (void)playbackBufferEmpty:(BOOL)bufferEmpty {
    if (bufferEmpty && _state == RGFeedVideoPlayerStatePlaying) {
        [self setState:RGFeedVideoPlayerStateBufferingAutoPlay];
    }
}

- (void)playbackBufferFull:(BOOL)bufferFull {
    if (bufferFull) {
        [_player play];
    }
}

- (void)playerReadyToPlay {
    [self setPlaybackAudio:_audioEnabled];

    [self.delegate videoPlayerReadyToPlay:self];
}

- (void)playerItemDidPlayToEnd {
    [self setState:RGFeedVideoPlayerStateEnded];
    
    if (self.shouldLoop) {
        [self.player seekToTime:kCMTimeZero];
        [self playImmediately];
    }
}

- (void)assetFailedToPrepareForPlayback:(NSError *)error {
    NSLog(@"Playback error: %@", error);

    [self setState:RGFeedVideoPlayerStateError];

    if (error.code == AVErrorMediaServicesWereReset) {
        [self resetPlayer];
    }
}


#pragma mark -
#pragma mark Playback States

- (void)setState:(RGFeedVideoPlayerState)state {
    if (state == _state) {
        return;
    }

    RGFeedVideoPlayerState previousState = _state;
    _state = state;
    [self.delegate videoPlayerStateDidChange:self previous:previousState current:_state];
}


#pragma mark -
#pragma mark VideoPlayer Initialization

- (void)prepareToPlayURL:(NSURL *)url {
    AVPlayerItem *currentPlayerItem = _player.currentItem;
    if (currentPlayerItem) {
        [currentPlayerItem removeObserver:self forKeyPath:kPlayerItemStatusKey];
        [currentPlayerItem removeObserver:self forKeyPath:kPlayerItemPlaybackLikelyToKeepUpKey];
        [currentPlayerItem removeObserver:self forKeyPath:kPlayerItemPlaybackBufferEmptyKey];
        [currentPlayerItem removeObserver:self forKeyPath:kPlayerItemPlaybackBufferFullKey];

        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:currentPlayerItem];
    }

    AVPlayerItem *newPlayerItem = [AVPlayerItem playerItemWithURL:url];

    [newPlayerItem addObserver:self
                    forKeyPath:kPlayerItemStatusKey
                       options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                       context:RGVideoPlayerItemStatusObservationContext];

    [newPlayerItem addObserver:self
                    forKeyPath:kPlayerItemPlaybackLikelyToKeepUpKey
                       options:NSKeyValueObservingOptionNew
                       context:RGVideoPlayerItemPlaybackLikelyToKeepUpContext];

    [newPlayerItem addObserver:self
                    forKeyPath:kPlayerItemPlaybackBufferEmptyKey
                       options:NSKeyValueObservingOptionNew
                       context:RGVideoPlayerItemPlaybackBufferEmptyContext];

    [newPlayerItem addObserver:self
                    forKeyPath:kPlayerItemPlaybackBufferFullKey
                       options:NSKeyValueObservingOptionNew
                       context:RGVideoPlayerItemPlaybackBufferFullContext];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidPlayToEnd)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:newPlayerItem];

    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:newPlayerItem];
        [_playerLayer setPlayer:_player];

        [_player addObserver:self
                  forKeyPath:kPlayerRateKey
                     options:NSKeyValueObservingOptionNew
                     context:RGVideoPlayerRateContext];

        // Sometimes video content has not rendered on PlayerLayer when player already start playing. So, use
        // player playing first frame as a proxy of detecting PlayerLayer did render video content.
        weakify(self);
        CMTime startTime = CMTimeMake(1, 30);
        NSValue *startTimeValue = [NSValue valueWithCMTime:startTime];
        _startTimeObserver = [_player addBoundaryTimeObserverForTimes:@[startTimeValue]
                                                                queue:dispatch_get_main_queue()
                                                           usingBlock:^{
            strongify(self);
            if (self) {
                [self setPlayerDidPlayFirstFrame:YES];
                [self setState:RGFeedVideoPlayerStatePlaying];
            }
        }];
    }

    if (_player.currentItem != newPlayerItem) {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur*/
        [_player replaceCurrentItemWithPlayerItem:newPlayerItem];
        _playerDidPlayFirstFrame = NO;
    }
}

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
    if (context == RGVideoPlayerItemStatusObservationContext) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusUnknown:
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */

                break;
            case AVPlayerStatusReadyToPlay:
                [self playerReadyToPlay];

                break;
            case AVPlayerStatusFailed: {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
        }
    } else if (context == RGVideoPlayerItemPlaybackBufferEmptyContext) {
        [self playbackBufferEmpty:[[change objectForKey:NSKeyValueChangeNewKey] boolValue]];
    } else if (context == RGVideoPlayerItemPlaybackBufferFullContext) {
        [self playbackBufferFull:[[change objectForKey:NSKeyValueChangeNewKey] boolValue]];
    } else if (context == RGVideoPlayerItemPlaybackLikelyToKeepUpContext) {
        [self playbackLikelyToKeepUp:[[change objectForKey:NSKeyValueChangeNewKey] boolValue]];
    } else if (context == RGVideoPlayerRateContext) {
        [self playerRateChange:[[change objectForKey:NSKeyValueChangeNewKey] floatValue]];
    } else {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

@end
