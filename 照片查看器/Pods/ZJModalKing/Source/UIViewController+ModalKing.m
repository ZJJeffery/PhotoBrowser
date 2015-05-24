//
//  UIViewController+ModalKing.m
//  ModalKing
//
//  Created by Jiajun Zheng on 15/5/16.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

#import "UIViewController+ModalKing.h"

#import <objc/runtime.h>
#import "ZJAnimationDelegate.h"

@implementation UIViewController (ModalKing)

const void *animationDelegateKey = "animationDelegate";
/**
 *  runtime动态加载执行动画的代理属性的set方法
 */
- (void)setAnimationDelegate:(ZJAnimationDelegate *)animationDelegate {
    objc_setAssociatedObject(self, animationDelegateKey, animationDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
/**
 *  runtime动态加载执行动画的代理属性的get方法
 */
- (ZJAnimationDelegate *)animationDelegate {
    return objc_getAssociatedObject(self, animationDelegateKey);
}

-(void)mk_presentViewController:(UIViewController *)modalVC
               withPresentFrame:(CGRect)presentFrame
           withPresentAnimation:(NSTimeInterval (^)(UIView *view))presentAnimation
            withDismissAnimation:(NSTimeInterval (^)(UIView *view))dismissAnimation
                 withCompletion:(void (^)(void))completion
{
    self.animationDelegate = [ZJAnimationDelegate new];
    modalVC.transitioningDelegate = (id)self.animationDelegate;
    modalVC.modalPresentationStyle = UIModalPresentationCustom;
    self.animationDelegate.presentFrame = presentFrame;
    self.animationDelegate.presentAnimation = presentAnimation;
    self.animationDelegate.dismissAnimation = dismissAnimation;
    [self presentViewController:modalVC animated:YES completion:completion];
}

-(void)mk_presentViewControllerWithDummingView:(UIViewController *)modalVC
                              withPresentFrame:(CGRect)presentFrame
                          withPresentAnimation:(NSTimeInterval (^)(UIView *view))presentAnimation
                          withDismissAnimation:(NSTimeInterval (^)(UIView *view))dismissAnimation
                                withCompletion:(void (^)(void))completion
{
    self.animationDelegate = [ZJAnimationDelegate new];
    self.animationDelegate.needCover = YES;
    modalVC.transitioningDelegate = (id)self.animationDelegate;
    modalVC.modalPresentationStyle = UIModalPresentationCustom;
    self.animationDelegate.presentFrame = presentFrame;
    self.animationDelegate.presentAnimation = presentAnimation;
    self.animationDelegate.dismissAnimation = dismissAnimation;
    [self presentViewController:modalVC animated:YES completion:completion];
}
@end
