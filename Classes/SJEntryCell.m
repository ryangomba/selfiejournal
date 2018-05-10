//
//  SJEntryCell.m
//  SelfieJournal
//
//  Created by Ryan Gomba on 5/19/14.
//  Copyright (c) 2014 Ryan Gomba. All rights reserved.
//

#import "SJEntryCell.h"

#import "RGFeedVideoPlayer.h"
#import "SJThumbnailGenerator.h"

@interface SJEntryCell ()

//@property (nonatomic, strong) RGFeedVideoPlayer *player;

@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, weak) NSOperation *thumbnailOperation;

@end


@implementation SJEntryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textLabel.backgroundColor = [UIColor clearColor];
        
//        self.player.playerView.frame = self.contentView.bounds;
//        self.player.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
//        [self.contentView addSubview:self.player.playerView];
        
        self.thumbnailView.frame = self.contentView.bounds;
        [self.contentView addSubview:self.thumbnailView];
    }
    return self;
}

- (UIImageView *)thumbnailView {
    if (!_thumbnailView) {
        _thumbnailView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _thumbnailView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return _thumbnailView;
}

//- (RGFeedVideoPlayer *)player {
//    if (!_player) {
//        _player = [[RGFeedVideoPlayer alloc] init];
//        _player.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//        _player.shouldLoop = YES;
//    }
//    return _player;
//}

- (void)setEntry:(SJEntry *)entry {
    _entry = entry;
    
    [self.thumbnailOperation cancel];
    self.thumbnailView.image = nil;
    
    self.textLabel.text = entry.text;
    
    self.thumbnailOperation =
    [SJThumbnailGenerator generateThumbnailOfSize:640.0 forVideoAtPath:entry.filePath completion:
     ^(UIImage *image) {
         self.thumbnailView.image = image;
    }];
    
//    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:entry.filePath];
//    [self.player loadVideoForURL:videoURL];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    //
}

- (void)play {
//    [self.player playImmediately];
}

- (void)stop {
//    [self.player stop];
}

@end
