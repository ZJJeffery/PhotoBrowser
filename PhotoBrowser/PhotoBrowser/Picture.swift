//
//  Picture.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/21.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit

class Picture: NSObject {
    var small : String? {
        didSet {
            smallURL = NSURL(string: small!)
        }
    }
    var large : String?{
        didSet {
            largeURL = NSURL(string: large!)
        }
    }
    var smallURL : NSURL?
    var largeURL : NSURL?
    
    static let properties = ["small", "large"]
    
    init(dic: NSDictionary) {
        super.init()
        
        for key in Picture.properties {
            if dic[key] != nil {
                setValue(dic[key], forKey: key)
            }
        }
        
    }
    
    class func picturesList() -> [Picture] {
        let path = NSBundle.mainBundle().pathForResource("pictures", ofType: "plist")
        let array = NSArray(contentsOfFile: path!) as! [NSDictionary]
        
        var arrayM = [Picture]()
        
        for dic in array {
            let modal = Picture(dic: dic)
            arrayM.append(modal)
        }
        return arrayM
    }
}
