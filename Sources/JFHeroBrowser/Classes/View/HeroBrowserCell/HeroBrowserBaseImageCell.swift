//
//  HeroBrowserBaseImageCell.swift
//  Example
//
//  Created by 逸风 on 2021/8/8.
//

import UIKit
import Combine

open class HeroBrowserBaseImageCell: UICollectionViewCell {

    weak public var browser: HeroBrowser?
    public var closeBlock: CloseBlock?
    public var updatedContainerScaleBlock: UpdatedContainerScaleBlock?
    public var beginTouchPoint: CGPoint = .zero
    public var beginFrame: CGRect = .zero
    let zoomScalePublisher = PassthroughSubject<CGFloat, Never>()

    var container: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy var scrollView: UIScrollView = {
        let tempView = UIScrollView(frame: .zero)
        tempView.showsHorizontalScrollIndicator = false
        tempView.showsVerticalScrollIndicator = false
        tempView.alwaysBounceVertical = false
        tempView.alwaysBounceHorizontal = true
        tempView.scrollsToTop = false
        tempView.backgroundColor = .clear
        tempView.maximumZoomScale = 3.0
        tempView.minimumZoomScale = 1.0
        tempView.setZoomScale(1, animated: false)
        tempView.isUserInteractionEnabled = false
        if #available(iOS 11.0, *) {
            tempView.contentInsetAdjustmentBehavior = .never
        }
        tempView.delegate = self
        return tempView
    }()

    lazy var panGesture: UIPanGestureRecognizer = {
        // scrollView设置frame之前把手势放在cell上,设置之后才放在ScrollView上.避免空白的时候无法交互
        let gesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(gest:)))
        gesture.delegate = self
        return gesture
    }()

    public var videoViewModule: HeroBrowserVideoViewModule? {
        didSet {
            self.beginLoadSource()
        }
    }

    public var viewModule: HeroBrowserViewModule? {
        didSet {
            self.beginLoadSource()
        }
    }

    func beginLoadSource() {
        guard let vm = viewModule else { return }
        vm.asyncLoadThumbailSource { result in
            switch result {
            case let .success(image):
                self.updateView(image: image)
            case _ :
                break
            }
        }
        vm.asyncLoadRawSource { result in
            switch result {
            case let .success(rawData):
                self.updateView(image: rawData.0)
            case _ :
                break
            }
        }
    }

    func updateView(image: UIImage) {
        self.container.image = image
        self.scrollView.addGestureRecognizer(panGesture)
        self.scrollView.isUserInteractionEnabled = true
        self.updateContainerFrame(with: image)
    }

    func updateContainerFrame(with image: UIImage) {
        self.updateContainerFrame(size: image.size)
    }

    func updateContainerFrame(size: CGSize) {
        guard let screenWidth = window?.frame.size.width, let screenHeight = window?.frame.size.height else { return }
        scrollView.frame = CGRect(origin: .zero, size: CGSize(width: screenWidth, height: screenHeight)) // 必须设置,否则scrollView.contentSize有问题.
        let height = size.height * screenWidth / size.width
        let containerSize = CGSize(width: screenWidth, height: height)
        container.frame = CGRect(origin: .zero, size: containerSize)
        scrollView.contentSize = containerSize

        if container.frame.size.height < frame.size.height {
            var center = container.center
            center.y = frame.size.height / 2
            container.center = center
        }
    }
    nonisolated
    public static func identify() -> String {
        NSStringFromClass(Self.self)
    }

    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(noti:)), name:UIDevice.orientationDidChangeNotification, object: UIDevice.current)
    }

    func setupView() {
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        scrollView.addSubview(self.container)
        addGestureRecognizer(panGesture)

        zoomScalePublisher
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] scale in
                guard let self else { return }
                if let browser, let headerFooterDataSource = browser.store.headerFooterDataSource {
                    let store = browser.store
                    if scale == 1 {
                        store.showHeaderFooterView.toggle()
                    } else {
                        store.showHeaderFooterView = false
                    }
                }
            }
        .store(in: &cancellables)

    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func beginDragHandle() {

    }

    func endDragHandle() {

    }

}

extension HeroBrowserBaseImageCell: UIScrollViewDelegate {
    @objc private func onPan(gest: UIPanGestureRecognizer) {
        switch gest.state {
        case .began:
            beginFrame = container.frame
            beginTouchPoint = gest.location(in: scrollView)
            beginDragHandle()
            if let browser {
                browser.willDismissHandle?(browser.currentIndex, viewModule!)
            }
        case .changed:
            container.frame = getRectForPan(pan: gest)
            updatedContainerScaleBlock?(getScaleForPan(pan: gest))
        case .ended, .cancelled:
            self.container.frame = getRectForPan(pan: gest)
            let isDown: Bool = gest.velocity(in: self).y > 100 ? true : false
            if isDown == true {
                resetZoom()
                closeBlock?()
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.container.frame = self.beginFrame
                }
                updatedContainerScaleBlock?(1.0)
                endDragHandle()
            }

        default:
            break
        }
    }

    private func getRectForPan(pan: UIPanGestureRecognizer) -> CGRect {
        var rect: CGRect = .zero
        guard beginFrame != CGRect.zero else {
            return rect
        }
        let currentTouch = pan.location(in: scrollView)
        let scale = getScaleForPan(pan: pan)
        let width = beginFrame.size.width * scale
        let  height = beginFrame.size.height * scale
        let xRate = (beginTouchPoint.x - beginFrame.origin.x) / beginFrame.size.width
        let currentTouchDeltaX = xRate * width
        let x = currentTouch.x - currentTouchDeltaX
        let yRate = (beginTouchPoint.y - beginFrame.origin.y) / beginFrame.size.height
        let currentTouchDeltaY = yRate * height
        let y = currentTouch.y - currentTouchDeltaY
        rect = CGRect(x: x, y: y, width: width, height: height)
        return rect
    }

    private func getScaleForPan(pan: UIPanGestureRecognizer) -> CGFloat {
        let translation = pan.translation(in: scrollView)
        let scale: CGFloat = min(1.0, max(0.3, 1 - translation.y / bounds.size.height))
        return scale
    }

    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect: CGRect = .zero
        zoomRect.size.height = frame.size.height / scale
        zoomRect.size.width  = frame.size.width / scale
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
}

extension HeroBrowserBaseImageCell: HeroBrowserHostedCellProtocol {}

extension HeroBrowserBaseImageCell: HeroBrowserCollectionCellProtocol {

    public func getContainer() -> UIView {
        container
    }

    public func resetZoom() {
        // setScrollViewZoomScale(1.0) // 会导致翻页的时候也触发zoomScalePublisher
        scrollView.setZoomScale(1.0, animated: true)
    }

    public func doubleTap(location: CGPoint) {
        if self.scrollView.zoomScale <= 1.0 {
            let gesturePointInImageView = container.convert(location, to: self)
            self.scrollView.zoom(to: zoomRectForScale(scale: 2.0, center: gesturePointInImageView), animated: true)
        } else {
            setScrollViewZoomScale(1.0)
        }
    }

    public func setScrollViewZoomScale(_ scale: CGFloat, animated: Bool = true) {
        scrollView.setZoomScale(scale, animated: true)
        zoomScalePublisher.send(scale)
    }

}

extension HeroBrowserBaseImageCell {

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        container
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var frame = container.frame
        if container.frame.size.height < scrollView.frame.size.height {
            frame.origin.y = (scrollView.frame.size.height - container.frame.size.height) / 2
        } else {
            frame.origin.y = 0
        }
        container.frame = frame
        if bounds.width > bounds.height {
            container.jf.centerX = scrollView.jf.centerX
        }
        zoomScalePublisher.send(scrollView.zoomScale)
    }
}

extension HeroBrowserBaseImageCell:UIGestureRecognizerDelegate {

    @objc func orientationChanged(noti: Notification) {
        DispatchQueue.main.async {
            guard let bounds = self.window?.bounds else { return }
            self.scrollView.frame = bounds
        }
    }

    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            if scrollView.contentOffset.y > 0 {
                return false
            }
            let velocity: CGPoint = pan.velocity(in: self)
            if velocity.y < 0 {
                return false
            }
            if abs(Int(velocity.x)) > Int(velocity.y) {
                return false
            }
            return true
        } else {
            return true
        }
    }
}
