//
//  CCglCameraViewController.m
//  CCCamera
//
//  Created by wsk on 16/8/29.
//  Copyright © 2016年 cyd. All rights reserved.
//

#import "CCglCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>

@interface CCglCameraViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession  *_captureSession;
}
@property(nonatomic, strong) GLKView   *glview;
@property(nonatomic, strong) CIContext *cicontext;

@end

@implementation CCglCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 上下文和预览视图
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *glView = [[GLKView alloc]initWithFrame:self.view.bounds context:context];
    [EAGLContext setCurrentContext:context];
    [self.view addSubview:glView];
    glView.transform = CGAffineTransformMakeRotation(M_PI_2);
    glView.frame = [UIApplication sharedApplication].keyWindow.bounds;
    _cicontext = [CIContext contextWithEAGLContext:context];
    _glview = glView;
    
    // 捕捉会话
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    [session setSessionPreset:AVCaptureSessionPreset1920x1080];
    _captureSession = session;
    
    // 输入
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    if (videoInput) {
        if ([_captureSession canAddInput:videoInput]){
            [_captureSession addInput:videoInput];
        }
    }
    
    // 输出
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
    [videoOut setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [videoOut setSampleBufferDelegate:self queue:dispatch_queue_create("video.buffer", DISPATCH_QUEUE_SERIAL)];
    if ([_captureSession canAddOutput:videoOut]){
        [_captureSession addOutput:videoOut];
    }
    if (!_captureSession.isRunning){
        [_captureSession startRunning];
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (_glview.context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:_glview.context];
    }
    CVImageBufferRef imageRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVImageBuffer:imageRef];
    [_glview bindDrawable];
    [_cicontext drawImage:image inRect:image.extent fromRect:image.extent];
    [_glview display];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
