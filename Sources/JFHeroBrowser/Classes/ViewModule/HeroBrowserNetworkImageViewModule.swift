//
//  HeroBrowserNetworkImageViewModule.swift
//  HeroBrowser
//
//  Created by 逸风 on 2021/10/29.
//

import UIKit

public class HeroBrowserNetworkImageViewModule: HeroBrowserViewModule {
    
    public override func createCell(_ collectionView: UICollectionView, _ indexPath: IndexPath) -> HeroBrowserCollectionCellProtocol {
        return collectionView.dequeueReusableCell(withReuseIdentifier: HeroBrowserNetworkImageCell.identify(), for: indexPath) as! HeroBrowserNetworkImageCell
    }
    
    public override func asyncLoadThumbailSource(with complete: HeroBrowserViewModule.Complete<UIImage>?) {
        guard let thumbailImgUrl = self.thumbailImgUrl else {
            complete?(.failed(nil))
            return
        }
        self.imageProvider?.downloadImage(with: thumbailImgUrl, complete: { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(rawdata):
                    complete?(.success(rawdata.0))
                    break
                case let .failed(error):
                    complete?(.failed(error))
                    break
                case let .progress(progress):
                    complete?(.progress(progress))
                    break
                }
            }
        })
    }
    
    public override func asyncLoadRawSource(with complete: HeroBrowserViewModule.Complete<RawData>?) {
        self.imageProvider?.downloadImage(with: self.originImgUrl, complete: { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(rawData):
                    complete?(.success(rawData))
                case let .failed(error):
                    complete?(.failed(error))
                case let .progress(progress):
                    complete?(.progress(progress))
                }
            }
        })
    }
    
    public weak var imageProvider: NetworkImageProvider?
    var thumbailImgUrl: String?
    var originImgUrl: String
    
    public init(thumbailImgUrl: String?, originImgUrl: String, provider: NetworkImageProvider? = JFHeroBrowserGlobalConfig.default.networkImageProvider) {
        self.thumbailImgUrl = thumbailImgUrl
        self.originImgUrl = originImgUrl
        self.imageProvider = provider
        super.init(type: .networkImage)
    }
}
