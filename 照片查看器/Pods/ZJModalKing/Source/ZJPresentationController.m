//
//  ZJPresentationController.m
//  ModalKing
//
//  Created by Jiajun Zheng on 15/5/16.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

#import "ZJPresentationController.h"

@interface ZJPresentationController ()
@property (nonatomic, strong) UIView *dummingView;
@end

@implementation ZJPresentationController
-(void)containerViewWillLayoutSubviews
{
    [super containerViewWillLayoutSubviews];
    self.presentedView.frame = self.presentFrame;
    if (self.isNeedCover) {
        [self.containerView insertSubview:self.dummingView atIndex:0];
    }
}

-(UIView *)dummingView
{
    if (_dummingView == nil) {
        _dummingView = [[UIView alloc] initWithFrame:self.containerView.bounds];
        _dummingView.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickDumming)];
        [_dummingView addGestureRecognizer:tap];
        return _dummingView;
    }
    return _dummingView;
}

-(void)clickDumming{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
