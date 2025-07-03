//
//  HeroBrowserViewModule.swift
//  Example
//
//  Created by 逸风 on 2021/8/4.
//

import UIKit

public enum HeroBrowserType {
    case unknown
    case networkImage
    case localImage
    case dataImage
    case networkVideo
    case localVideo  //file path video
    case assetVideo // Album Asset Video Source
    case assetImage // Album Asset Image Source
}

public enum HeroBrowserResult<T> {
    case success(_ data: T)
    case progress(_ progress: CGFloat)
    case failed(_ error: Error?)
}

public protocol NetworkImageProvider: AnyObject {
    typealias Complete<T> = (HeroBrowserResult<T>) -> Void
    func downloadImage(with imgUrl: String, complete: Complete<(UIImage, Data?)>?)
}

open class HeroBrowserViewModule: HeroBrowserViewModuleProtocol {
    open var identity: String {
        ""
    }

    open var cellClz: AnyClass? {
        nil
    }

    public typealias ThumbailData = UIImage
    public typealias RawData = (UIImage, Data?)
    open var type: HeroBrowserType
    open func asyncLoadThumbailSource(with complete: Complete<UIImage>?) {
        complete?(.failed(nil))
    }
    open func asyncLoadRawSource(with complete: Complete<RawData>?) {
        complete?(.failed(nil))
    }
    public init(type: HeroBrowserType) {
        self.type = type
    }
    open func createCell(_ collectionView: UICollectionView, _ indexPath: IndexPath) -> HeroBrowserCollectionCellProtocol {
        collectionView.dequeueReusableCell(withReuseIdentifier: HeroBrowserBaseImageCell.identify(), for: indexPath) as! HeroBrowserBaseImageCell
    }
}

extension HeroBrowserViewModule: HeroCompatible {}
extension Hero where Base: HeroBrowserViewModule {
    static func localImageVM(image: UIImage) -> HeroBrowserViewModule {
        HeroBrowserLocalImageViewModule(image: image)
    }
}
