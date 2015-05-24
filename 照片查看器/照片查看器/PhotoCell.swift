//
//  PhotoCell.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/21.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit
import SDWebImage

class PhotoCell: UICollectionViewCell {
    
    lazy var imageView : UIImageView? = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        return imageView
    }()
    
    var url : NSURL? {
        didSet {
            imageView!.sd_setImageWithURL(url)
        }
    }

    // 布局内部图像视图
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame = self.bounds
    }
}
