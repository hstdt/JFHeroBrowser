//
//  HeroBrowserViewModuleBaseProtocol.swift
//  JFHeroBrowser
//
//  Created by tdt on 7/3/25.
//

import Foundation
import UIKit

public protocol HeroBrowserViewModuleBaseProtocol {
    var type: HeroBrowserType { get set }
    func createCell(_ collectionView: UICollectionView, _ indexPath: IndexPath) -> HeroBrowserCollectionCellProtocol
    var identity : String { get }
    var cellClz : AnyClass? { get }
}

public protocol HeroBrowserViewModuleProtocol: HeroBrowserViewModuleBaseProtocol {
    associatedtype ThumbailData
    associatedtype RawData
    typealias Complete<T> = (HeroBrowserResult<T>) -> Void
    func asyncLoadThumbailSource(with complete: Complete<ThumbailData>?)
    func asyncLoadRawSource(with complete: Complete<RawData>?)
}
