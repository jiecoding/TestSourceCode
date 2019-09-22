//
//  ViewController.m
//  TestSourceCode
//
//  Created by keep on 2019/9/22.
//  Copyright © 2019 keep. All rights reserved.
//

#import "ViewController.h"
#import "DMWebImageView.h"
//#import <SDWebImage/SDWebImage.h>
@interface ViewController ()

/**
 自己使用的图片视图控件
 */
@property (weak, nonatomic) IBOutlet UIImageView *myImageView;

/**
 第三方加载图片使用的图片视图控件
 */
@property (weak, nonatomic) IBOutlet DMWebImageView *testImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //1.获取图片url链接
    NSURL *imageUrl = [NSURL URLWithString:@"http://n.sinaimg.cn/edu/transform/20160505/pe7k-fxryhhu2274915.png"];
    //2.从url图片链接里获取内容放到Data二进制数据里
    NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
    //3.图片直接加载data二进制数据来获取展示图片
    self.myImageView.image = [UIImage imageWithData:imageData];
    
    
    
    [self.testImageView setImageWithURL:[NSURL URLWithString:@"http://n.sinaimg.cn/edu/transform/20160505/pe7k-fxryhhu2274915.png"]];
    
    
}


@end
