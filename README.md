#PhotoBrowser
###一个用于展示多张图片的视图控制器，通过添加类似于collectionViewController的控制器进入到自己的项目所需要的位置，即可实现多图小图展示，点击小图进入大图浏览视图，可以支持一下特点：
1.	封装了cell放大到全屏的动画
	*	被点击cell隐藏
	* 	需显示cell隐藏
2. 支持捏合缩回功能
	*	实时矫正scrollView捏合时向左上角偏移问题
	*	捏合消失功能
3. 支持保存到相册功能
4. 在SDWebImage的基础上更加细节的处理了在各种情况下显示图片的问题
5. 图片下载进度展示
6.	多种内部实现可以外部通过实现代理方法修改

#效果展示
![效果演示](http://img.blog.csdn.net/20150601001422771)
##使用步骤
###添加框架
由于框架内部使用了SDWebImage，所以看自己的项目内部是否添加了该框架，如果没添加，须添加该框架先。

添加完毕之后，下载该展示项目，下载完成之后内部有一个Framework文件夹，将该文件夹拖入自己的项目中，记住一定要拷贝进去。

###项目内部使用展示：
在需要用到该视图的具体位置根据实际情况添加该视图控制器

``` swift
    // 测试数组
    override func awakeFromNib() {
        super.awakeFromNib()
        // 添加控制器
        let photoVC = PhotoBrowserController()
        // 一般不需要设置，如有需要的其他属性改变，可以实现特定的代理方法
        photoVC.delegate = self
        // 记录控制器
        self.photoVC = photoVC
        // 添加视图
        photoView = photoVC.view
        self.contentView.addSubview(photoView!)
        // 添加约束
        addConstraint()
        // 添加只有一张图片的时候的大小,该示例未赋值该属性
        photoVC.singleImageSize = singleImageSize
    }
    
    // 添加约束，须手动添加约束，内部长宽属性已经被设置好了，会根据具体图片数目做出判断
    private func addConstraint(){
        var cons = [AnyObject]()
        // 位置约束
        cons.append(NSLayoutConstraint(item: self.photoView!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.titleLabel, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 10))
        cons.append(NSLayoutConstraint(item: self.photoView!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.titleLabel, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        self.contentView.addConstraints(cons)
    }
```

###可以额外修改的属性代理协议方法
####全部属性都有默认值，如果和默认值不符，可以自行调整


```swift
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

```
###注意事项
外部在使用该视图控制器的时候一定要记住记录下该控制器进入到自控制器数组中

``` swift
if !(childViewControllers as NSArray).containsObject(cell.photoVC!) {
	addChildViewController(cell.photoVC!)
}
```
如果不做该处理，会在不经意地时候产生一些很神奇的BUG，原因就是响应者链条断了



