//
//  ViewController.m
//  JJGPUImage_demo1
//
//  Created by lucy on 2017/10/8.
//  Copyright © 2017年 com.daoKeLegend. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import "THImageMovieWriter.h"
#import "THImageMovie.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

@interface ViewController ()

@property (nonatomic, strong) UILabel *displayLabel;
@property (nonatomic, strong) THImageMovieWriter *movieWriter;
@property (nonatomic, strong) dispatch_group_t recordDispatchGroup;
@property (nonatomic, strong) THImageMovie *imageMovieOne;
@property (nonatomic, strong) THImageMovie *imageMovieTwo;
@property (nonatomic, strong) GPUImageOutput <GPUImageInput> *filter;
@property (nonatomic, strong) GPUImageView *imageView;

@end

@implementation ViewController

#pragma mark - Override Base Function

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupUI];
    
    [self setupConfiguration];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Object Private Function

- (void)setupUI
{
    //展示视图
    GPUImageView *imageView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.view = imageView;
    self.imageView = imageView;
    
    //Label
    self.displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 150, 150)];
    self.displayLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.displayLabel];
}

- (void)setupConfiguration
{
    self.filter = [[GPUImageDissolveBlendFilter alloc] init];
    GPUImageDissolveBlendFilter *filter = (GPUImageDissolveBlendFilter *)self.filter;
    [filter setMix:0.5];
    
    //播放
    NSURL *demoURL1 = [[NSBundle mainBundle] URLForResource:@"abc" withExtension:@"mp4"];
    self.imageMovieOne = [[THImageMovie alloc] initWithURL:demoURL1];
    self.imageMovieOne.runBenchmark = YES;
    self.imageMovieOne.playAtActualSpeed = YES;
    
    NSURL *demoURL2 = [[NSBundle mainBundle] URLForResource:@"def" withExtension:@"mp4"];
    self.imageMovieTwo = [[THImageMovie alloc] initWithURL:demoURL2];
    self.imageMovieTwo.runBenchmark = YES;
    self.imageMovieTwo.playAtActualSpeed = YES;
    
    NSArray *imageMovieArr = @[self.imageMovieOne, self.imageMovieTwo];
    
    //存储路径
    NSString *pathStr = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathStr UTF8String]);
    NSURL *movieURL = [NSURL URLWithString:pathStr];
    
    //写入
    self.movieWriter = [[THImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640, 480) movies:imageMovieArr];
    
    //添加响应链
    [self.imageMovieOne addTarget:filter];
    [self.imageMovieTwo addTarget:filter];
    
    //显示
    [filter addTarget:self.imageView];
    [filter addTarget:self.movieWriter];
    
    [self.imageMovieOne startProcessing];
    [self.imageMovieTwo startProcessing];
    [self.movieWriter startRecording];
    
    //进度显示
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [displayLink setPaused:NO];
    
    //存储
    __weak typeof(self) weakSelf = self;
    [self.movieWriter setCompletionBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        [filter removeTarget:strongSelf.self.movieWriter];
        [strongSelf.imageMovieOne endProcessing];
        [strongSelf.imageMovieTwo endProcessing];
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathStr))
        {
            [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     if (error) {
                         NSLog(@"保存失败");
                     } else {
                         NSLog(@"保存成功");
                     }
                 });
             }];
        }
        else {
            NSLog(@"error mssg)");
        }
    }];
}

- (void)updateProgress
{
    self.displayLabel.text = [NSString stringWithFormat:@"Progress:%d%%", (int)(self.imageMovieOne.progress * 100)];
    [self.displayLabel sizeToFit];
}

@end










































