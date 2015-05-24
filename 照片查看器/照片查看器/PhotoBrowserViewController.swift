//
//  PhotoBrowserViewController.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/21.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit
import SVProgressHUD


let reuseIdentifier = "Cell"
// 交互时颜色变化通知
let PhotoBrowserDidScaleNotification = "PhotoBrowserDidScaleNotification"

class PhotoBrowserViewController: UIViewController {
    //MARK: - 属性
    /// 布局属性
    lazy var layout : UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = self.view.frame.size
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        return flowLayout
    }()
    /// collectionView
    lazy var collectionView : UICollectionView = {
        let cv = UICollectionView(frame: self.view.bounds, collectionViewLayout: self.layout)
        cv.backgroundView = UIView(frame: self.view.bounds)
        cv.backgroundColor = UIColor.clearColor()
        // 设置背景视图的颜色，为了之后对于不同的颜色可以通过调节视图的透明度来实现颜色渐变
        cv.backgroundView?.backgroundColor = UIColor.blackColor()
        // 设置数据源代理
        cv.dataSource = self
        // 设置其他属性
        cv.pagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    /// 关闭按钮
    lazy var closeBtn : UIButton = {
        return self.createButton("关闭")
    }()
    /// 大图URL数组
    var largeImageURLList : [NSURL]?
    /// 大图URL数组
    var smallImageURLList : [NSURL]?
    /// 浏览的位置
    var index : Int?
    /// 所有frame对于主视图的位置
    var startFrameList : [CGRect]?
    var endFrameList : [CGRect]?
    
    //MARK: - 内部方法
    override func loadView() {
        let frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width + 20, UIScreen.mainScreen().bounds.height)
        view = UIView(frame: frame)
        view.backgroundColor = UIColor.clearColor()
        view.addSubview(self.collectionView)
        // 创建约束
        var cons = [AnyObject]()
        cons += NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[btn(80)]", options: NSLayoutFormatOptions(0), metrics: nil, views: ["btn" : closeBtn])
        
        cons += NSLayoutConstraint.constraintsWithVisualFormat("V:[btn]-20-|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["btn" : closeBtn])
        // 添加约束
        view.addConstraints(cons)
        
        // 监听方法
        closeBtn.addTarget(self, action: "close", forControlEvents: UIControlEvents.TouchUpInside)
    }
    override func viewDidLoad() {
        // 注册cell
        collectionView.registerClass(PhotoBrowserCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        // 注册通知
        registerNotification()
    }
    override func viewDidLayoutSubviews() {
        let indexPath = NSIndexPath(forItem: index!, inSection: 0)
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.allZeros, animated: false)
    }
    // 销毁通知
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    /// 所有注册的通知
    private func registerNotification(){
        // 注册通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didDismiss", name: PhotoBrowserEndDismissNotification, object: nil)
        // 注册通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didScale:", name: PhotoBrowserDidScaleNotification, object: nil)
    }
    
    /// 关闭视图
    func close() {
        SVProgressHUD.dismiss()
        // 确定关闭的图像索引
        let indexPath = collectionView.indexPathsForVisibleItems().last as! NSIndexPath
        let index = indexPath.item
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        self.view.alpha = 0
        // 发送开始关闭通知
        NSNotificationCenter.defaultCenter().postNotificationName(PhotoBrowserStartDismissNotification, object: nil, userInfo: ["index": index])
    }
    func didDismiss(){
        dismissViewControllerAnimated(false, completion: nil)
    }
    /// 创建按钮
    private func createButton(title: String) -> UIButton {
        let btn = UIButton()
        btn.setTitle(title, forState: UIControlState.Normal)
        btn.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        btn.backgroundColor = UIColor.brownColor()
        view.addSubview(btn)
        // 设置自动布局须关闭
        btn.setTranslatesAutoresizingMaskIntoConstraints(false)
        return btn
    }
    /// 开始缩放的通知方法
    func didScale(noti : NSNotification){
        let scale = noti.userInfo!["scale"] as! CGFloat
        // 隐藏关闭按钮
        closeBtn.hidden = scale < 1.0
        collectionView.backgroundView?.alpha = scale
    }
}
//MARK: - 数据源方法
extension PhotoBrowserViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return largeImageURLList?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoBrowserCell
        // 添加子控制器
        if !(childViewControllers as NSArray).containsObject(cell.viewerVC!) {
            addChildViewController(cell.viewerVC!)
        }
        // 设置图片URL
        cell.smallURL = smallImageURLList![indexPath.item]
        cell.largeURL = largeImageURLList![indexPath.item]
        // 传递当前索引
        cell.index = indexPath.item
        return cell
    }
}


