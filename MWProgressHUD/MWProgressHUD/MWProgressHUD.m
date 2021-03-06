//
//  MWProgressHUD.m
//  Facaishu
//
//  Created by caifeng on 2016/11/29.
//  Copyright © 2016年 领鲜01. All rights reserved.
//

#import "MWProgressHUD.h"
#import "MWProgressHUDConst.h"

#define MW_MaxSize CGSizeMake(MAXFLOAT, MAXFLOAT)
#define MW_TextSize(text, font) [text length] > 0 ? [text boundingRectWithSize:MW_MaxSize \
        options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : \
        [UIFont systemFontOfSize:font]} context:nil].size : CGSizeZero;

#define MW_MultiLine_TextSize(text, font, maxSize) [text length] > 0 ? [text \
        boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin \
        attributes:@{NSFontAttributeName :[UIFont systemFontOfSize:font]} context:nil].size\
        : CGSizeZero;

#define MW_Bounds(width, height) CGRectMake(0, 0, width, height);
#define MW_ScreenWidth [UIScreen mainScreen].bounds.size.width
#define MW_ScreenHeight [UIScreen mainScreen].bounds.size.height
#define MW_MainWindow [[[UIApplication sharedApplication] windows] firstObject]

@interface MWProgressHUD ()

@property (nonatomic, strong) CAShapeLayer *dimLayer;/**<背景layer*/
@property (nonatomic, strong) UIColor *dimBackgroundColor;/**<背景色*/
@property (nonatomic, assign) CGFloat dimBackgroundOpacity;/**<背景色不透明度*/
@property (nonatomic, strong) UIView *targetView;/**<放HUD的View*/
@property (nonatomic, assign) MWProgressHUDMode mode;/**<指示器的类型*/
@property (nonatomic, strong) UILabel *label;/**<描述Label*/
@property (nonatomic, assign) CGFloat labelFont;
@property (nonatomic, assign) CGFloat labelWidth;
@property (nonatomic, assign) CGFloat labelHeight;
@property (nonatomic, strong) UIView *indicator;/**<指示器*/
@property (nonatomic, assign) CGFloat indicatorWHScale;/**<指示器的宽高比例*/
@property (nonatomic, assign) CGFloat indicatorWidth;/**<指示器的宽度*/
@property (nonatomic, assign) CGFloat indicatorHeight;/**<指示器的高度*/

@property (nonatomic, copy) NSString *message;

@end


@implementation MWProgressHUD

#pragma mark **** 显示GIF图片加载指示器HUD在View上
+ (instancetype)showGifHUDOnView:(UIView *)targetView {
    
    // 处理滑动视图
    if ([targetView isKindOfClass:[UIScrollView class]]) {
        UIScrollView *view = (UIScrollView *)targetView;
        [view setContentOffset:CGPointZero animated:NO];
    }
    return [self showHUDOnView:targetView mode:MWProgressHUDModeGIF message:MWProgressHUDLoadingLabelText];
}

#pragma mark **** 显示系统加载指示器HUD在View上
+ (instancetype)showIndicatorHUDOnView:(UIView *)targetView {

    return [self showHUDOnView:targetView mode:MWProgressHUDModeIndicator message:nil];
}

#pragma mark **** 显示message在View上
+ (instancetype)showMessage:(NSString *)message onView:(UIView *)targetView{

    MWProgressHUD *hud = [self showHUDOnView:targetView mode:MWProgressHUDModeMessage message:message];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MWProgressHUDMessageLabelShowDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideHUDFromView:targetView];
    });
    return hud;
}


+ (instancetype)showSuccessMessage:(NSString *)successMessage {return nil;}
+ (instancetype)showErrorMessage:(NSString *)errorMessage{return nil;}


#pragma mark **** 隐藏HUD

+ (void)hideHUDFromView:(UIView *)targetView {
    
    MWProgressHUD *hud = [self hudOnView:targetView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MWProgressHUDGifShowDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud removeFromSuperview];
    });
}

+ (instancetype)showHUDOnView:(UIView *)targetView mode:(MWProgressHUDMode)mode message:(NSString *)message{

    MWProgressHUD *hud = [self getCurrentHUDOnView:targetView];
    hud.message = message;
    hud.mode = mode;
    return hud;
}


#pragma mark **** 获取当前HUD 如果不存在创建
+ (instancetype)getCurrentHUDOnView:(UIView *)targetView {
    
    MWProgressHUD *hud = [self hudOnView:targetView];
    if (hud) {
        return hud;
    } else {
        hud = [[MWProgressHUD alloc] initWithView:targetView];
        [targetView addSubview:hud];
        hud.targetView = targetView;
        return hud;
    }
    return nil;
}

#pragma mark **** 获取当前view上的HUD
+ (instancetype)hudOnView:(UIView *)targetView {

    for (UIView *view in targetView.subviews) {
        if ([view isKindOfClass:[MWProgressHUD class]]) {
            return (MWProgressHUD *)view;
        }
    }
    return nil;
}

- (instancetype)initWithView:(UIView *)targetView {

    return [self initWithFrame:targetView.bounds];
}

- (instancetype)initWithFrame:(CGRect)frame {

    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        [self updateIndicators];
        [self addObserverForKeyPaths];
        
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    
    [_dimBackgroundColor setFill];
//    self.layer.opacity = _dimBackgroundOpacity;
    UIRectFill(rect);
}

- (void)layoutSubviews {

    self.indicatorWidth = _indicatorHeight * _indicatorWHScale;
    self.indicator.bounds = MW_Bounds(_indicatorWidth, _indicatorHeight);
    self.indicator.center = self.center;
    
    CGSize size = MW_TextSize(self.message, _labelFont);
    CGFloat maxWidth = MW_ScreenWidth * 0.6 - 2 * MWProgressHUDMessageLabelMarginX;
    CGFloat width = MIN(size.width, maxWidth);
    CGSize newSize = size.width < maxWidth ? size : MW_MultiLine_TextSize(self.message, _labelFont, CGSizeMake(width, MAXFLOAT));
    self.labelWidth = newSize.width;
    self.labelHeight = newSize.height;
    self.label.bounds = MW_Bounds(_labelWidth, _labelHeight);
    // 根据label是gif加载描述和messageLabel来确定中心位置
    self.label.center = _indicatorHeight == 0 ? self.center : CGPointMake(CGRectGetMidX(_indicator.frame), CGRectGetMaxY(_indicator.frame) + _labelHeight * 0.5);
    
    UIView *messageBgView = [self viewWithTag:10];
    if (messageBgView) {
        messageBgView.bounds = CGRectMake(0, 0, CGRectGetWidth(self.label.frame) + MWProgressHUDMessageLabelMarginX * 2, CGRectGetHeight(self.label.frame) + MWProgressHUDMessageLabelMarginY * 2);
        messageBgView.center = self.label.center;
    }
}

#pragma mark **** 更新指示器类型
- (void)updateIndicators {

    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (_mode == MWProgressHUDModeGIF) {
       
        _indicatorHeight = MWProgressHUDGifIndicatorHeight;
        _labelFont = MWProgressHUDLoadingLabelFont;
        _dimBackgroundColor = MWProgressHUDGifDimBackgroundColor;
        _dimBackgroundOpacity = MWProgressHUDGifDimBackgroundOpacity;

        _indicator = [[UIImageView alloc] initWithFrame:self.bounds];
        [(UIImageView *)_indicator setAnimationImages:[self animationImages]];
        [self addSubview:_indicator];
        [(UIImageView *)_indicator setAnimationDuration:MWProgressHUDGifAnimationDuration];
        [(UIImageView *)_indicator startAnimating];
        
        [self setupLabelWithTextColor:MWProgressHUDGifLoadingLabelTextColor fontSize:MWProgressHUDLoadingLabelFont text:MWProgressHUDLoadingLabelText];

    } else if (_mode == MWProgressHUDModeIndicator){
        
        _dimBackgroundColor = MWProgressHUDGifDimBackgroundColor;
        _dimBackgroundOpacity = MWProgressHUDGifDimBackgroundOpacity;
        
        _indicator = [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
        [(UIActivityIndicatorView *)_indicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [(UIActivityIndicatorView *)_indicator startAnimating];
        [self addSubview:_indicator];
        [self insertBgViewForSystemIndicator:_indicator];
        
    } else if (_mode == MWProgressHUDModeMessage) {
    
        _indicatorHeight = 0;
        _labelFont = MWProgressHUDMessageLabelFont;
        _dimBackgroundColor = MWProgressHUDMessageDimBackgroundColor;
        _dimBackgroundOpacity = MWProgressHUDMessageDimBackgroundOpacity;
        
        [self setupLabelWithTextColor:MWProgressHUDMessageLabelTextColor fontSize:MWProgressHUDMessageLabelFont text:self.message];
        [self insertBgViewForMessageLabel];
    }
}

#pragma mark **** 加载提示Label/messageLabel
- (void)setupLabelWithTextColor:(UIColor *)textColor fontSize:(CGFloat)fontSize text:(NSString *)text {

    self.label = [[UILabel alloc] initWithFrame:self.bounds];
    self.label.font = [UIFont systemFontOfSize:fontSize];
    self.label.textColor = textColor;
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.text = text;
    self.label.numberOfLines = 0;
    [self insertSubview:self.label atIndex:0];
}

#pragma mark **** 为消息提示Label添加背景View
- (void)insertBgViewForMessageLabel {

    UIView *bgView = [[UIView alloc] initWithFrame:self.bounds];
    bgView.backgroundColor = [UIColor blackColor];
    bgView.center = _label.center;
    bgView.layer.cornerRadius = 10;
    bgView.tag = 10;
    [self insertSubview:bgView belowSubview:self.label];
}

#pragma mark - 系统活动指示器的背景View
- (void)insertBgViewForSystemIndicator:(UIView *)systemIndicator {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 74, 74)];
    bgView.backgroundColor = [UIColor blackColor];
    bgView.center = self.center;
    bgView.layer.cornerRadius = 10;
    [self insertSubview:bgView belowSubview:systemIndicator];
}

#pragma mark **** KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    if ([keyPath isEqualToString:@"mode"]) {
        
        if ([[change objectForKey:@"new"] integerValue] == [[change objectForKey:@"old"] integerValue])            return;
        [self updateIndicators];
        [self setNeedsDisplay];
        
    } else if ([keyPath isEqualToString:@"targetView.frame"]) {// 监听父Viewframe变化 改变HUD的frame
        self.frame = self.targetView.bounds;
//        MWLog(@"%@", NSStringFromCGRect(self.targetView.frame));
    }
}

#pragma mark **** KVO监听keyPath
- (void)addObserverForKeyPaths {

    for (NSString *keyPath in [self keyPaths]) {
        [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
}

#pragma mark **** KVO监听的keyPath数组
- (NSArray *)keyPaths {
    
    return [NSArray arrayWithObjects:@"mode",@"targetView.frame", nil];
}

#pragma mark **** GIF的图片数组
- (NSMutableArray *)animationImages {
    
    NSMutableArray *animationImages = [NSMutableArray array];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"MWProgressHUD" ofType:@".bundle"];
    NSArray *imageNameArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *imageName in imageNameArr) {
        NSString *imagePath = [path stringByAppendingPathComponent:imageName];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        _indicatorWHScale = image.size.width / image.size.height;
        [animationImages addObject:image];
    }
    return animationImages;
}

#pragma mark **** 移除KVO
- (void)removeObserverForKeyPaths {

    for (NSString *keyPath in [self keyPaths]) {
        [self removeObserver:self forKeyPath:keyPath];
    }
}


- (void)dealloc {
//    MWLog(@"MWprogressHUD delloc");
    [self removeObserverForKeyPaths];
}


@end
