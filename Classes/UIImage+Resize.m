// Copyright 2014-present Ryan Gomba. All rights reserved.

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

#pragma mark -
#pragma mark Public Methods

- (CGImageRef)newCGImageWithCropRect:(CGRect)cropRect {
    CGRect finalCropRect = [self cropRectForOrientation:cropRect];
    CGImageRef croppedImage = CGImageCreateWithImageInRect(self.CGImage, finalCropRect);
    return croppedImage;
}

- (UIImage *)croppedImage:(CGRect)cropRect {
    CGImageRef croppedImageRef = [self newCGImageWithCropRect:cropRect];
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef scale:1.0f orientation:self.imageOrientation];
    CGImageRelease(croppedImageRef);
    return croppedImage;
}

- (UIImage*)paddedImageOfSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self drawAtPoint:CGPointMake((size.width - self.size.width) / 2, (size.height - self.size.height) / 2)];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)squareThumbnailImageOfSize:(NSInteger)thumbnailSize {
    UIImage *resizedImage = [self resizedImageWithBounds:CGSizeMake(thumbnailSize, thumbnailSize)];
    CGRect cropRect = CGRectMake(round((resizedImage.size.width - thumbnailSize) / 2),
                                 round((resizedImage.size.height - thumbnailSize) / 2),
                                 thumbnailSize,
                                 thumbnailSize);
    UIImage *croppedImage = [resizedImage croppedImage:cropRect];
    return croppedImage;
}

- (UIImage *)resizedImageWithBounds:(CGSize)bounds {
    CGFloat horizontalRatio = bounds.width / self.size.width;
    CGFloat verticalRatio = bounds.height / self.size.height;
    CGFloat ratio = MAX(horizontalRatio, verticalRatio);
    CGSize newSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
    return [self resizedImageWithSize:newSize];
}


#pragma mark -
#pragma mark Private Methods

- (UIImage *)resizedImageWithSize:(CGSize)newSize {
    CGAffineTransform transform = [self transformForOrientation:newSize];

    BOOL drawTransposed;
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;
        default:
            drawTransposed = NO;
            break;
    }

    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    CGImageRef imageRef = self.CGImage;

    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                CGImageGetColorSpace(imageRef),
                                                kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    NSCAssert(bitmap, @"Bitmap context is NULL");

    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationMedium);

    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, drawTransposed ? transposedRect : newRect, imageRef);

    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];

    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);

    return newImage;
}

- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (self.imageOrientation) {
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;

        default:
            break;
    }

    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }

    return transform;
}

- (CGRect)cropRectForOrientation:(CGRect)cropRect {
    CGRect finalCropRect = CGRectZero;

    switch (self.imageOrientation) {
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            finalCropRect.origin.x = cropRect.origin.y;
            finalCropRect.origin.y = self.size.width - CGRectGetMaxX(cropRect);
            finalCropRect.size.width = cropRect.size.height;
            finalCropRect.size.height = cropRect.size.width;
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            finalCropRect.origin.x = self.size.height - CGRectGetMaxY(cropRect);
            finalCropRect.origin.y = cropRect.origin.x;
            finalCropRect.size.width = cropRect.size.height;
            finalCropRect.size.height = cropRect.size.width;
            break;

        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            finalCropRect.origin.x = self.size.width - CGRectGetMaxX(cropRect);
            finalCropRect.origin.y = self.size.height - CGRectGetMaxY(cropRect);
            finalCropRect.size.width = cropRect.size.width;
            finalCropRect.size.height = cropRect.size.height;
            break;

        default:
            finalCropRect = cropRect;
            break;
    }

    return CGRectIntegral(finalCropRect);
}

- (UIImage *)resizableImageWithCenterInsets {
    CGSize size = [self size];
    size.width  *= 0.5f;
    size.height *= 0.5f;
    return [self resizableImageWithCapInsets:UIEdgeInsetsMake(size.height, size.width, size.height, size.width)];
}

@end
