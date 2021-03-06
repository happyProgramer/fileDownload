//
//  ViewController.m
//  文件下载
//
//  Created by 宠爱 on 16/6/4.
//  Copyright © 2016年 iscast. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSURLConnectionDataDelegate>

// 要下载的内容长度
@property (nonatomic, assign) long long expectedContentLength;

// 输出流
@property (nonatomic, strong) NSOutputStream *outputStream;

// 已下载的长度
@property (nonatomic, assign) long long hasDownloadContentLength;

// 拿到连接，进行暂停和恢复
@property (nonatomic, strong) NSURLConnection *downloadConnection;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)start:(id)sender {
    // 子线程进行下载
#pragma mark - block中为防止循环应用，定义弱指针
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //0.发送HEAD的请求获取文件的大小
        [self getTotalContentLength];
        
        // 1. NSURL
        NSURL *url = [NSURL URLWithString:@"http://127.0.0.1/videos.zip"];
        // 2.发送请求
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        //3. 建立连接，发送请求
      wself.downloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        //4. 子线程要手动开启运行循环
        [[NSRunLoop currentRunLoop] run];
        
    });
    
}

- (IBAction)suspend:(id)sender {
 
    [self.downloadConnection cancel];
}

- (IBAction)resume:(id)sender {

    // 子线程进行下载
#pragma mark - block中为防止循环应用，定义弱指针
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //0.发送HEAD的请求获取文件的大小
        [self getTotalContentLength];
        
        // 1. NSURL
        NSURL *url = [NSURL URLWithString:@"http://127.0.0.1/videos.zip"];
        // 2.发送请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        // 2.1 设置请求头
        NSString *value = [NSString stringWithFormat:@"bytes=%lld-",self.hasDownloadContentLength];
        
        [request setValue:value forHTTPHeaderField:@"Range"];
        
        //3. 建立连接，发送请求
        wself.downloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        //4. 子线程要手动开启运行循环
        [[NSRunLoop currentRunLoop] run];
        
    });

}


-(void)getTotalContentLength{
    // 1. NSURL
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1/videos.zip"];
    // 2.发送请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    // 2.1 设置请求方式
     request.HTTPMethod = @"HEAD";
    
#pragma mark - HEAD请求只发送请求行和请求头，不包含请求体
    NSURLResponse *response = nil;
    // 3.建立连接，发送请求
   NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
    
    NSLog(@"HEAD----%ld",data.length);
    
    self.expectedContentLength = response.expectedContentLength;
    
    NSLog(@"HEAD 获取文件的大小 --- %lld",self.expectedContentLength);

}

#pragma mark - 实现代理方法
// 接受服务器的响应,只调用一次
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"----接收服务器的响应----%@",[NSThread currentThread]);
    
    // 1. 获取沙盒路径
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    // 1.1 拼接路径
   NSString *filePath = [cachesPath stringByAppendingPathComponent:@"789.zip"];
    
    // 2. 创建管道(拿到输出流)
  self.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:YES];
    // 2.1 开启输出流
    [self.outputStream open];
}

// 每当获取到服务器给我们返回的小数据块的时候,就调用,调用多次
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    //1. 通过输出流，写入沙盒
    [self.outputStream write:data.bytes maxLength:data.length];

   //2. 将每一次获取到的文件的长度,累加起来,方便计算下载的进度
    self.hasDownloadContentLength += data.length;
    
   //3. 计算进度
    float progress = (float)self.hasDownloadContentLength/self.expectedContentLength;
    
    NSLog(@"----%f-----%@",progress,[NSThread currentThread]);

}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"----下载完毕----%@",[NSThread currentThread]);
    
    // 关闭输出流
    [self.outputStream close];

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    // 关闭输出流
    [self.outputStream close];

}
@end
