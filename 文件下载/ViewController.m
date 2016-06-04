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
        
        // 1. NSURL
        NSURL *url = [NSURL URLWithString:@"http://127.0.0.1/videos.zip"];
        // 2.发送请求
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        //3. 建立连接，发送请求
        [NSURLConnection connectionWithRequest:request delegate:self];
        
        //4. 子线程要手动开启运行循环
        [[NSRunLoop currentRunLoop] run];
        
    });
    
}

- (IBAction)suspend:(id)sender {
 
}

- (IBAction)resume:(id)sender {

}

#pragma mark - 实现代理方法
// 接受服务器的响应,只调用一次
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"----接收服务器的响应----%@",[NSThread currentThread]);
    
    self.expectedContentLength = response.expectedContentLength;
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
