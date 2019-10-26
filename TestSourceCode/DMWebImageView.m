//
//  DMWebImageView.m
//  Dailymotion
//
//  Created by Olivier Poitrey on 18/09/09.
//  Copyright 2009 Dailymotion. All rights reserved.
//

#import "DMWebImageView.h"
#import "DMImageCache.h"

static NSOperationQueue *downloadQueue;
static NSOperationQueue *cacheInQueue;

@implementation DMWebImageView

- (void)dealloc
{
    
    [placeHolderImage release];
    [currentOperation release];
    [super dealloc];
}

#pragma mark RemoteImageView

- (void)setImageWithURL:(NSURL *)url
{
    if (currentOperation != nil)
    {
        [currentOperation cancel]; // remove from queue
        [currentOperation release];
        currentOperation = nil;
    }

    // Save the placeholder image in order to re-apply it when view is reused
    if (placeHolderImage == nil)
    {
        placeHolderImage = [self.image retain];
    }
    else
    {
        self.image = placeHolderImage;
    }

    UIImage *cachedImage = [[DMImageCache sharedImageCache] imageFromKey:[url absoluteString]];

    if (cachedImage)
    {
        self.image = cachedImage;
    }
    else
    {
        if (downloadQueue == nil)
        {
            downloadQueue = [[NSOperationQueue alloc] init];
            [downloadQueue setMaxConcurrentOperationCount:8];
        }
        
        currentOperation = [[DMWebImageDownloadOperation alloc] initWithURL:url delegate:self];
       [downloadQueue addOperation:currentOperation];
    }
}

- (void)downloadFinishedWithImage:(UIImage *)anImage
{
    self.image = anImage;
    [currentOperation release];
    currentOperation = nil;
}

@end

@implementation DMWebImageDownloadOperation

@synthesize url, delegate;

- (void)dealloc
{
    [url release];
    [super dealloc];
}


- (id)initWithURL:(NSURL *)anUrl delegate:(DMWebImageView *)aDelegate
{
    if (self = [super init])
    {
        self.url = anUrl;
        self.delegate = aDelegate;
    }

    return self;
}
//main方法的话，如果main方法执行完毕，那么整个operation就会从队列中被移除
- (void)main
{
    if (self.isCancelled)
    {
        return;
    }
    
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    UIImage *image = [[UIImage alloc] initWithData:data];
    [data release];
    
    if (!self.isCancelled)
    {
        [delegate performSelectorOnMainThread:@selector(downloadFinishedWithImage:) withObject:image waitUntilDone:YES];
    }

    if (cacheInQueue == nil)
    {
        cacheInQueue = [[NSOperationQueue alloc] init];
        [cacheInQueue setMaxConcurrentOperationCount:2];
    }

    NSString *cacheKey = [url absoluteString];

    DMImageCache *imageCache = [DMImageCache sharedImageCache];

    // Store image in memory cache NOW, no need to wait for the cache-in operation queue completion
    [imageCache storeImage:image forKey:cacheKey toDisk:NO];

    // Perform the cache-in in another operation queue in order to not block a download operation slot
    //在另一个操作队列中执行缓存，以避免阻塞下载操作插槽
    
    //创建签名对象的时候不是使用NSMethodSignature这个类创建，而是方法属于谁就用谁来创建
    //    NSMethodSignature*signature = [ViewController instanceMethodSignatureForSelector:@selector(sendMessageWithNumber:WithContent:)];
    //1、创建NSInvocation对象
    NSInvocation *cacheInInvocation = [NSInvocation invocationWithMethodSignature:[[imageCache class] instanceMethodSignatureForSelector:@selector(storeImage:forKey:)]];
    [cacheInInvocation setTarget:imageCache];
    [cacheInInvocation setSelector:@selector(storeImage:forKey:)];
    //注意：
    //1.自定义的参数索引从2开始，0和1已经被self and _cmd占用了
    //2.方法签名中保存的方法名称必须和调用的名称一致
    [cacheInInvocation setArgument:&image atIndex:2];
    [cacheInInvocation setArgument:&cacheKey atIndex:3];
    //retain 所有参数，防止参数被释放dealloc
    [cacheInInvocation retainArguments];
    NSInvocationOperation *cacheInOperation = [[NSInvocationOperation alloc] initWithInvocation:cacheInInvocation];
    [cacheInQueue addOperation:cacheInOperation];
    [cacheInOperation release];
    
    [image release];
}

@end
