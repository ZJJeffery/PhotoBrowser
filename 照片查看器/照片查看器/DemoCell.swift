//
//  DemoCell.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/24.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit

class DemoCell: UITableViewCell {

    
    var photoVC : PhotoBrowserScanViewController?
    
    var photoView : UIView?
    
    /// 图片资源
    var photoes : [Picture]? {
        didSet {
            // 小图数组
            var sList = [NSURL]()
            // 大图数组
            var lList = [NSURL]()
            for p in photoes! {
                lList.append(p.largeURL!)
                sList.append(p.smallURL!)
            }
            // 将数组赋值
            self.smallURLList = sList
            self.largeURLList = lList
        }
    }
    /// 小图数组
    var smallURLList : [NSURL]? {
        didSet {
            self.photoVC!.smallURLList = smallURLList
        }
    }
    /// 大图数组
    var largeURLList : [NSURL]? {
        didSet {
            self.photoVC!.largeURLList = largeURLList
        }
    }
    // 测试数组
    override func awakeFromNib() {
        super.awakeFromNib()
        let photoVC = PhotoBrowserScanViewController()
        self.photoVC = photoVC
        photoView = photoVC.view
        self.addSubview(photoView!)
    }

//    override func layoutSubviews() {
//        super.layoutSubviews()
//        photoView?.frame = self.bounds
//    }

}
