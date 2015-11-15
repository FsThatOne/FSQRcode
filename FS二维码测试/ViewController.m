//
//  ViewController.m
//  FS二维码测试
//
//  Created by FS小一 on 15/11/15.
//  Copyright © 2015年 FSxiaoyi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITabBarDelegate,AVCaptureMetadataOutputObjectsDelegate>
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstrain;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstrain;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureDeviceInput *inputDevice;
@property (nonatomic,strong) AVCaptureMetadataOutput *outputData;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,strong) CALayer *drawLayer;
@property (weak, nonatomic) IBOutlet UILabel *qrcodeLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.tabBar.selectedItem = self.tabBar.items[0];
    self.tabBar.delegate = self;
    self.tabBar.items[0].selectedImage = [UIImage imageNamed:@"qrcode_tabbar_icon_qrcode_highlighted"];
    self.tabBar.items[1].selectedImage = [UIImage imageNamed:@"qrcode_tabbar_icon_barcode_highlighted"];
    
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self startAnimation];
    [self setupSession];
    [self startScan];
    [self setupLayer];
}

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
    self.heightConstrain.constant = self.widthConstraint.constant * (item.tag == 1 ? 0.5 : 1);
    [self.view.layer removeAllAnimations];
    
    [self startAnimation];
}

//开始动画
-(void)startAnimation{
    self.topConstrain.constant = -self.heightConstrain.constant;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:2.0 animations:^{
        [UIView setAnimationRepeatCount:MAXFLOAT];
        self.topConstrain.constant = self.heightConstrain.constant;
        [self.view layoutIfNeeded];
    }];

}

///开始扫描
-(void)startScan{
    [self.session startRunning];
}

//设置涂层
-(void)setupLayer{
    self.drawLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.drawLayer atIndex:0];
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
}

-(AVCaptureSession *)session{
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

-(AVCaptureDeviceInput *)inputDevice{
    if (!_inputDevice) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        _inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    }
    return _inputDevice;
}

-(AVCaptureMetadataOutput *)outputData{
    if (!_outputData) {
        _outputData = [[AVCaptureMetadataOutput alloc] init];
    }
    return _outputData;
}

-(AVCaptureVideoPreviewLayer *)previewLayer{
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    }
    return _previewLayer;
}

-(CALayer *)drawLayer{
    if (!_drawLayer) {
        _drawLayer = [[CALayer alloc] init];
    }
    return _drawLayer;
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    //清空图层
    [self clearLayer];
    
    for (id obj in metadataObjects) {
        if ([[obj class] isSubclassOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            //数据类型转换
            AVMetadataObject *codeObj = [self.previewLayer transformedMetadataObjectForMetadataObject:obj];
            [self drawConners:(AVMetadataMachineReadableCodeObject *)codeObj];
            self.qrcodeLabel.text = ((AVMetadataMachineReadableCodeObject *)codeObj).stringValue;
        }
    }
}

-(void)drawConners:(AVMetadataMachineReadableCodeObject *)codeObject{
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.lineWidth = 3;
    layer.strokeColor = [[UIColor blueColor] CGColor];
    layer.fillColor = [[UIColor clearColor] CGColor];
    //corners是一个包含CFDictionary类型的数组
    layer.path = [[self drawPath:codeObject.corners] CGPath];
    [self.drawLayer addSublayer:layer];
}

-(void)clearLayer{
    if (self.drawLayer.sublayers == nil) {
        return;
    }
    int i = 0;
    while (self.drawLayer.sublayers != nil) {
        [self.drawLayer.sublayers[i++] removeFromSuperlayer];
    }
//
//    for (CALayer *layer in self.drawLayer.sublayers) {
//        [layer removeFromSuperlayer];
//    }
}

-(UIBezierPath *)drawPath:(NSArray *)corners{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGPoint point = CGPointMake(0,0);
    NSInteger index = 0;
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)corners[index++], &point);
    [path moveToPoint:point];
    while (index < corners.count) {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)corners[index++], &point);
        [path addLineToPoint:point];
    }
    [path closePath];
    return path;
}

-(void)setupSession{
     //判断能否添加设备
    if (![self.session canAddInput:self.inputDevice]){
        NSLog(@"无法添加设备");
        return;
    }
    //判断能否输出数据
    if (![self.session canAddOutput:self.outputData]) {
        NSLog(@"无法添加输出设备");
        return;
    }
    //添加设备
    [_session addInput:_inputDevice];
    NSLog(@"%@",_outputData.availableMetadataObjectTypes);
    [_session addOutput:_outputData];
    NSLog(@"%@",_outputData.availableMetadataObjectTypes);
    //只有添加到session之后，输出数据类型才可用
    _outputData.metadataObjectTypes = _outputData.availableMetadataObjectTypes;
    [_outputData setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
