//
//  HeroBrowserViewModuleBaseProtocol.swift
//  JFHeroBrowser
//
//  Created by tdt on 7/3/25.
//

import Foundation
import UIKit
import AVFoundation

@MainActor
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

/* 修复Xcode 16.4 + Swift 5打包问题
 While deserializing SIL witness table for protocol conformance HeroBrowserVideoViewModule: HeroBrowserViewModuleProtocol
 While cross-referencing conformance for 'AVPlayerItem' ... to 'Sendable'
 */
extension AVPlayerItem: @unchecked @retroactive Sendable {}
