//
//  DemoCell.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/24.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit

class DemoCell: UITableViewCell, PhotoBrowserControllerDelegate {


    @IBOutlet weak var titleLabel: UILabel!
    
    var photoVC : PhotoBrowserController?
    
    var photoView : UIView?
    
    var singleImageSize: CGSize?
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
        // 添加控制器
        let photoVC = PhotoBrowserController()
        // 一般不需要设置，如有需要的其他属性改变，可以实现特定的代理方法
        photoVC.delegate = self
        // 记录控制器
        self.photoVC = photoVC
        // 添加视图
        photoView = photoVC.view
        self.contentView.addSubview(photoView!)
        // 添加约束
        addConstraint()
        // 添加只有一张图片的时候的大小,该示例未赋值该属性
        photoVC.singleImageSize = singleImageSize
    }

    // 添加约束，须手动添加约束，内部长宽属性已经被设置好了，会根据具体图片数目做出判断
    private func addConstraint(){
        var cons = [NSLayoutConstraint]()
        // 位置约束
        cons.append(NSLayoutConstraint(item: self.photoView!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.titleLabel, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 10))
        cons.append(NSLayoutConstraint(item: self.photoView!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.titleLabel, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        self.contentView.addConstraints(cons)
    }
    
    func rowHeight(photoes : [Picture]) -> CGFloat {
        self.photoes = photoes
        self.layoutIfNeeded()
        return CGRectGetMaxY(self.photoView!.frame) + CGFloat(20.0)
    }
    

}
