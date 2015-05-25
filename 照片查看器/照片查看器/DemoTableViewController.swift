//
//  DemoTableViewController.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/24.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit

private let reusedId = "demoCell"

class DemoTableViewController: UITableViewController {

    lazy var heightCache : NSCache = {
        return NSCache()
    }()
    
    /// 图片资源
    lazy var photoes : [Picture] = {
        let pList = Picture.picturesList()
        return pList
    }()
    /// 测试数组
    lazy var dataList : [[Picture]] = {
        var result = [[Picture]]()
        for i in 1..<10 {
            var list = [Picture]()
            for x in 0..<i {
                list.append(self.photoes[x])
            }
            result.append(list)
        }
        return result
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reusedId, forIndexPath: indexPath) as! DemoCell
        if !(childViewControllers as NSArray).containsObject(cell.photoVC!) {
            addChildViewController(cell.photoVC!)
        }
        cell.photoes = self.dataList[indexPath.row] as [Picture]
        return cell
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if heightCache.objectForKey(indexPath.row) == nil {
            let photoes = self.dataList[indexPath.row] as [Picture]
            let cell = tableView.dequeueReusableCellWithIdentifier(reusedId) as! DemoCell
            let rowHeight = cell.rowHeight(photoes)
            heightCache.setObject(rowHeight, forKey: indexPath.row)
            println("\(indexPath.row) height: \(rowHeight)")
            return rowHeight
        }
        return heightCache.objectForKey(indexPath.row) as! CGFloat
    }
}
