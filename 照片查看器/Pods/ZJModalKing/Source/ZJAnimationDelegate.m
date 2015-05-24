//
//  ZJAnimationDelegate.m
//  ModalKing
//
//  Created by Jiajun Zheng on 15/5/16.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

#import "ZJAnimationDelegate.h"
#import "ZJPresentationController.h"
@interface ZJAnimationDelegate ()<UIViewControllerTransitioningDelegate,UIViewControllerAnimatedTransitioning>
@property (nonatomic, assign) BOOL isPresenting;

@end

@implementation ZJAnimationDelegate
-(UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source{
    ZJPresentationController *pc =  [[ZJPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    pc.presentFrame = self.presentFrame;
    pc.needCover = self.isNeedCover;
    return pc;
}

#pragma mark - UIViewControllerTransitioningDelegate代理方法
- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    self.isPresenting = YES;
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    self.isPresenting = NO;
    return self;
}
#pragma mark - UIViewControllerAnimatedTransitioning方法
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext;
{
    return 5.0;
}
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    if (self.isPresenting) {
        UIView *view = [transitionContext viewForKey:UITransitionContextToViewKey];
        [[transitionContext containerView] addSubview:view];
        // 动画部分
        NSTimeInterval time = self.presentAnimation(view);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [transitionContext completeTransition:YES];
        });
    }else {
        UIView *view = [transitionContext viewForKey:UITransitionContextFromViewKey];
        NSTimeInterval time = self.dismissAnimation(view);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [transitionContext completeTransition:YES];
            [view removeFromSuperview];
        });
        
        //        [UIView animateWithDuration:2 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:5.0 options:UIViewAnimationOptionTransitionNone animations:^{
        //            view.transform = CGAffineTransformMakeScale(1, 0);
        //            NSLog(@"%@",view);
        //        } completion:^(BOOL finished) {
        //            
        //
        //        }];
    }
}
@end
