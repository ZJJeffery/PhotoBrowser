//
//  PhotoBrowser.swift
//
//
//  Created by Jiajun Zheng on 15/5/24.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//
import UIKit
import SDWebImage

//MARK: - PhotoBrowser代理协议
@objc protocol PhotoBrowserControllerDelegate: NSObjectProtocol {
    
    /// 设置小图与小图之间的间距大小 默认是10.0
    optional func PhotoBrowerControllerSetImageMargin(photoBrowserController:PhotoBrowserController) -> CGFloat
    
    /// 设置一行放多少个小图 默认是3.0
    optional func PhotoBrowerControllerSetImageNumberInRow(photoBrowserController:PhotoBrowserController) -> Int
    
    /// 设置点击小图时的动画时长，默认是0.3秒
    optional func PhotoBrowerControllerSetAnimationDuration(photoBrowserController:PhotoBrowserController) -> NSTimeInterval
    
    /// 设置多个小图时候每个小图的大小
    optional func PhotoBrowerControllerSetItemSize(photoBrowserController:PhotoBrowserController) -> CGSize
    
    /// 设置占位图的资源,有默认图
    optional func PhotoBrowerControllerSetPlaceHolder(photoBrowserController:PhotoBrowserController) -> UIImage
    
    /// 设置交互式消失时候出发的图片比例大小 默认是1.0
    optional func PhotoBrowerControllerSetDismissScaleNumber(photoBrowserController:PhotoBrowserController) -> CGFloat
    
    /// 下载指示器线的宽度
    optional func PhotoBrowerControllerSetActivityLineWidth(photoBrowserController:PhotoBrowserController) -> CGFloat
    
    /// 下载指示器背景颜色
    optional func PhotoBrowerControllerSetActivityBackgroundColor(photoBrowserController:PhotoBrowserController) -> UIColor
    
    /// 下载指示器颜色
    optional func PhotoBrowerControllerSetActivityLineColor(photoBrowserController:PhotoBrowserController) -> UIColor
    
    /// 是否需要保存按钮 默认需要
    optional func PhotoBrowerControllerWhetherNeedSaveButton(photoBrowserController:PhotoBrowserController) -> Bool
    
}
/** 展示小图的控制器
    该视图通过封装collectionView来实现小图的展示，同时实现了很多动画方法用于变相实现了转场动画，
    内部主要通过自定义转场动画使得该视图保持不消失，然后根据接听不同事件的通知，做出对应的动画实现
    从而实现各种转场动画
    
    由于该控制器不止一个存在，所以只有被点击的控制器开启通知的监听，并且当回到该界面的时候取消监听通知
    以此保持只有对应需要产生动作的控制器做出对应的响应
*/
//MARK: - 展示小图的控制器
class PhotoBrowserController: UIViewController {
    //MARK: - 可自定义属性
    weak var delegate : PhotoBrowserControllerDelegate?
    /// 单张图片大小 如果没有给定该参数，单张图片显示的时候就按照layout的大小的2倍显示
    var singleImageSize : CGSize?
    /// 图片间距 默认为 10
    private var imageMargin : CGFloat = 10.0
    /// 一行图片数目 默认是3
    private var imageNumberInRow : Int = 3
    // 动画时长
    private var animationDuration : NSTimeInterval = 0.3
    /// itemSize
    private var itemSize : CGSize = CGSizeMake(90, 90)
    
    //MARK: 其他属性
    /// 布局约束
    var layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    /// 图片视图
    lazy var collectionView: UICollectionView? = {
        let cv = UICollectionView(frame: CGRectZero, collectionViewLayout: self.layout)
        cv.backgroundColor = UIColor.clearColor()
        cv.dataSource = self
        cv.delegate = self
        // 取消指示器
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        return cv
    }()
    /// URL元祖接收外界需要展示的数据
    var URLList : (smallURLList : [NSURL]?, largeURLList : [NSURL]?) {
        didSet {
            // 如果大小图长度不同，不继续
            assert(URLList.smallURLList?.count ?? 0 == URLList.largeURLList?.count ?? 0, "大小图URL数组长度必须相同！")
            // 根据数据转换成模型数组
            photoes = Photo.photoes(URLList.smallURLList!, largeURLList: URLList.largeURLList!)
            // 计算自动布局
            calculateViewSize()
            collectionView?.reloadData()
        }
    }
    // 图片模型数组
    var photoes : [Photo]?
    /// 小图开始frame
    var startFrameList : [CGRect]?
    /// 展开后frame
    var endFrameList : [CGRect]?
    
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
    // 设置属性
    private func setInfo(){
        if delegate == nil{
            return
        }
        /// 图片间距 默认为 10
        if let result = self.delegate!.PhotoBrowerControllerSetImageMargin?(self) {
            imageMargin = result
        }
        /// 一行图片数目 默认是3
        if let result = self.delegate!.PhotoBrowerControllerSetImageNumberInRow?(self) {
            imageNumberInRow = result
        }
        // 动画时长
        if let result = self.delegate!.PhotoBrowerControllerSetAnimationDuration?(self) {
            animationDuration = result
        }
        /// itemSize
        if let result = self.delegate!.PhotoBrowerControllerSetItemSize?(self) {
            itemSize = result
        }
        /// 图片占位图
        if let result = self.delegate!.PhotoBrowerControllerSetPlaceHolder?(self) {
            placeHolderImage = result
        }
        /// 缩放触发动画的比例
        if let result = self.delegate!.PhotoBrowerControllerSetDismissScaleNumber?(self) {
            dismissScale = result
        }
        /// 线条宽度
        if let result = self.delegate!.PhotoBrowerControllerSetActivityLineWidth?(self){
            activityLineWidth = result
        }
        /// 线条颜色
        if let result = self.delegate!.PhotoBrowerControllerSetActivityLineColor?(self){
            activityLineColor = result
        }
        /// 指示器背景颜色
        if let result = self.delegate!.PhotoBrowerControllerSetActivityBackgroundColor?(self){
            activityBackgroundColor = result
        }
        /// 是否需要保存功能
        if let result = self.delegate!.PhotoBrowerControllerWhetherNeedSaveButton?(self){
            needSaveButton = result
        }
    }
    // 销毁注册的通知
    private func removeNotification(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    private func setLayout(){
        layout.itemSize = itemSize
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
        collectionView?.setTranslatesAutoresizingMaskIntoConstraints(false)
        // 创建约束
        var cons = [AnyObject]()
        // 添加约束
        // 宽高约束
        collectionViewHeight = NSLayoutConstraint(item: collectionView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 0)
        collectionViewWidth = NSLayoutConstraint(item: self.collectionView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute:  NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 0)
        // 宽高约束添加
        cons.append(collectionViewHeight!)
        cons.append(collectionViewWidth!)
        collectionView!.addConstraints(cons)
    }
    // 计算framelist
    private func calculateFrameLists() {
        var startFrameList = [CGRect]()
        var endFrameList = [CGRect]()
        for i in 0..<(photoes?.count ?? 0) {
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
        // 无图 根据外部情况可能传空，可能不传
        if photoes == nil || photoes?.count == 0 {
            collectionViewHeight?.constant = 0
            collectionViewWidth?.constant = 0
            return
        }
        // 一张图
        if self.photoes!.count == 1 {
            // 判断是否给定大小
            if singleImageSize == nil || singleImageSize == CGSizeMake(0, 0){
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
        if self.photoes!.count == 2 {
            collectionViewHeight?.constant = itemHeight
            collectionViewWidth?.constant = itemWidth * 2 + imageMargin
            return
        }
        // 特殊张数图片
        if self.photoes!.count == ((imageNumberInRow - 1) * 2) {
            let number = CGFloat(imageNumberInRow - 1)
            let width = itemWidth * number + imageMargin
            let height = itemHeight * number + imageMargin
            collectionViewHeight?.constant = height
            collectionViewWidth?.constant = width
            return
        }
        //  其他图片数量
        let count = self.photoes!.count - 1
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
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        let photo = self.photoes![index]
        let url = photo.smallURL
        imageView.sd_setImageWithURL(url, placeholderImage: placeHolderImage)
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
        
        // 遮罩
        let backView = UIView(frame: UIScreen.mainScreen().bounds)
        backView.backgroundColor = UIColor.blackColor()
        backView.alpha = scale < dismissScale ? 0 : 1
        // 添加遮罩和图片
        UIApplication.sharedApplication().keyWindow?.addSubview(backView)
        UIApplication.sharedApplication().keyWindow?.addSubview(imageView)
        // 开始动画
        UIView.animateWithDuration(animationDuration, animations: { () in
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
        modalVC.photoes = self.photoes
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
        let photo = self.photoes![indexPath.item]
        let url = photo.smallURL
        imageView.sd_setImageWithURL(url, placeholderImage: placeHolderImage)
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        // 将遮罩添加到window
        UIApplication.sharedApplication().keyWindow?.addSubview(backView)
        UIApplication.sharedApplication().keyWindow?.addSubview(imageView)
        // 准备跳转
        modalVC.view.alpha = 0
        // 设置跳转属性为自定义
        modalVC.modalPresentationStyle = UIModalPresentationStyle.Custom
//        SVProgressHUD.dismiss()
        presentViewController(modalVC, animated: false){ () -> Void in
            UIView.animateWithDuration(self.animationDuration, animations: { () -> Void in
                imageView.frame = endFrame
                backView.alpha = 1
            }, completion: { (_) -> Void in
                modalVC.view.alpha = 1
                imageView.removeFromSuperview()
                backView.removeFromSuperview()
                let photo = self.photoes![indexPath.item]
                let url = photo.largeURL
                self.view.userInteractionEnabled = true
                cell.hidden = false
            })
        }

    }
}
//MARK: - UICollectionViewDataSource数据源方法
extension PhotoBrowserController : UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoes?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reusedId, forIndexPath: indexPath) as! PhotoCell
        // 设置小图
        let photo = self.photoes![indexPath.item]
        let url = photo.smallURL
        cell.url = url
        return cell
    }
}
//MARK: - UICollectionViewDelegate代理方法
extension PhotoBrowserController : UICollectionViewDelegate {
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
//MARK: - 展示单张小图图片的cell
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
            imageView!.sd_setImageWithURL(url, placeholderImage: placeHolderImage)
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
/** 展示全部图片的控制器
    通过小图和大图数组，可以动态展示所有的图片，同时根据接受的通知，改变自己的背景图片的alpha值，从而产生交互式转场的效果。
*/
//MARK: - 展示全部图片的控制器
class PhotoBrowserViewController: UIViewController {
    //MARK: - 属性
    /// 模型数组
    var photoes : [Photo]?
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
        cv.delegate = self
        // 设置其他属性
        cv.pagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        return cv
        }()
    /// 关闭按钮
    lazy var closeBtn : UIButton = {
        return self.createButton("关闭")
        }()
    /// 保存按钮
    lazy var saveBtn : UIButton = {
        return self.createButton("保存")
    }()
    /// 保存按钮的提示视图
    lazy var statusView: UILabel = {
        let label = UILabel(frame: CGRectMake(0, 0, 90, 60))
        label.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        label.textColor = UIColor.whiteColor()
        label.center = self.view.center
        label.textAlignment = NSTextAlignment.Center
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        return label
    }()
    
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
        cons += NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[closeBtn(60)]-10-[saveBtn(60)]", options: NSLayoutFormatOptions(0), metrics: nil, views: ["closeBtn" : closeBtn, "saveBtn" : saveBtn])
        
        cons += NSLayoutConstraint.constraintsWithVisualFormat("V:[closeBtn]-20-|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["closeBtn" : closeBtn])
        
        cons += NSLayoutConstraint.constraintsWithVisualFormat("V:[saveBtn]-20-|", options: NSLayoutFormatOptions(0), metrics: nil, views: ["saveBtn" : saveBtn])
        // 添加约束
        view.addConstraints(cons)
        // 判断是否需要save按钮
        saveBtn.hidden = !needSaveButton
        // 监听方法
        closeBtn.addTarget(self, action: "close", forControlEvents: UIControlEvents.TouchUpInside)
        saveBtn.addTarget(self, action: "save", forControlEvents: UIControlEvents.TouchUpInside)
    }
    override func viewDidLoad() {
        // 注册cell
        collectionView.registerClass(PhotoBrowserCell.self, forCellWithReuseIdentifier: reuseIdBrowser)
        // 注册通知
        registerNotification()
    }
    override func viewDidLayoutSubviews() {
        let indexPath = NSIndexPath(forItem: index!, inSection: 0)
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.allZeros, animated: false)
    }
    override func viewDidAppear(animated: Bool) {
        // 手动先检查保存按钮是否可以开启
        checkSaveBtn()
    }
    // 销毁通知
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    //MARK: - 监听方法
    /// 关闭视图
    func close() {
        // 确定关闭的图像索引
        let indexPath = collectionView.indexPathsForVisibleItems().last as! NSIndexPath
        let index = indexPath.item
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        self.view.alpha = 0
        // 发送开始关闭通知
        NSNotificationCenter.defaultCenter().postNotificationName(PhotoBrowserStartDismissNotification, object: nil, userInfo: ["index": index])
    }
    /// save
    func save(){
        // 判断是否需要进行保存
        // 根据索引计算当前浏览的图片
        var index = calculateIndex()
        let photo = self.photoes![index]
        // 获取具体图片，因为能点击肯定已经得到大图
        let image = SDWebImageManager.sharedManager().imageCache.imageFromDiskCacheForKey(photo.largeURL.absoluteString)
        // 存入相册
        UIImageWriteToSavedPhotosAlbum(image, self, "image:didFinishSavingWithError:contextInfo:", nil)
    }
    /// 图像保存的回调方法
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject){
        if error != nil {
            // 展示失败
            self.view.addSubview(self.statusView)
            self.statusView.text = "保存失败"
            // 展示动画
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.statusView.alpha = 1
                }) { (_) -> Void in
                    UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.allZeros, animations: { () -> Void in
                        self.statusView.alpha = 0
                        }, completion: { (_) -> Void in
                            self.statusView.removeFromSuperview()
                            self.statusView.alpha = 1
                    })
            }
            return
        }
        // 展示成功
        var index = calculateIndex()
        let photo = self.photoes![index]
        photo.isSaved = true
        checkSaveBtn()
        self.statusView.alpha = 0
        self.view.addSubview(self.statusView)
        self.statusView.text = "保存成功"
        
        // 展示动画
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.statusView.alpha = 1
        }) { (_) -> Void in
            UIView.animateWithDuration(0.5, delay: 0.5, options: UIViewAnimationOptions.allZeros, animations: { () -> Void in
                self.statusView.alpha = 0
            }, completion: { (_) -> Void in
                self.statusView.removeFromSuperview()
                self.statusView.alpha = 1
            })
        }
        
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
        // 注册通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "checkSaveBtn", name: SaveBtnEnableNotification, object: nil)
    }
    /// 创建按钮
    private func createButton(title: String) -> UIButton {
        let btn = UIButton()
        btn.setTitle(title, forState: UIControlState.Normal)
        btn.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        btn.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        btn.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        view.addSubview(btn)
        // 设置自动布局须关闭
        btn.setTranslatesAutoresizingMaskIntoConstraints(false)
        return btn
    }
    /// 开始缩放的通知方法
    func didScale(noti : NSNotification){
        let scale = noti.userInfo!["scale"] as! CGFloat
        let index = noti.userInfo!["index"] as! Int
        let photo = photoes![index]
        // 隐藏关闭按钮
        closeBtn.hidden = scale < dismissScale
        // 如果不需要保存按钮，会一直隐藏
        saveBtn.hidden = scale < dismissScale || !needSaveButton || photo.isSaved
        collectionView.backgroundView?.alpha = scale
    }
    /// 检查按钮
    func checkSaveBtn() {
        self.scrollViewDidScroll(self.collectionView)
    }
    /// 根据contentOffset 计算哪个cell 正在显示
    func calculateIndex() -> Int{
        let sWidth = UIScreen.mainScreen().bounds.width
        let offset = collectionView.contentOffset.x
        let index = Int((offset + (sWidth * CGFloat(0.5))) / sWidth)
        // 防止索引越界
        if index < 0 {
            return 0
        }
        if index > self.photoes?.count {
            return self.photoes!.count - 1 
        }
        return index
    }
}
//MARK: - PhotoBrowserViewController的数据源方法
extension PhotoBrowserViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoes?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdBrowser, forIndexPath: indexPath) as! PhotoBrowserCell
        // 添加子控制器
        if !(childViewControllers as NSArray).containsObject(cell.viewerVC!) {
            addChildViewController(cell.viewerVC!)
        }
        // 设置图片URL
        cell.photo = photoes![indexPath.item]
        // 传递当前索引
        cell.index = indexPath.item
        return cell
    }
}
//MARK: - PhotoBrowserViewController的代理方法
extension PhotoBrowserViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let index = calculateIndex()
        let photo = self.photoes![index]
        saveBtn.enabled = SDWebImageManager.sharedManager().cachedImageExistsForURL(photo.largeURL)
        saveBtn.hidden = photo.isSaved
    }
    
}
/** 单大图图展示Cell
    通过传递单图处理的控制器，其他的实现都是通过控制器内部实现，cell只是起到了重用和组织的作用
*/
//MARK: - 单大图图展示Cell
class PhotoBrowserCell: UICollectionViewCell {
    //MARK: - 属性
    /// 查看照片控制器
    var viewerVC: SinglePhotoBrowserViewController?
    
    /// 图片模型数组
    var photo : Photo? {
        didSet {
            viewerVC?.photo = photo
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

/** 处理单张图片的控制器
    内部通过scrollView实现大小图放大缩小，当放大缩小的时候，处理了contentOffset的偏移实现了中心对齐
    根据不同的比例缩放，发送不同的通知，根据scale的通知，让父视图的背景色改变实现透明穿透的交互式转场效果
    
    当图片缩放之后，需要自己手动从新回到初始的tranform，不然哪怕图片看着没变大，内部的imageView
    的大小依旧是原来的大小。
*/

//MARK: - 处理单张图片的控制器
class SinglePhotoBrowserViewController: UIViewController {
    //MARK: - 属性
    /// 图片模型
    var photo : Photo? {
        didSet {
            smallURL = photo?.smallURL
            largeURL = photo?.largeURL
        }
    }
    private lazy var activity : ActivityView = {
        let activity = ActivityView(frame: CGRectMake(0, 0, 44, 44))
        activity.layer.cornerRadius = 22
        activity.layer.masksToBounds = true
        activity.backgroundColor = activityBackgroundColor
        activity.lineWidth = activityLineWidth
        activity.lineColor = activityLineColor
        activity.center = CGPointMake(UIScreen.mainScreen().bounds.width * 0.5, UIScreen.mainScreen().bounds.height * 0.5)
        
        self.view.addSubview(activity)
        return activity
    }()
    /// 滚动视图
    private lazy var scrollView : UIScrollView = {
        let sv = UIScrollView(frame: UIScreen.mainScreen().bounds)
        // 设置代理
        sv.delegate = self
        // 最小大缩放比例
        sv.minimumZoomScale = 0.5
        sv.maximumZoomScale = 2.0
        return sv
        }()
    /// 图像视图
    private lazy var imageView : UIImageView = {
        let iv = UIImageView()
        return iv
        }()
    var largeURL : NSURL? {
        didSet {
            // 清除原有的图片
            imageView.image = nil
            // 能否拿拿得到小图
            if let smallImage = SDWebImageManager.sharedManager().imageCache.imageFromDiskCacheForKey(smallURL?.absoluteString) {
                // 先小图显示
                self.imageView.image = smallImage
                self.setUpImage(smallImage)
                // 显示指示器
                self.activity.hidden = false
                // 下载大图
                SDWebImageManager.sharedManager().downloadImageWithURL(largeURL, options: SDWebImageOptions.allZeros, progress: { (finished, total) -> Void in
                    // 进度追踪
                    let progress = Double(finished) / Double(total) + 0.01
                    self.activity.progress = progress
                    
                    }, completed: { (image, error, _, _, _) -> Void in
                    if image != nil {
                        // 下载完毕隐藏进度
                        self.activity.hidden = true
                        self.imageView.image = image
                        self.setUpImage(image)
                        // 大图下载完毕，告诉上一级可以启用保存按钮
                        NSNotificationCenter.defaultCenter().postNotificationName(SaveBtnEnableNotification, object: nil)
                        return
                    }
                    //如果大图出错，打印错误显示不给力
                    self.imageView.image = smallImage
                    self.setUpImage(smallImage)
                    println("largeURL: \(self.largeURL) loadError: \(error)")
                })
                return
            }
            // 小图都拿不到
            imageView.image = placeHolderImage
            setUpImage(placeHolderImage)
        }
    }
    // 小图URL
    private var smallURL : NSURL?
    // 当前索引
    private var index : Int?
    
    //MARK: - 内部方法
    override func loadView() {
        view = UIView(frame: UIScreen.mainScreen().bounds)
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
    }
    //MARK: - 功能方法
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
//MARK: - 处理图片的模型
class Photo: NSObject {
    //MARK: - 属性
    // 小图地址
    var smallURL: NSURL
    // 大图地址
    var largeURL: NSURL
    // 判断是否已经保存
    var isSaved : Bool = false
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
//MARK: - 下载进度指示器
class ActivityView: UIView {
    //MARK: - 属性
    // 进度
    var progress  = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    // 线长度
    var lineWidth : CGFloat = 5.0
    // 线颜色
    var lineColor : UIColor = UIColor.whiteColor()
    
    override func drawRect(rect: CGRect) {
        // Drawing code
        let size = rect.size
        let centerPoint = CGPointMake(size.width * 0.5, size.height * 0.5)
        let r = CGFloat((min(size.width, size.height) - lineWidth - 8.0) * 0.5)
        let start = CGFloat(-M_PI_2)
        let end = CGFloat(2 * M_PI * progress + Double(start))
        
        let path = UIBezierPath(arcCenter: centerPoint, radius: r, startAngle: start, endAngle: end, clockwise: true)
        
        path.lineWidth = lineWidth
        path.lineCapStyle = kCGLineCapRound
        
        lineColor.setStroke()
        
        path.stroke()
        
    }
}
//MARK: - 常量列表
/// 通知列表
// 普通dismiss通知
private let PhotoBrowserStartDismissNotification = "PhotoBrowserStartDismissNotification"
private let PhotoBrowserEndDismissNotification = "PhotoBrowserEndDismissNotification"
// 交互式dismiss通知
private let PhotoBrowserStartInteractiveDismissNotification = "PhotoBrowserStartInteractiveDismissNotification"
/// 交互时颜色变化通知
private let PhotoBrowserDidScaleNotification = "PhotoBrowserDidScaleNotification"
/// 大图下载完成启用保存按钮的通知
private let SaveBtnEnableNotification = "SaveBtnEnableNotification"
///重用id
private let reuseIdBrowser = "PhotoBrowserCell"
private let reusedId = "PhotoCell"

/// 触发dismiss的Scale大小
private var dismissScale : CGFloat = 1.0
/// 图片占位图
private var placeHolderImage : UIImage = {
    let bundle = NSBundle(forClass: PhotoBrowserController.self)
    let url = bundle.URLForResource("image", withExtension: "bundle")!
    let imageBundle = NSBundle(URL: url)!
    let path = imageBundle.pathForResource("placeHolder", ofType: "png")
    return UIImage(contentsOfFile: path!)!
}()
/// 图片下载指示器属性
private var activityLineWidth : CGFloat = 5.0
private var activityLineColor = UIColor.whiteColor()
private var activityBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
/// 是否需要保存功能
private var needSaveButton = true