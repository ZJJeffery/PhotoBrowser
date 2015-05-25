//
//  DemoTableViewController.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/24.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit

class DemoTableViewController: UITableViewController {
    /// 图片资源
    lazy var photoes : [Picture] = {
        let pList = Picture.picturesList()
        return pList
    }()
    
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

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("demoCell", forIndexPath: indexPath) as! DemoCell
        if !(childViewControllers as NSArray).containsObject(cell.photoVC!) {
            addChildViewController(cell.photoVC!)
        }
        cell.photoes = self.dataList[indexPath.row] as [Picture]
        return cell
    }
}
