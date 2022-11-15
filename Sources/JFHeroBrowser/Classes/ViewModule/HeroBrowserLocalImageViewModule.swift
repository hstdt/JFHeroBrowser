//
//  HeroBrowserLocalImageViewModule.swift
//  HeroBrowser
//
//  Created by 逸风 on 2021/10/29.
//

import UIKit

public class HeroBrowserLocalImageViewModule: HeroBrowserViewModule {
    
    public override func createCell(_ collectionView: UICollectionView, _ indexPath: IndexPath) -> HeroBrowserCollectionCellProtocol {
        return collectionView.dequeueReusableCell(withReuseIdentifier: HeroBrowserBaseImageCell.identify(), for: indexPath) as! HeroBrowserBaseImageCell
    }
    
    public override func asyncLoadThumbailSource(with complete: HeroBrowserViewModule.Complete<UIImage>?) {
        complete?(.success(self.image))
    }
    
    public override func asyncLoadRawSource(with complete: HeroBrowserViewModule.Complete<RawData>?) {
        complete?(.success((self.image, self.imageData)))
    }
    
    var image: UIImage
    var imageData: Data?
    public init(image: UIImage, imageData: Data? = nil) {
        self.image = image
        self.imageData = imageData
        super.init(type: .localImage)
    }
}
