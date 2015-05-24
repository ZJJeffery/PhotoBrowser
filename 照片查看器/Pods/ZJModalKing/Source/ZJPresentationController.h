//
//  ZJPresentationController.h
//  ModalKing
//
//  Created by Jiajun Zheng on 15/5/16.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZJPresentationController : UIPresentationController
@property (nonatomic, assign) CGRect presentFrame;
@property (nonatomic, assign,getter=isNeedCover) BOOL needCover;
@end
