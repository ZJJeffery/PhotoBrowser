//
//  DemoTableViewController.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/24.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit

class DemoTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("demoCell", forIndexPath: indexPath) as! DemoCell
        if !(childViewControllers as NSArray).containsObject(cell.photoVC!) {
            addChildViewController(cell.photoVC!)
        }
        return cell
    }
}
