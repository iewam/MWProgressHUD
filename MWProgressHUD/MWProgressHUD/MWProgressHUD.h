//
//  MWProgressHUD.h
//  Facaishu
//
//  Created by caifeng on 2016/11/29.
//  Copyright © 2016年 领鲜01. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {

    MWProgressHUDModeGIF = 1,
    MWProgressHUDModeIndicator,
    MWProgressHUDModeMessage,
    MWProgressHUDModeSuccessMessage,
    MWProgressHUDModeErrorMessage
    
} MWProgressHUDMode;

@interface MWProgressHUD : UIView


/**
 显示Gif HUD在指定view上

 @param targetView 目标view
 @return <#return value description#>
 */
+ (instancetype)showGifHUDOnView:(UIView *)targetView;


/**
 显示活动指示器HUD在指定view 上

 @param targetView 目标view
 @return <#return value description#>
 */
+ (instancetype)showIndicatorHUDOnView:(UIView *)targetView;


/**
 显示提示信息在指定view 上

 @param message 提示信息
 @param targetView 目标view
 @return <#return value description#>
 */
+ (instancetype)showMessage:(NSString *)message onView:(UIView *)targetView;


+ (instancetype)showSuccessMessage:(NSString *)successMessage;
+ (instancetype)showErrorMessage:(NSString *)errorMessage;


/**
 隐藏指定view上的HUD

 @param targetView <#targetView description#>
 */
+ (void)hideHUDFromView:(UIView *)targetView;

@end
