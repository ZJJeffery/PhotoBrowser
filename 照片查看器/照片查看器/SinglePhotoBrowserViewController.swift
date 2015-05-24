//
//  SinglePhotoBrowserViewController.swift
//  照片查看器
//
//  Created by Jiajun Zheng on 15/5/21.
//  Copyright (c) 2015年 hgProject. All rights reserved.
//

import UIKit
import SDWebImage
import SVProgressHUD

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
//            // 清除原有的图片
//            imageView.image = nil
            // 判断图片是否缓存
            if !(SDWebImageManager.sharedManager().cachedImageExistsForURL(largeURL)) {
                SDWebImageManager.sharedManager().downloadImageWithURL(smallURL, options: SDWebImageOptions(0), progress: nil, completed: { (image, error, _, _, _) -> Void in
                    self.imageView.image = image
                    self.setUpImage(image)
                })
                SVProgressHUD.show()
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
    //MARK: - 代理方法
extension SinglePhotoBrowserViewController : UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        imageView.layer.anchorPoint = CGPointMake(0.5, 0.5)
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        let scale = imageView.transform.a
        // 根据偏移量保持图片中心对齐
        scrollView.contentOffset = calculateContentOffset()
        NSNotificationCenter.defaultCenter().postNotificationName(PhotoBrowserDidScaleNotification, object: nil, userInfo: ["scale" : scale])
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        
        if scale < 1.0 {
            let bounds = imageView.bounds
            NSNotificationCenter.defaultCenter().postNotificationName(PhotoBrowserStartInteractiveDismissNotification, object: NSNumber(integer: index!), userInfo: ["scale" : scale])
            dismissViewControllerAnimated(true, completion: nil)
        }else{
            // 重新调整图像的间距
            // 计算顶部的间距值
            let top = (scrollView.frame.height - view.frame.height) * 0.5
            if top > 0 {
                scrollView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0)
            } else {
                // top < 0 说明图片放大的结果，已经超出了 scrollView
                scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
        }
    }
}


