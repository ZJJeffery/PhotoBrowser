//
//  UIViewController+ModalKing.h
//  ModalKing
//
//  Created by Jiajun Zheng on 15/5/16.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZJAnimationDelegate;
@interface UIViewController (ModalKing)
/**
 *  进行转场动画的代理对象
 */
@property (nonatomic, strong) ZJAnimationDelegate *animationDelegate;
/**
 *  自定义modal的跳转方式
 *
 *  @param modalVC          需要展示的viewController
 *  @param presentFrame     展示视图在屏幕的frame
 *  @param presentAnimation 展示动画代码（返回的时间是转场动画上下文关闭的时间）
 *  @param dismissAnimation 消失动画代码（返回的时间是转场动画上下文关闭的时间）
 关于转场动画上下文时长说明：
 转场动画上下文关闭的时间决定了改转场动画封锁界面的用户交互能力的时长，如果返回0表示立马接受用户交互，
 那么可能存在在动画过程中用户交互而导致动画达不到预期效果。
 一般建议返回动画的时间长度，正好动画结束，然后开启用户交互能力。
 特殊需求可以填写特殊时长
 *  @param completion       完成回调
 */
-(void)mk_presentViewController:(UIViewController *)modalVC
               withPresentFrame:(CGRect)presentFrame
           withPresentAnimation:(NSTimeInterval (^)(UIView *view))presentAnimation
           withDismissAnimation:(NSTimeInterval (^)(UIView *view))dismissAnimation
                 withCompletion:(void (^)(void))completion;

/**
 *  自定义modal的跳转方式,自带透明遮盖，点击非跳转界面可以dismiss
 *
 *  @param modalVC          需要展示的viewController
 *  @param presentFrame     展示视图在屏幕的frame
 *  @param presentAnimation 展示动画代码（返回的时间是转场动画上下文关闭的时间）
 *  @param dismissAnimation 消失动画代码（返回的时间是转场动画上下文关闭的时间）
 关于转场动画上下文时长说明：
 转场动画上下文关闭的时间决定了改转场动画封锁界面的用户交互能力的时长，如果返回0表示立马接受用户交互，
 那么可能存在在动画过程中用户交互而导致动画达不到预期效果。
 一般建议返回动画的时间长度，正好动画结束，然后开启用户交互能力。
 特殊需求可以填写特殊时长
 *  @param completion       完成回调
 */
-(void)mk_presentViewControllerWithDummingView:(UIViewController *)modalVC
               withPresentFrame:(CGRect)presentFrame
           withPresentAnimation:(NSTimeInterval (^)(UIView *view))presentAnimation
           withDismissAnimation:(NSTimeInterval (^)(UIView *view))dismissAnimation
                 withCompletion:(void (^)(void))completion;
@end
