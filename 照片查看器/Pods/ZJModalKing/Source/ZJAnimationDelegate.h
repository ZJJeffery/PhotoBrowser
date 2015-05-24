//
//  ZJAnimationDelegate.h
//  ModalKing
//
//  Created by Jiajun Zheng on 15/5/16.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZJAnimationDelegate : NSObject
@property (nonatomic, assign) CGRect presentFrame;
@property (nonatomic, copy) NSTimeInterval (^presentAnimation)(UIView *);
@property (nonatomic, copy) NSTimeInterval (^dismissAnimation)(UIView *);
@property (nonatomic, assign,getter=isNeedCover) BOOL needCover;
@end
