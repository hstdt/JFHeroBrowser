//
//  HeroBrowser.swift
//  Example
//
//  Created by 逸风 on 2021/8/7.
//

import UIKit
import Combine

@objc public protocol HeroBrowserDataSource: AnyObject {
    @objc func viewForHeader() -> UIView?
    @objc func viewForFooter() -> UIView?
}

public protocol HeroBrowserDelegate: AnyObject {
    func heroBrowser(_ heroBrowser: HeroBrowser, didLongPressHandle viewModule: HeroBrowserViewModuleBaseProtocol)
}

extension HeroBrowserDelegate {
    func heroBrowser(_ heroBrowser: HeroBrowser, didLongPressHandle viewModule: HeroBrowserViewModuleBaseProtocol) {}
}

@MainActor
public class HeroBrowserObservation: ObservableObject {

    @Published public fileprivate(set) var _viewModules: [HeroBrowserViewModuleBaseProtocol]
    @Published public var currentPage: Int = 0

    let initialIndex: Int
    let config: JFHeroBrowserGlobalConfig
    public init(viewModules: [HeroBrowserViewModuleBaseProtocol],
                index: Int = 0,
                config: JFHeroBrowserGlobalConfig = .default) {
        self._viewModules = viewModules
        self.initialIndex = index
        self.currentPage = index
        self.config = config
    }
}

open class HeroBrowser: UIViewController {

    public typealias HeroBrowserDidLongPressHandle = (_ heroBrowser: HeroBrowser, _ viewModule: HeroBrowserViewModuleBaseProtocol) -> Void
    public typealias HeroBrowserWillDismissHandle = (_ currentIndex: Int, _ viewModule: HeroBrowserViewModuleBaseProtocol) -> Void
    public typealias HeroBrowserDidDismissHandle = (_ currentIndex: Int, _ viewModule: HeroBrowserViewModuleBaseProtocol) -> Void

    public var heroBrowserDidLongPressHandle: HeroBrowserDidLongPressHandle?
    public var willDismissHandle: HeroBrowserWillDismissHandle?
    public var didDismissHandle: HeroBrowserDidDismissHandle?

    public let store: HeroBrowserObservation

    lazy var effect = { UIBlurEffect(style: .dark) }()
    var blurEffectView: UIVisualEffectView?
    lazy var blurView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.panGestureRecognizer.delaysTouchesBegan = true // 避免视频播放按钮对手势的干扰
        view.showsHorizontalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()

    var animationType: HeroTransitionAnimationType = .hero

    public weak var dataSource: HeroBrowserDataSource?
    public weak var delegate: HeroBrowserDelegate?

    public weak var headerView: UIView?
    public weak var footerView: UIView?
    private var _isHideOther: Bool = false
    var isHideOther: Bool {
        get { _isHideOther }
        set {
            guard _isHideOther != newValue else { return }
            _isHideOther = newValue
            let alpha: CGFloat = newValue ? 0 : 1
            UIView.animate(withDuration: 0.25) {
                self.headerView?.alpha = alpha
                self.footerView?.alpha = alpha
            }
        }
    }
    weak var transitionContext: UIViewControllerAnimatedTransitioning?

    var _viewModules: [HeroBrowserViewModuleBaseProtocol]? {
        store._viewModules
    }

    var config: JFHeroBrowserGlobalConfig {
        store.config
    }

    var isShow = false
    var _scrolling: Bool = false
    var currentIndex: Int {
        let width = bounds.size.width
        guard width > 0 else { return 0 }
        let index = Int(self.collectionView.contentOffset.x / width)
        let count = _viewModules?.count ?? 0
        return index < count ? index : count
    }

    var bounds: CGRect {
        self.view.window?.frame ?? .zero // 某些分屏情况下self.view.frame不正确
    }

    public typealias ImagePageDidChangeHandle = (_ imageIndex: Int) -> UIImageView?
    public var imagePageDidChangeHandle: ImagePageDidChangeHandle?
    var heroImageView: UIImageView?
    var heroFrame: CGRect = .zero
    var heroImage: UIImage?
    var heroContentMode: UIView.ContentMode = .scaleAspectFill

    private lazy var pageControlContainer: PageControlContainer = {
        var view = PageControlContainer(store: store, frame: CGRect(x: 0, y: 0, width: 250, height: 20))
        view.didChangePageHandle = { [weak self] pageControl in
            self?.changePage(pageControl: pageControl)
        }
        self.view.addSubview(view)
        view.backgroundColor = .clear
        return view
    }()

    deinit {
        print("HeroBrowser deinit")
    }

    public convenience init(
        viewModules: [HeroBrowserViewModuleBaseProtocol],
        index: Int = 0,
        heroImageView: UIImageView? = nil,
        imagePageDidChangeHandle: ImagePageDidChangeHandle? = nil,
        config: JFHeroBrowserGlobalConfig = .default
    ) {
        let store = HeroBrowserObservation(viewModules: viewModules, index: index, config: config)
        self.init(store: store, heroImageView: heroImageView, imagePageDidChangeHandle: imagePageDidChangeHandle)
        setup()
    }

    init(store: HeroBrowserObservation,
         heroImageView: UIImageView? = nil,
         imagePageDidChangeHandle: ImagePageDidChangeHandle? = nil) {
        self.store = store
        self.heroImageView = heroImageView
        self.imagePageDidChangeHandle = imagePageDidChangeHandle
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - Life Cycle
extension HeroBrowser {

    open override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.setNeedsStatusBarAppearanceUpdate()
        DispatchQueue.main.async {
            self.updateSubviewsFrame()
        }
    }
}

// MARK: - Setup
extension HeroBrowser {
    func setup() {
        self.transitionContext = self
        self.setupView()
        self.setupGestureRecognizer()
        self.switchToPage(index: store.initialIndex)
        self.updatepageControlContainer(index: store.initialIndex)
        self.indexChangeHandle(index: store.initialIndex)
        self.prefetchImages()
        self.registerCells()
    }

    func setupView() {
        self.view.addSubview(self.blurView)
        self.view.addSubview(self.collectionView)
        self.view.backgroundColor = .clear
        if let headerView = self.dataSource?.viewForHeader() {
            self.view.addSubview(headerView)
            self.headerView = headerView
        }
        if let footerView = self.dataSource?.viewForFooter() {
            self.view.addSubview(footerView)
            self.footerView = footerView
        }

        let pageCount = _viewModules?.count ?? 0
        self.pageControlContainer.updateView()
        if store.config.enableBlurEffect {
            enableBlurEffet()
        }
    }

    private func registerCells() {
        _viewModules?.forEach { module in
            self.collectionView.register(module.cellClz, forCellWithReuseIdentifier: module.identity)
        }
    }

    func enableBlurEffet() {
        self.blurView.backgroundColor = .clear
        let blurEffectView = UIVisualEffectView(effect: self.effect)
        blurEffectView.frame = bounds
        self.blurView.addSubview(blurEffectView)
        self.blurEffectView = blurEffectView
    }

}

// MARK: - Setup
extension HeroBrowser {

    func updatepageControlContainer(index: Int) {
        guard index < self.pageControlContainer.numberOfPages else { return }
        store.currentPage = index
    }

    func updateHeroView(index: Int) {
        guard index < _viewModules?.count ?? 0 else { return }
        self.heroImageView = self.imagePageDidChangeHandle?(index)
    }
}

// MARK: - Action
extension HeroBrowser {

    public func show(with vc: UIViewController, animationType: HeroTransitionAnimationType = .hero) {
        self.animationType = animationType
        self.isShow = true
        let navi = UINavigationController(rootViewController: self)
        navi.transitioningDelegate = self
        navi.modalPresentationStyle = .custom
        vc.present(navi, animated: true, completion: nil)
    }

    public func hide(with completion: (() -> Void)?) {
        self.isShow = false
        self.dismiss(animated: true, completion: {
            self.didDismissHandle?(self.currentIndex, self._viewModules![self.currentIndex])
            completion?()
        })
    }

    // 预加载左右各一张
    func prefetchImages() {
        guard let vms = _viewModules else { return }
        if currentIndex > 0 {
            self.loadImage(index: currentIndex - 1)
        }
        if currentIndex < vms.count {
            self.loadImage(index: currentIndex + 1)
        }
    }

    func loadImage(index: Int) {
        guard let vms = _viewModules, index < vms.count, let networkVM = vms[index] as? HeroBrowserNetworkImageViewModule else { return }
        networkVM.asyncLoadRawSource(with: nil)
        networkVM.asyncLoadThumbailSource(with: nil)
    }

    func switchToPage(index: Int) {
        self.collectionView.setContentOffset(CGPoint(x: Int(bounds.width * CGFloat(index)), y: 0), animated: false)
    }

    @objc func changePage(pageControl: UIPageControl) {
        self.updateHeroView(index: pageControl.currentPage)
        self.switchToPage(index: pageControl.currentPage)
    }

    //preset to override
    open func indexChangeHandle(index: Int) {

    }
}

extension HeroBrowser: UIGestureRecognizerDelegate {
    func setupGestureRecognizer() {
        let singleFingerOne = UITapGestureRecognizer(target: self, action: #selector(handleSingleFingerEvent(gesture:)))
        singleFingerOne.numberOfTouchesRequired = 1
        singleFingerOne.numberOfTapsRequired = 1
        singleFingerOne.delegate = self
        self.view.addGestureRecognizer(singleFingerOne)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressEvent(gesture:)))
        self.view.addGestureRecognizer(longPress)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleFingerEvent(gesture:)))
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        self.view.addGestureRecognizer(doubleTap)
        singleFingerOne.require(toFail: doubleTap)
    }

    @objc func handleLongPressEvent(gesture: UIGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let vm = _viewModules?[self.currentIndex] else { return }
        if let del = self.delegate {
            del.heroBrowser(self, didLongPressHandle: vm)
            return
        }
        self.heroBrowserDidLongPressHandle?(self, vm)
    }

    @objc func handleSingleFingerEvent(gesture: UIGestureRecognizer) {
        if let cell = self.collectionView.cellForItem(at: self.currentIndexPath()) as? HeroBrowserCollectionCellProtocol {
            cell.resetZoom()
        }

        if let cell = self.collectionView.cellForItem(at: self.currentIndexPath()) as? HeroBrowserVideoCell {
            if cell.videoView.player?.rate == 0 || cell.videoView.currentTime < 2 { // currentTime为1还是会响应
                return // 避免在开始播放的时候想暂停，误操作导致dismiss
            }
            cell.videoView.resetPlayer()
        }

        self.hide(with: nil)
    }

    @objc func handleDoubleFingerEvent(gesture: UIGestureRecognizer) {
        let touchLocation: CGPoint = gesture.location(in: gesture.view)
        if let cell = self.collectionView.cellForItem(at: self.currentIndexPath()) as? HeroBrowserCollectionCellProtocol {
            if cell.videoViewModule == nil { // 避免视频readyToPlay阶段的双击
                cell.doubleTap(location: touchLocation)
            }
        }
    }

    //如果上层UI 有Button 拦截掉，不然会阻止Button Event
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isKind(of: UIButton.self) ?? false {
            return false
        } else {
            return true
        }
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func currentIndexPath() -> IndexPath {
        IndexPath(item: self.currentIndex, section: 0)
    }
}

extension HeroBrowser: UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        _viewModules?.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cellForItemAt index \(indexPath.item)")
        guard let vm = _viewModules?[indexPath.item] else {
            return UICollectionViewCell()
        }
        let cell = vm.createCell(collectionView, indexPath)
        cell.getContainer().contentMode = self.heroContentMode
        cell.closeBlock = { [weak self] in
            guard let self = self else { return }
            self.animationType = .hero
            self.hide(with: nil)
        }
        cell.updatedContainerScaleBlock = { [weak self] scale in
            guard let self = self else { return }
            self.blurView.alpha = scale
            self.isHideOther = scale < 1
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("willDisplay cell index \(indexPath.item)")
        guard let vm = _viewModules?[indexPath.item] else {
            return
        }
        guard var cell = cell as? HeroBrowserHostedCellProtocol else { return }
        if let vm = vm as? HeroBrowserViewModule {
            cell.viewModule = vm
        } else if let vm = vm as? HeroBrowserVideoViewModule {
            cell.videoViewModule = vm
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? HeroBrowserCollectionCellProtocol {
            cell.resetZoom()
        }
        if let videoCell = cell as? HeroBrowserVideoCellProtocol {
            videoCell.pauseVideo()
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _scrolling = true
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetX: CGFloat = scrollView.contentOffset.x
        guard bounds.width > 0 else { return }
        let currentIndex: Int = Int((contentOffsetX + 0.5 * bounds.width) / bounds.width)
        self.updateHeroView(index: currentIndex)
        self.updatepageControlContainer(index: currentIndex)
        self.indexChangeHandle(index: currentIndex)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        _scrolling = false
        self.prefetchImages()
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let self = self else { return }
            self.updateSubviewsFrame()
            self.collectionView.invalidateIntrinsicContentSize()
        }, completion: nil)
    }
}

extension HeroBrowser: UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    // 自定义 放大 缩小 转场
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.3
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transitionContext
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transitionContext
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if self.isShow == true {
            self.present(transitonContext: transitionContext)
        } else {
            self.dismiss(transitonContext: transitionContext)
        }
    }

    func present(transitonContext: UIViewControllerContextTransitioning) {
        HeroTransitionAnimation.present(transitonContext: transitonContext, animationType: animationType, heroBrowser: self)
    }

    func dismiss(transitonContext: UIViewControllerContextTransitioning) {
        HeroTransitionAnimation.dismiss(transitonContext: transitonContext, animationType: animationType, heroBrowser: self)
    }
}

extension HeroBrowser {

    func updateSubviewsFrame() {
        let currentPage = self.store.currentPage
        self.collectionView.frame = bounds
        self.blurView.frame = bounds
        self.blurEffectView?.frame = bounds
        self.pageControlContainer.jf.centerX = self.collectionView.jf.centerX
        if #available(iOS 11.0, *) {
            self.pageControlContainer.jf.bottom = bounds.height - (self.view.window?.safeAreaInsets.bottom ?? 0) - 15
        } else {
            self.pageControlContainer.jf.bottom = bounds.height - 15
        }
        self.collectionView.reloadData()
        self.collectionView.scrollToItem(at: IndexPath(item: currentPage, section: 0), at: .centeredHorizontally, animated: false)
        self.updateFooterOrHeaderView()
    }

    func updateFooterOrHeaderView() {
        if var footer = self.footerView {
            let size = footer.jf.size
            footer.jf.width = bounds.width
            footer.jf.height = size.height
            footer.jf.bottom = bounds.height
        }
        if var header = self.headerView {
            let size = header.jf.size
            header.jf.width = bounds.width
            header.jf.height = size.height
        }
    }

}
