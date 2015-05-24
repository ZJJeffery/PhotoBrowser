//
//  PhotoBrowserCell.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/21.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit

class PhotoBrowserCell: UICollectionViewCell {
    /// 查看照片控制器
    var viewerVC: SinglePhotoBrowserViewController?
    
    /// 要显示的图片的 URL
    var largeURL: NSURL? {
        didSet {
            viewerVC?.largeURL = largeURL
        }
    }
    /// 要显示的图片的小图 URL
    var smallURL: NSURL? {
        didSet {
            viewerVC?.smallURL = smallURL
        }
    }
    /// 要显示的图片的小图 URL
    var index: Int? {
        didSet {
            viewerVC?.index = index
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 创建视图控制器
        viewerVC = SinglePhotoBrowserViewController()
        viewerVC?.view.frame = bounds
        // 添加视图
        self.addSubview(viewerVC!.view)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
