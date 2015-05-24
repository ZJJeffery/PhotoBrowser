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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let photoVC = PhotoBrowserScanViewController()
        self.photoVC = photoVC
        photoView = photoVC.view
        self.addSubview(photoView!)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        photoView?.frame = self.bounds
    }

}
