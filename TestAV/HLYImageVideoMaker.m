//
//  HLYImageVideoMaker.m
//  TestAV
//
//  Created by huangluyang on 14-7-27.
//  Copyright (c) 2014年 huangluyang. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "HLYImageVideoMaker.h"

@implementation HLYImageVideoMaker

#pragma mark -
#pragma mark - public
+ (void)writeImage:(UIImage *)image
           withFps:(NSInteger)fps
          duration:(NSInteger)duration
         startRect:(CGRect)startRect
           endRect:(CGRect)endRect
           toVideo:(NSString *)videoPath
          withSize:(CGSize)size
          complete:(void (^)(NSString *path))complete
{
    if (!videoPath || !image || !videoPath) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                      [NSURL fileURLWithPath:videoPath] fileType:AVFileTypeQuickTimeMovie
                                                                  error:&error];
        NSParameterAssert(videoWriter);
        
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecH264, AVVideoCodecKey,
                                       [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                       [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                       nil];
        AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                           assetWriterInputWithMediaType:AVMediaTypeVideo
                                           outputSettings:videoSettings]; //retain should be removed if ARC
        
        NSParameterAssert(writerInput);
        NSParameterAssert([videoWriter canAddInput:writerInput]);
        [videoWriter addInput:writerInput];
        
        AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
        
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero]; //use kCMTimeZero if unsure
        
        CVPixelBufferRef buffer = NULL;
        
        //convert uiimage to CGImage.
        
        //frame per second
        NSInteger frameDuration = fps * duration;
        
        // 防花屏，必须调整尺寸
        //    UIImage *scaledImage = [self scaleImage:image size:CGSizeMake(320, 240)];
        CGFloat xCell = (endRect.origin.x - startRect.origin.x) / frameDuration;
        CGFloat yCell = (endRect.origin.y - startRect.origin.y) / frameDuration;
        CGFloat widthCell = (endRect.size.width - startRect.size.width) / frameDuration;
        CGFloat heightCell = (endRect.size.height - startRect.size.height) / frameDuration;
        
        for(int i = 0; i< frameDuration; i++)
        {
            
            buffer = [self newPixelBufferFromCGImage:[image CGImage] withFrame:CGRectMake(xCell * i + startRect.origin.x, yCell * i + startRect.origin.y, widthCell * i + startRect.size.width, heightCell * i + startRect.size.height)];
            CMTime frameTime = CMTimeMake(i, (int32_t)fps);
            [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
            [NSThread sleepForTimeInterval:0.05];
        }
        
        //    [writerInput markAsFinished];
        //    [videoWriter finishWriting]; //deprecated in ios6
        
        [videoWriter finishWritingWithCompletionHandler:^{
            NSLog(@"status --> %d", (int)videoWriter.status);
            if (complete) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    complete(videoPath);
                });
            }
            
        }]; //ios 6.0+
    });
}

#pragma mark -
#pragma mark - private
+ (void)drawFrameInContext:(CGContextRef)context rect:(CGRect)rect image:(CGImageRef)image
{
    [NSException raise:NSInternalInconsistencyException format:@"抽象方法 %s 必须重写", __FUNCTION__];
}

+ (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image withFrame:(CGRect)frame
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CGSize frameSize = CGSizeMake(640, 480);
    UIImage *presentImage = [self scaleImage:[self cropImage:image toRect:frame] size:frameSize];
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    // iOS中坐标系需要进行翻转
    CGContextConcatCTM(context, CGAffineTransformMake(1,0,0,-1,0,frameSize.height));
    
    CGContextDrawImage(context, CGRectMake(0, 0, frameSize.width, frameSize.height), presentImage.CGImage);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (UIImage *)scaleImage:(UIImage *)image size:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image.CGImage);
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

+ (UIImage *)cropImage:(CGImageRef)image toRect:(CGRect)rect

{
    
    //create a context to do our clipping in
    
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    
    
    //create a rect with the size we want to crop the image to
    
    //the X and Y here are zero so we start at the beginning of our
    
    //newly created context
    
    CGRect clippedRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
    
    CGContextClipToRect( currentContext, clippedRect);
    
    
    
    //create a rect equivalent to the full size of the image
    
    //offset the rect by the X and Y we want to start the crop
    
    //from in order to cut off anything before them
    
    CGRect drawRect = CGRectMake(rect.origin.x * -1,
                                 
                                 rect.origin.y * -1,
                                 
                                 CGImageGetWidth(image),
                                 
                                 CGImageGetHeight(image));
    
    
    
    //draw the image to our clipped context using our offset rect
    
    CGContextTranslateCTM(currentContext, 0.0, rect.size.height);
    
    CGContextScaleCTM(currentContext, 1.0, -1.0);
    
    CGContextDrawImage(currentContext, drawRect, image);
    
    
    
    //pull the image from our cropped context
    
    UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
    
    
    
    //pop the context to get back to the default
    
    UIGraphicsEndImageContext();
    
    
    
    //Note: this is autoreleased
    
    return cropped;
    
}

@end
