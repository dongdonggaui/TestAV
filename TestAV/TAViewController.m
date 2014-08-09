//
//  TAViewController.m
//  TestAV
//
//  Created by huangluyang on 14-7-26.
//  Copyright (c) 2014年 huangluyang. All rights reserved.
//

#import "TAViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HLYImageVideoMaker.h"
#import "HLYVideoPlayView.h"

@interface TAViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet HLYVideoPlayView *videoView;
@property (weak, nonatomic) IBOutlet UIButton *pickerButton;
@property (weak, nonatomic) IBOutlet UILabel *pathLabel;
@property (weak, nonatomic) IBOutlet UILabel *cacheLabel;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;

@property (nonatomic, strong) NSString *videoPath;
@property (nonatomic, strong) UIImage *pickerdImage;

@end

@implementation TAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playButton.enabled = NO;
    self.button.enabled = NO;
    [self.button addTarget:self action:@selector(convertButtonDidTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton addTarget:self action:@selector(playeButtonDidTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.pickerButton addTarget:self action:@selector(pickerButtonDidTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.clearButton addTarget:self action:@selector(clearButtonDidTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self scanCache];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark - private
- (void)convertButtonDidTapped:(UIButton *)sender
{
    [self.textField resignFirstResponder];
    
    if (self.textField.text.length == 0) {
        return;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths lastObject];
    NSString *imageCache = [cachesDirectory stringByAppendingPathComponent:@"HWDImageCache"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imageCache]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:imageCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    imageCache = [imageCache stringByAppendingString:[NSString stringWithFormat:@"/%@.mp4", self.textField.text]];
    NSLog(@"path --> %@", imageCache);
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"JPG"];
    
    __weak TAViewController *safeSelf = self;
    [HLYImageVideoMaker writeImage:self.pickerdImage withFps:30 duration:5 startRect:CGRectMake(0, 0, 560, 420) endRect:CGRectMake(20, 460, 560, 420) toVideo:imageCache withSize:CGSizeMake(640, 480) complete:^(NSString *path) {
        safeSelf.playButton.enabled = YES;
        safeSelf.videoPath = path;
        [safeSelf scanCache];
    }];
}

- (void)playeButtonDidTapped:(UIButton *)sender
{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:self.videoPath];
    NSLog(@"url --> %@", url);
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
    [self.videoView setPlayer:player];
    
    [self.videoView.player play];
}

- (void)pickerButtonDidTapped:(UIButton *)sender
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.delegate = self;
    [self presentViewController:ipc animated:YES completion:nil];
}

- (void)clearButtonDidTapped:(UIButton *)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"清除缓存？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alert show];
}

- (void)scanCache
{
    float cacheSize = [self folderSizeAtPath:[self cachePath]];
    self.cacheLabel.text = [NSString stringWithFormat:@"缓存大小：%.2f M", cacheSize];
}

- (void)clearCache
{
    NSError *error = nil;
    NSFileManager* manager = [NSFileManager defaultManager];
    NSArray *allFiles = [manager contentsOfDirectoryAtPath:[self cachePath] error:&error];
    if (error) {
        NSLog(@"get contents error --> %@", error);
        return;
    }
    
    for (NSString *file in allFiles) {
        NSLog(@"file path --> %@", file);
        [manager removeItemAtPath:[[self cachePath] stringByAppendingPathComponent:file] error:&error];
        if (error) {
            NSLog(@"remove item error --> %@", error);
            return;
        }
    }
    
    [self scanCache];
}

- (float )folderSizeAtPath:(NSString*) folderPath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/(1024.0*1024.0);
}

//单个文件的大小
- (long long)fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

- (NSString *)cachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths lastObject];
    NSString *imageCache = [cachesDirectory stringByAppendingPathComponent:@"HWDImageCache"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imageCache]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:imageCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return imageCache;
}

- (void)testImageCompressAndScaleWithImage:(UIImage *)image
{
    // 原始图片尺寸
    NSLog(@"image size --> %@", NSStringFromCGSize(image.size));
    
    NSData *originData = UIImageJPEGRepresentation(image, 1);
    
    // 压缩图片
    NSData *imageData = UIImageJPEGRepresentation(image, 0.01);
    
    // 获取压缩图片
    UIImage *compressedImage = [[UIImage alloc] initWithData:imageData];
    
    NSLog(@"compressed image size --> %@", NSStringFromCGSize(compressedImage.size));
    NSLog(@"image data size --> %u, before --> %u", imageData.length, originData.length);
    
    // 缩放图片
    UIImage *scaledImage = [[UIImage alloc] initWithData:imageData scale:2];
    NSLog(@"scaled image size --> %@", NSStringFromCGSize(scaledImage.size));
}

#pragma mark -
#pragma mark - ipc delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
//    [self testImageCompressAndScaleWithImage:image];
//    return;
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.01);
    self.pickerdImage = [[UIImage alloc] initWithData:imageData];
    NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
    if (url) {
        self.pathLabel.text = url.absoluteString;
    }
    self.button.enabled = self.pickerdImage != nil;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark - alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self clearCache];
    }
}

@end
