//
//  DemoCell.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/24.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit

class DemoCell: UITableViewCell {


    @IBOutlet weak var titleLabel: UILabel!
    
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
            self.photoVC?.URLList = (sList,lList)
        }
    }
    // 测试数组
    override func awakeFromNib() {
        super.awakeFromNib()
        let photoVC = PhotoBrowserScanViewController()
        self.photoVC = photoVC
        photoView = photoVC.view
        self.contentView.addSubview(photoView!)
        setPropertys()
        // 添加约束
        addConstraint()
    }
    
    func rowHeight(photoes : [Picture]) -> CGFloat {
        self.photoes = photoes
        self.layoutIfNeeded()
        return CGRectGetMaxY(self.photoView!.frame) + CGFloat(20.0)
    }
    
    // 添加约束
    private func addConstraint(){
        var cons = [AnyObject]()
        cons.append(NSLayoutConstraint(item: self.photoView!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.titleLabel, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 10))
        cons.append(NSLayoutConstraint(item: self.photoView!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.titleLabel, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        self.contentView.addConstraints(cons)
    }
    // 设置视图属性
    private func setPropertys() {
//        photoVC?.itemSize = CGSizeMake(180, 180)
    }

}
