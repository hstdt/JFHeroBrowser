//
//  HeroBrowserVideoViewModule.swift
//  HeroBrowser
//
//  Created by 逸风 on 2022/4/24.
//

import UIKit
import AVFoundation

/// Video VM, support network video or local file path video
open class HeroBrowserVideoViewModule: HeroBrowserViewModuleProtocol {
    open var identity: String {
        return HeroBrowserVideoCell.identify()
    }
    
    open var cellClz: AnyClass? {
        return HeroBrowserVideoCell.self
    }
    
    public typealias ThumbailData = UIImage
    public typealias RawData = AVPlayerItem
    open var type: HeroBrowserType
    
    open func asyncLoadThumbailSource(with complete: Complete<UIImage>?) {
        guard let thumbailImgUrl = self.thumbailImgUrl else {
            complete?(.failed(nil))
            return
        }
        self.imageProvider?.downloadImage(with: thumbailImgUrl, complete: {
            switch $0 {
            case let .success(rawData):
                complete?(.success(rawData.0))
            case let .failed(error):
                complete?(.failed(error))
            case let .progress(progress):
                complete?(.progress(progress))
            }
        })
    }
    
    open func asyncLoadRawSource(with complete: Complete<AVPlayerItem>?) {
        guard let url = self.videoURL else {
            complete?(.failed(nil))
            return
        }
        let asset = AVURLAsset(url: url)
        complete?(.success(AVPlayerItem(asset: asset)))
    }
    
    open func createCell(_ collectionView: UICollectionView, _ indexPath: IndexPath) -> HeroBrowserCollectionCellProtocol {
        return collectionView.dequeueReusableCell(withReuseIdentifier: HeroBrowserVideoCell.identify(), for: indexPath) as! HeroBrowserVideoCell
    }
    
    open weak var imageProvider: NetworkImageProvider?
    open var thumbailImgUrl: String?
    open var videoURL: URL?
    open var isAutoPlay = true
    open var isAutoLoop = false

    public init(type: HeroBrowserType) {
        self.type = type
    }
    
    public init(thumbailImgUrl: String?, fileUrlPath: String, provider: NetworkImageProvider? = JFHeroBrowserGlobalConfig.default.networkImageProvider, autoPlay: Bool = true, autoLoop: Bool = false) {
        self.thumbailImgUrl = thumbailImgUrl
        self.videoURL = URL(fileURLWithPath: fileUrlPath)
        self.imageProvider = provider
        self.isAutoPlay = autoPlay
        self.isAutoLoop = autoLoop
        self.type = .localVideo
    }
    
    public init(thumbailImgUrl: String?, videoUrl: String, provider: NetworkImageProvider? = JFHeroBrowserGlobalConfig.default.networkImageProvider, autoPlay: Bool = true, autoLoop: Bool = false) {
        self.thumbailImgUrl = thumbailImgUrl
        self.videoURL = URL(string: videoUrl)
        self.imageProvider = provider
        self.isAutoPlay = autoPlay
        self.isAutoLoop = autoLoop
        self.type = .networkVideo
    }
}
