//
//  PhotoBrowserScanViewController.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/24.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//
import UIKit
import SDWebImage
import SVProgressHUD

//MARK: - 常量列表
/// 通知列表
// 普通dismiss通知
private let PhotoBrowserStartDismissNotification = "PhotoBrowserStartDismissNotification"
private let PhotoBrowserEndDismissNotification = "PhotoBrowserEndDismissNotification"
// 交互式dismiss通知
private let PhotoBrowserStartInteractiveDismissNotification = "PhotoBrowserStartInteractiveDismissNotification"
/// 交互时颜色变化通知
private let PhotoBrowserDidScaleNotification = "PhotoBrowserDidScaleNotification"

///重用id
private let reuseIdentifier = "PhotoBrowserCellCell"
private let reusedId = "PhotoCell"

/// 触发dismiss的Scale大小
private let dismissScale : CGFloat = 1.0

/** 展示小图的控制器
    该视图通过封装collectionView来实现小图的展示，同时实现了很多动画方法用于变相实现了转场动画，
    内部主要通过自定义转场动画使得该视图保持不消失，然后根据接听不同事件的通知，做出对应的动画实现
    从而实现各种转场动画
    
    由于该控制器不止一个存在，所以只有被点击的控制器开启通知的监听，并且当回到该界面的时候取消监听通知
    以此保持只有对应需要产生动作的控制器做出对应的响应
*/
//MARK: - 展示小图的控制器
class PhotoBrowserScanViewController: UIViewController {
    //MARK: 属性
    /// 布局约束
    var layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    /// 图片视图
    lazy var collectionView: UICollectionView? = {
        let cv = UICollectionView(frame: UIScreen.mainScreen().bounds, collectionViewLayout: self.layout)
        cv.backgroundColor = UIColor.clearColor()
        cv.dataSource = self
        cv.delegate = self
        // 取消指示器
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        return cv
    }()
    /// 小图数组
    var smallURLList : [NSURL]? {
        didSet {
            // 计算自动布局
            calculateViewSize()
            collectionView?.reloadData()
        }
    }
    /// 大图数组
    var largeURLList : [NSURL]?
    /// 小图开始frame
    var startFrameList : [CGRect]?
    /// 展开后frame
    var endFrameList : [CGRect]?
    
    //MARK: - 可自定义属性
    /// 单张图片大小 如果没有给定该参数，单张图片显示的时候就按照layout的大小的2倍显示
    var singleImageSize : CGSize?
    /// 图片间距 默认为 10
    var imageMargin : CGFloat = 10.0
    /// 一行图片数目 默认是3
    var imageNumberInRow : Int = 3
    // 动画时长
    var AnimationDuration : NSTimeInterval = 0.3
    
    //MARK: - 布局约束
    /// 高度约束
    var collectionViewHeight : NSLayoutConstraint?
    /// 宽度约束
    var collectionViewWidth : NSLayoutConstraint?
    
    //MARK: - 系统方法
    override func loadView() {
        view = self.collectionView!
        // 添加约束
        addconstraints()
    }
    override func viewDidLoad() {
        // 注册cell
        collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: reusedId)
    }
    // 销毁通知
    deinit{
        removeNotification()
    }
    //MARK: - 功能方法
    // 销毁注册的通知
    private func removeNotification(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    private func setLayout(){
        layout.itemSize = CGSizeMake(90, 90)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
    }
    // 注册通知
    private func regiserNotification(){
        // 注册开始转场动画通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"normalDismiss:", name: PhotoBrowserStartDismissNotification, object: nil)
        // 注册结束转场动画通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"interactiveDismissAnimation:", name: PhotoBrowserStartInteractiveDismissNotification, object: nil)
        // // 注册通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didScale:", name: PhotoBrowserDidScaleNotification, object: nil)
    }
    // 添加约束
    private func addconstraints() {
        // 开启自动布局属性
        self.collectionView?.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        // 创建约束
        var cons = [AnyObject]()
        // 添加约束
        // 宽高约束
        collectionViewHeight = NSLayoutConstraint(item: collectionView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 0)
        collectionViewWidth = NSLayoutConstraint(item: self.collectionView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute:  NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 0)
        // 宽高约束添加
        cons.append(collectionViewHeight!)
        cons.append(collectionViewWidth!)
        self.view.addConstraints(cons)
    }
    // 计算framelist
    private func calculateFrameLists() {
        var startFrameList = [CGRect]()
        var endFrameList = [CGRect]()
        for i in 0..<(smallURLList?.count ?? 0) {
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
    // 计算view大小
    private func calculateViewSize(){
        // 还原最初布局
        setLayout()
        // 根据数组的数目
        let itemWidth = layout.itemSize.width
        let itemHeight = layout.itemSize.height
        // 无图
        if self.smallURLList == nil {
            collectionViewHeight?.constant = 0
            collectionViewWidth?.constant = 0
            return
        }
        // 一张图
        if self.smallURLList!.count == 1 {
            // 判断是否给定大小
            if singleImageSize == nil {
                let size = CGSizeMake(itemWidth * 2, itemHeight * 2)
                collectionViewHeight?.constant = size.height
                collectionViewWidth?.constant = size.width
                layout.itemSize = size
                // 清空singleImageSize属性 防止复用
                singleImageSize = nil
                return
            }
            // 有初始大小
            collectionViewHeight?.constant = singleImageSize!.height
            collectionViewWidth?.constant = singleImageSize!.width
            return
        }
        // 2张图片
        if self.smallURLList!.count == 2 {
            collectionViewHeight?.constant = itemHeight
            collectionViewWidth?.constant = itemWidth * 2 + imageMargin
            return
        }
        // 特殊张数图片
        if self.smallURLList!.count == ((imageNumberInRow - 1) * 2) {
            let number = CGFloat(imageNumberInRow - 1)
            let width = itemWidth * number + imageMargin
            let height = itemHeight * number + imageMargin
            collectionViewHeight?.constant = height
            collectionViewWidth?.constant = width
            return
        }
        //  其他图片数量
        let count = self.smallURLList!.count - 1
        let row = CGFloat(count / imageNumberInRow + 1)
        let width = itemWidth * CGFloat(imageNumberInRow) +  imageMargin * CGFloat(imageNumberInRow - 1)
        let height = itemHeight * row + imageMargin * (row - 1)
        collectionViewHeight?.constant = height
        collectionViewWidth?.constant = width
    }
    // 坐标转换
    private func cellStartFrameRelativeToMainScreen(cell : PhotoCell) ->CGRect {
        let frame = cell.convertRect(cell.bounds, toCoordinateSpace: UIScreen.mainScreen().fixedCoordinateSpace)
        return frame
    }
    // 根据cell 计算cell对于主屏幕的frame
    private func cellEndFrame(cell : PhotoCell) ->CGRect {
        let image = cell.imageView!.image!
        var size = scaleImageSize(image, relateToWidth: UIScreen.mainScreen().bounds.width)
        var y = (UIScreen.mainScreen().bounds.height - size.height) * 0.5
        if size.height > UIScreen.mainScreen().bounds.height {
            y = 0
        }
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
    //MARK: - 通知方法
    func didScale(n : NSNotification){
        let scale = n.userInfo!["scale"] as! CGFloat
        let index = n.userInfo!["index"] as! Int
        
        let indexPath = NSIndexPath(forItem: index, inSection: 0)
        let cell = self.collectionView!.cellForItemAtIndexPath(indexPath)! as UICollectionViewCell
        cell.hidden = scale < dismissScale
    }
    // 常规dismiss
    func normalDismiss(n : NSNotification) {
        // 根据通知得知正在看第几个图
        let index = n.userInfo!["index"] as! Int
        // 坐标
        let endFrame = endFrameList![index]
        let startFrame = startFrameList![index]
        // 动画
        dismissAnimation(startFrame, endFrame: endFrame, index: index, scale: 1)
    }
    // 交互式dismiss
    func interactiveDismissAnimation(n : NSNotification) {
        // 当前缩放比例
        let scale = n.userInfo!["scale"] as! CGFloat
        // 当前图片索引
        let index = n.userInfo!["index"] as! Int
        // 坐标
        let endFrame = endFrameList![index]
        let startFrame = startFrameList![index]
        // 动画
        dismissAnimation(startFrame, endFrame: endFrame, index: index, scale: scale)
    }
    
    //MARK: - 动画方法
    // dismiss动画方法
    private func dismissAnimation(startFrame: CGRect, endFrame: CGRect, index : Int, scale : CGFloat){
        // 获取当前cell
        let indexPath = NSIndexPath(forItem: index, inSection: 0)
        let cell = self.collectionView?.cellForItemAtIndexPath(indexPath)
        cell?.hidden = true
        
        // 创建图片展示正在回去的图片
        let imageView = UIImageView(frame: endFrame)
        imageView.clipsToBounds = true
        let url = self.smallURLList![index]
        imageView.sd_setImageWithURL(url)
        // 确定高度
        var height = endFrame.height * scale
        // 统一计算位置
        imageView.frame = CGRectMake(0, 0, endFrame.width * scale, height)
        imageView.center = CGPointMake(UIScreen.mainScreen().bounds.width * CGFloat(0.5), UIScreen.mainScreen().bounds.height * CGFloat(0.5))
        // 如果是长图，限制大小
        if endFrame.height > UIScreen.mainScreen().bounds.height {
            // 大小设定
            let width = endFrame.width * scale
            let x = (UIScreen.mainScreen().bounds.width - width) * 0.5
            let y = x
            height = UIScreen.mainScreen().bounds.height - y
            height = endFrame.height - y
            imageView.frame = CGRectMake(x, y, width, height)
        }
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        
        // 遮罩
        let backView = UIView(frame: UIScreen.mainScreen().bounds)
        backView.backgroundColor = UIColor.blackColor()
        backView.alpha = scale
        // 添加遮罩和图片
        UIApplication.sharedApplication().keyWindow?.addSubview(backView)
        UIApplication.sharedApplication().keyWindow?.addSubview(imageView)
        // 开始动画
        UIView.animateWithDuration(AnimationDuration, animations: { () in
            // 获得需要回去的frame
            imageView.frame = startFrame
            backView.alpha = 0
            }, completion: {(finish) -> Void in
                // 移除动画视图
                imageView.removeFromSuperview()
                backView.removeFromSuperview()
                // 发送结束动画通知
                NSNotificationCenter.defaultCenter().postNotificationName(PhotoBrowserEndDismissNotification, object: nil)
                // 结束监听通知
                self.removeNotification()
                cell?.hidden = false
        })
    }
    // 展示的动画
    private func presentAnimation(indexPath : NSIndexPath) {
        // 准备跳转的视图
        let modalVC = PhotoBrowserViewController()
        // 将图像数组传递
        modalVC.largeImageURLList = largeURLList
        modalVC.smallImageURLList = smallURLList
        modalVC.index = indexPath.item
        modalVC.startFrameList = startFrameList
        modalVC.endFrameList = endFrameList
        
        // 根据点击cell截取动画图片
        let cell = self.collectionView!.cellForItemAtIndexPath(indexPath) as! PhotoCell
        // 隐藏
        cell.hidden = true
        var dummyView = cell.snapshotViewAfterScreenUpdates(false)
        // 设置遮罩view
        let backView = UIView(frame: UIScreen.mainScreen().bounds)
        backView.backgroundColor = UIColor.blackColor()
        backView.alpha = 0
        
        
        // 开始frame
        let startFrame = startFrameList![indexPath.item]
        let imageView = UIImageView(frame: startFrame)
        var endFrame = endFrameList![indexPath.item]
        imageView.sd_setImageWithURL(smallURLList![indexPath.item])
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        // 将遮罩添加到window
        UIApplication.sharedApplication().keyWindow?.addSubview(backView)
        UIApplication.sharedApplication().keyWindow?.addSubview(imageView)
        // 准备跳转
        modalVC.view.alpha = 0
        // 设置跳转属性为自定义
        modalVC.modalPresentationStyle = UIModalPresentationStyle.Custom
        presentViewController(modalVC, animated: false){ () -> Void in
            UIView.animateWithDuration(self.AnimationDuration, animations: { () -> Void in
                imageView.frame = endFrame
                backView.alpha = 1
            }, completion: { (_) -> Void in
                modalVC.view.alpha = 1
                imageView.removeFromSuperview()
                backView.removeFromSuperview()
            if !(SDWebImageManager.sharedManager().cachedImageExistsForURL(modalVC.largeImageURLList![indexPath.item])) {
                    SVProgressHUD.show()
            }
                self.view.userInteractionEnabled = true
                cell.hidden = false
            })
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
        return self.smallURLList?.count ?? 0
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
        // 走之前注册通知
        regiserNotification()
        // 计算当前点击时候的全部cell的frame
        calculateFrameLists()
        // 进行动画跳转
        presentAnimation(indexPath)
    }
}

/** 单小图图展示Cell
    简单地小图展示Cell，主要展示小图，并且传递接受大图，小图的URL传递给需要展示的下面的控制器
*/
//MARK: - 单小图图展示Cell
class PhotoBrowserCell: UICollectionViewCell {
    //MARK: - 属性
    /// 查看照片控制器
    var viewerVC: SinglePhotoBrowserViewController?
    
    /// 要显示的图片的 URL
    var largeURL: NSURL? {
        didSet {
            viewerVC?.largeURL = largeURL
        }
    }
    /// 要显示的图片的小图 URL
    var smallURL: NSURL? {
        didSet {
            viewerVC?.smallURL = smallURL
        }
    }
    /// 要显示的图片的小图 URL
    var index: Int? {
        didSet {
            viewerVC?.index = index
        }
    }
    //MARK: - 构造方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 创建视图控制器
        viewerVC = SinglePhotoBrowserViewController()
        viewerVC?.view.frame = bounds
        // 添加视图
        self.addSubview(viewerVC!.view)
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//MARK: - 处理单张图片的控制器
class SinglePhotoBrowserViewController: UIViewController {
    //MARK: - 属性
    /// 滚动视图
    lazy var scrollView : UIScrollView = {
        let sv = UIScrollView(frame: UIScreen.mainScreen().bounds)
        // 设置代理
        sv.delegate = self
        // 最小大缩放比例
        sv.minimumZoomScale = 0.5
        sv.maximumZoomScale = 2.0
        return sv
        }()
    /// 图像视图
    lazy var imageView : UIImageView = {
        let iv = UIImageView()
        return iv
        }()
    var largeURL : NSURL? {
        didSet {
            // 清除原有的图片
            // 判断图片是否缓存
            if !(SDWebImageManager.sharedManager().cachedImageExistsForURL(largeURL)) {
                SDWebImageManager.sharedManager().downloadImageWithURL(smallURL, options: SDWebImageOptions(0), progress: nil, completed: { (image, error, _, _, _) -> Void in
                    self.imageView.image = image
                    self.setUpImage(image)
                })
            }
            SDWebImageManager.sharedManager().downloadImageWithURL(largeURL, options: SDWebImageOptions(0), progress: nil) { (image, error, _, _, _) -> Void in
                if error != nil {
                    SVProgressHUD.showErrorWithStatus("网络不给力")
                    SVProgressHUD.dismiss()
                    return
                }
                // 设置图片
                self.imageView.image = image
                self.setUpImage(image)
                SVProgressHUD.dismiss()
            }
        }
    }
    // 小图URL
    var smallURL : NSURL?
    // 当前索引
    var index : Int?
    
    //MARK: - 内部方法
    override func loadView() {
        view = UIView(frame: UIScreen.mainScreen().bounds)
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        // 设置SVProgressHUD
        setSVProgressHUD()
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        SVProgressHUD.dismiss()
    }
    //MARK: - 功能方法
    // 设置SVProgressHUD样式
    private func setSVProgressHUD(){
        SVProgressHUD.setBackgroundColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.5))
        SVProgressHUD.setForegroundColor(UIColor.whiteColor())
        SVProgressHUD.setRingThickness(8.0)
    }
    // 重置scrollView属性
    private func resetScrollView() {
        scrollView.contentSize = CGSizeZero
        scrollView.contentOffset = CGPointZero
        scrollView.contentInset = UIEdgeInsetsZero
        imageView.transform = CGAffineTransformIdentity
    }
    // 设置图片
    private func setUpImage(image : UIImage) {
        // 重置
        resetScrollView()
        // 缩放大小
        let size = scaleImageSize(image)
        // 设置属性
        self.imageView.frame = CGRectMake(0, 0, size.width, size.height)
        // 判断长短图
        var top : CGFloat
        if size.height > view.frame.height {
            // 长图
            top = 0
        } else {
            // 短图
            top = (view.frame.size.height - size.height) * 0.5
        }
        // 设置contentInset
        scrollView.contentSize = size
        scrollView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0)
    }
    // 计算图片缩放
    private func scaleImageSize(image : UIImage) -> CGSize {
        let imageW = image.size.width
        let imageH = image.size.height
        let screenW = UIScreen.mainScreen().bounds.width
        let scaleH = screenW * imageH / imageW
        return CGSizeMake(screenW, scaleH)
    }
    // 判断图片的缩放便宜
    private func calculateContentOffset() -> CGPoint{
        // 根据图像的目前大小计算需要偏移的contentOffset
        var offsety : CGFloat
        var offsetx : CGFloat
        // 判断图片的高度是否已经超出屏幕，超出屏幕按照默认的contentOffset
        if imageView.frame.height > UIScreen.mainScreen().bounds.height {
            offsety = scrollView.contentOffset.y //y值不变，直接保持即可
        }else{
            offsety = (imageView.frame.height - UIScreen.mainScreen().bounds.height) * CGFloat(0.5)
        }
        
        // 判断图片的宽度是否已经超出屏幕，超出屏幕按照默认的contentOffset
        if imageView.frame.width > UIScreen.mainScreen().bounds.width {
            offsetx = scrollView.contentOffset.x //y值不变，直接保持即可
        }else{
            offsetx = (imageView.frame.width - UIScreen.mainScreen().bounds.width) * CGFloat(0.5)
        }
        return CGPointMake(offsetx, offsety)
    }
}
//MARK: - UIScrollViewDelegate代理方法
extension SinglePhotoBrowserViewController : UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        let scale = imageView.transform.a
        // 根据偏移量保持图片中心对齐
        scrollView.contentOffset = calculateContentOffset()
        // 发送缩放通知
        NSNotificationCenter.defaultCenter().postNotificationName(PhotoBrowserDidScaleNotification, object: nil, userInfo: ["scale" : scale, "index" : index!])
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if imageView.transform.a < dismissScale {
            imageView.hidden = true
            scrollView.contentOffset = calculateContentOffset()
        }
    }
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        if scale < dismissScale {
            NSNotificationCenter.defaultCenter().postNotificationName(PhotoBrowserStartInteractiveDismissNotification, object: nil, userInfo: ["scale" : scale, "index" : index!])
            dismissViewControllerAnimated(false, completion: nil)
            return
        }
        // 重新调整图像的间距
        // 计算顶部的间距值
        let top = (scrollView.frame.height - view.frame.height) * 0.5
        if top > 0 {
            scrollView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0)
            return
        }
        // top < 0 说明图片放大的结果，已经超出了 scrollView
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }
}
//MARK: - 展示全部图片的控制器
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
    //MARK: - 监听方法
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
    //MARK: - 功能方法
    /// 所有注册的通知
    private func registerNotification(){
        // 注册通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didDismiss", name: PhotoBrowserEndDismissNotification, object: nil)
        // 注册通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didScale:", name: PhotoBrowserDidScaleNotification, object: nil)
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
//MARK: - PhotoBrowserViewController的数据源方法
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

//MARK: - 展示单张图片的cell
class PhotoCell: UICollectionViewCell {
    //MARK: - 属性
    /// 展示图像视图
    lazy var imageView : UIImageView? = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        return imageView
        }()
    /// 图像地址
    var url : NSURL? {
        didSet {
            imageView!.sd_setImageWithURL(url)
        }
    }
    // 功能方法
    // 判断长短图
    private func isLongImage(image : UIImage) -> Bool{
        let size = scaleImageSize(image, relateToWidth: UIScreen.mainScreen().bounds.width)
        if size.height > UIScreen.mainScreen().bounds.height {
            return true
        }
        return false
    }
    // 计算图片缩放根据给定的宽度
    private func scaleImageSize(image : UIImage, relateToWidth width: CGFloat) -> CGSize {
        let imageW = image.size.width
        let imageH = image.size.height
        let scaleH = width * imageH / imageW
        return CGSizeMake(width, scaleH)
    }
    //MARK: - 内部方法
    // 布局内部图像视图
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame = self.bounds
    }
}