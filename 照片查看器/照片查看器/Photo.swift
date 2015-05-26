//
//  Photo.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/26.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit
//MARK: - 处理图片的模型
class Photo: NSObject {
    //MARK: - 属性
    // 小图地址
    var smallURL: NSURL
    // 大图地址
    var largeURL: NSURL
    //内部方法
    /// 初始化方法
    init(smallURL : NSURL, largeURL : NSURL){
        self.smallURL = smallURL
        self.largeURL = largeURL
    }
    /// 快速创建方法
    class func photoes(smallURLList : [NSURL], largeURLList : [NSURL]) -> [Photo]{
        var photoM = [Photo]()
        for i in 0..<smallURLList.count {
            let modal = Photo(smallURL: smallURLList[i], largeURL: largeURLList[i])
            photoM.append(modal)
        }
        return photoM
    }
}
