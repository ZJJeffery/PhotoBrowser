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
            SDWebImageManager.sharedManager().downloadImageWithURL(url, options: SDWebImageOptions.allZeros, progress: nil) { (image, error, _, _, _) -> Void in
                if image == nil && error != nil{
                    println(error)
                    // 设置错误图片
                    return
                }
                if self.isLongImage(image) {
                    self.imageView!.contentMode = UIViewContentMode.Top
                }else{
                    self.imageView!.contentMode = UIViewContentMode.ScaleAspectFill
                }
                self.imageView!.image = image
            }
            imageView!.sd_setImageWithURL(url)
        }
    }
    
    // 判断长短图
    private func isLongImage(image : UIImage) -> Bool{
        let size = scaleImageSize(image, relateToWidth: UIScreen.mainScreen().bounds.width)
        if size.height > UIScreen.mainScreen().bounds.height {
            return true
        }
        return false
    }
    // 计算图片缩放根据给定的宽度
    private func scaleImageSize(image : UIImage, relateToWidth width: CGFloat) -> CGSize {
        let imageW = image.size.width
        let imageH = image.size.height
        let scaleH = width * imageH / imageW
        return CGSizeMake(width, scaleH)
    }
    // 布局内部图像视图
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame = self.bounds
    }
}
