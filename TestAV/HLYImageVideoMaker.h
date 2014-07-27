//
//  HLYImageVideoMaker.h
//  TestAV
//
//  Created by huangluyang on 14-7-27.
//  Copyright (c) 2014年 huangluyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLYImageVideoMaker : NSObject

+ (void)writeImage:(UIImage *)image
           withFps:(NSInteger)fps
          duration:(NSInteger)duration
         startRect:(CGRect)startRect
           endRect:(CGRect)endRect
           toVideo:(NSString *)videoPath
          withSize:(CGSize)size
          complete:(void (^)(NSString *path))complete;

@end
