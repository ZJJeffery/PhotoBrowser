//
//  PhotoBrowserScanViewController.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/24.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

//MARK: - 属性

//MARK: - 内部方法


//MARK: - 数据源方法


//MARK: - 代理方法

import UIKit
import ZJModalKing
import SDWebImage
import SVProgressHUD
// 通知列表
// 普通dismiss通知
let PhotoBrowserStartDismissNotification = "PhotoBrowserStartDismissNotification"
let PhotoBrowserEndDismissNotification = "PhotoBrowserEndDismissNotification"
// 交互式dismiss通知
let PhotoBrowserStartInteractiveDismissNotification = "PhotoBrowserStartInteractiveDismissNotification"


private let reusedId = "photoCell"
class PhotoBrowserScanViewController: UIViewController, UICollectionViewDataSource {
    //MARK: 属性
    // 动画时长
    let AnimationDuration = 0.3 as NSTimeInterval
    /// 布局约束
    lazy var layout : UICollectionViewFlowLayout? = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSizeMake(90, 90)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        return layout
    }()
    /// 图片视图
    lazy var collectionView: UICollectionView? = {
        let cv = UICollectionView(frame: CGRectZero, collectionViewLayout: self.layout!)
//        cv.backgroundColor = UIColor.clearColor()
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    /// 图片资源
    lazy var photoes : [Picture] = {
        let pList = Picture.picturesList()
        // 小图数组
        var sList = [NSURL]()
        // 大图数组
        var lList = [NSURL]()
        for p in pList {
            sList.append(p.smallURL!)
            lList.append(p.largeURL!)
        }
        // 将数组赋值
        self.smallURLList = sList
        self.largeURLList = lList
        // 返回
        return pList
        }()
    /// 小图数组
    var smallURLList : [NSURL]?
    /// 大图数组
    var largeURLList : [NSURL]?
    /// 小图开始frame
    var startFrameList : [CGRect]?
    /// 展开后frame
    var endFrameList : [CGRect]?
    //MARK: - 自己方法
    override func viewDidLoad() {
        view.addSubview(self.collectionView!)
        // 添加约束
        addconstraints()
        // 注册cell
        collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: reusedId)
        // 注册开始转场动画通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"dismissAnimation:", name: PhotoBrowserStartDismissNotification, object: nil)
        // 注册结束转场动画通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"interactiveDismissAnimation:", name: PhotoBrowserStartInteractiveDismissNotification, object: nil)
    }
    // 销毁通知
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    // 添加约束
    private func addconstraints() {
        // 创建约束
        var cons = [AnyObject]()
        // 字典属性
        let dic = ["collectionView" : collectionView!] as [String : AnyObject]
        // 横向约束
        cons += NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[collectionView]-0-|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: dic)
        // 纵向约束
        cons += NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[collectionView]-0-|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: dic)
        // 添加约束
        self.view.addConstraints(cons)
    }
    // 计算framelist
    private func calculateFrameLists() {
        var startFrameList = [CGRect]()
        var endFrameList = [CGRect]()
        for i in 0..<photoes.count {
            let indexPath = NSIndexPath(forItem: i, inSection: 0)
            let cell = collectionView!.cellForItemAtIndexPath(indexPath) as! PhotoCell
            // 计算开始frame
            let startFrame = cellStartFrameRelativeToMainScreen(cell)
            // 计算结束frame
            let endFrame = cellEndFrame(cell)
            // 储存
            startFrameList.append(startFrame)
            endFrameList.append(endFrame)
        }
        // 存储frame数组
        self.startFrameList = startFrameList
        self.endFrameList = endFrameList
    }
    // 坐标转换
    private func cellStartFrameRelativeToMainScreen(cell : PhotoCell) ->CGRect {
        return cell.convertRect(cell.bounds, toCoordinateSpace: UIScreen.mainScreen().fixedCoordinateSpace)
    }
    // 根据cell 计算cell对于主屏幕的frame
    private func cellEndFrame(cell : PhotoCell) ->CGRect {
        let image = cell.imageView!.image!
        let size = scaleImageSize(image, relateToWidth: view.bounds.size.width)
        let y = (UIScreen.mainScreen().bounds.height - size.height) * 0.5
        return CGRectMake(0, y, size.width, size.height)
    }
    // 计算图片缩放根据给定的宽度
    private func scaleImageSize(image : UIImage, relateToWidth width: CGFloat) -> CGSize {
        let imageW = image.size.width
        let imageH = image.size.height
        let scaleH = width * imageH / imageW
        return CGSizeMake(width, scaleH)
    }
    // 计算图片缩放根据给定的高度
    private func scaleImageSize(image : UIImage, relateToHeight height: CGFloat) -> CGSize {
        let imageW = image.size.width
        let imageH = image.size.height
        let scaleW = height * imageW / imageH
        return CGSizeMake(scaleW, height)
    }
    
    // 常规dismiss动画
    func dismissAnimation(n : NSNotification) {
        // 根据通知得知正在看第几个图
        let index = n.userInfo!["index"] as! Int
        // 创建一个view用于做回归动画
        let endFrame = view.convertRect(endFrameList![index], fromCoordinateSpace: UIScreen.mainScreen().fixedCoordinateSpace)
        // 创建图片展示正在回去的图片
        let imageView = UIImageView(frame: endFrame)
        view.addSubview(imageView)
        imageView.sd_setImageWithURL(self.smallURLList![index])
        // 如果是长图，限制大小
        if endFrame.height > UIScreen.mainScreen().bounds.height {
            imageView.bounds = UIScreen.mainScreen().bounds
            // 先拉伸小图，然后填充
            imageView.contentMode = UIViewContentMode.ScaleToFill
        }else{
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
        }
        imageView.clipsToBounds = true
        self.view.addSubview(imageView)
        // 转换坐标系
        let startFrame = view.convertRect(self.startFrameList![index], fromCoordinateSpace: UIScreen.mainScreen().fixedCoordinateSpace)
        // 计算对应的center位置
        let centerS = calculateCenterPointWithRect(startFrame)
        let centerE = calculateCenterPointWithRect(endFrame)
        
        // 开始动画
        UIView.animateWithDuration(AnimationDuration, animations: { () in
            // 获得需要回去的frame
            imageView.frame = startFrame
            // 为长图缩放小的比例做准备
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            }, completion: {(finish) -> Void in
                // 移除动画视图
                imageView.removeFromSuperview()
                // 发送结束动画通知
                NSNotificationCenter.defaultCenter().postNotificationName(PhotoBrowserEndDismissNotification, object: nil)
        })
    }
    // 交互式dismiss动画
    func interactiveDismissAnimation(n : NSNotification) {
        // 当前缩放比例
        let scale = n.userInfo!["scale"] as! CGFloat
        // 当前图片索引
        let index = (n.object as! NSNumber).integerValue
        
        // 动画图片视图
        let imageView = UIImageView()
        imageView.sd_setImageWithURL(smallURLList![index])
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        
        // 计算当前frame
        let endFrame = endFrameList![index]
        imageView.frame = CGRectMake(0, 0, endFrame.width * scale, endFrame.height * scale)
        imageView.center = CGPointMake(UIScreen.mainScreen().bounds.width * CGFloat(0.5), UIScreen.mainScreen().bounds.height * CGFloat(0.5))
        
        // 遮罩
        let backView = UIView(frame: UIScreen.mainScreen().bounds)
        backView.alpha = scale
        // 添加到视图
        view.addSubview(imageView)
        view.addSubview(backView)
        // 按比例计算剩余动画时长
        let duration = AnimationDuration * NSTimeInterval(scale)
        // 开始动画
        UIView.animateWithDuration(duration, animations: { () -> Void in
            imageView.frame = self.startFrameList![index]
            backView.alpha = 0
            }) { (_) -> Void in
                // 移除图片
                imageView.removeFromSuperview()
                backView.removeFromSuperview()
        }
    }
    // 根据给定的frame, 计算center坐标
    private func calculateCenterPointWithRect(rect : CGRect) -> CGPoint {
        let x = rect.origin.x + rect.width * 0.5
        let y = rect.origin.y + rect.height * 0.5
        return CGPointMake(x, y)
    }
}
//MARK: - UICollectionViewDataSource数据源方法
extension PhotoBrowserScanViewController : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoes.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reusedId, forIndexPath: indexPath) as! PhotoCell
        // 设置小图
        cell.url = smallURLList![indexPath.item]
        return cell
    }
}
//MARK: - UICollectionViewDelegate代理方法
extension PhotoBrowserScanViewController : UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // 计算当前点击时候的全部cell的frame
        calculateFrameLists()
        // 准备跳转的视图
        let modalVC = PhotoBrowserViewController()
        // 将图像数组传递
        modalVC.largeImageURLList = largeURLList
        modalVC.smallImageURLList = smallURLList
        modalVC.index = indexPath.item
        modalVC.startFrameList = startFrameList
        modalVC.endFrameList = endFrameList
        
        // 根据点击cell截取动画图片
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        var dummyView = cell.snapshotViewAfterScreenUpdates(false)
        // 设置遮罩view
        let backView = UIView(frame: self.view.bounds)
        backView.backgroundColor = UIColor.blackColor()
        backView.alpha = 0
        // 将遮罩添加到视图
        self.view.addSubview(backView)
        
        // 开始frame
        let startFrame = startFrameList![indexPath.item]
        let imageView = UIImageView(frame: startFrame)
        var endFrame = endFrameList![indexPath.item]
        imageView.sd_setImageWithURL(smallURLList![indexPath.item])
        if endFrame.height > UIScreen.mainScreen().bounds.height {
            // 拉伸小图，填充
            imageView.contentMode = UIViewContentMode.ScaleToFill
            endFrame = UIScreen.mainScreen().bounds
        }else{
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
        }
        imageView.clipsToBounds = true
        self.view.addSubview(imageView)
        // 准备跳转
        modalVC.view.alpha = 0
        mk_presentViewController(modalVC, withPresentFrame: UIScreen.mainScreen().bounds, withPresentAnimation: { (_) -> NSTimeInterval in
            return 0.0
            }, withDismissAnimation: { (_) -> NSTimeInterval in
                return 0.0
            }) { () -> Void in
                self.view.userInteractionEnabled = false
                UIView.animateWithDuration(self.AnimationDuration, animations: { () -> Void in
                    imageView.frame = endFrame
                    // 小图填充后显示最核心部分
                    imageView.contentMode = UIViewContentMode.ScaleAspectFill
                    backView.alpha = 1
                    }, completion: { (_) -> Void in
                        modalVC.view.alpha = 1
                        imageView.removeFromSuperview()
                        backView.removeFromSuperview()
                        self.view.userInteractionEnabled = true
                })
        }
    }
}

