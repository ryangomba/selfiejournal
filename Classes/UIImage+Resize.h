// Copyright 2014-present Ryan Gomba. All rights reserved.

@interface UIImage (Resize)

// Returns a cropped CGImage
- (CGImageRef)newCGImageWithCropRect:(CGRect)cropRect;

// Pads image to requested size
- (UIImage*)paddedImageOfSize:(CGSize)size;

// Returns a cropped UIImage
- (UIImage *)croppedImage:(CGRect)bounds;

// Returns an auto-cropped square UIImage
- (UIImage *)squareThumbnailImageOfSize:(NSInteger)thumbnailSize;

// Returns a resizeable image, where the center pixel is tiled
- (UIImage *)resizableImageWithCenterInsets;

// Returns an image with the original aspect ratio that is at least as large as the passed in bounds.
- (UIImage *)resizedImageWithBounds:(CGSize)bounds;

@end
