//
//  HeroBrowserCollectionCellProtocol.swift
//  JFHeroBrowser
//
//  Created by tdt on 7/3/25.
//

import Foundation
import UIKit

@MainActor
public protocol HeroBrowserCollectionCellProtocol: UICollectionViewCell {
    typealias UpdatedContainerScaleBlock = (CGFloat) -> Void
    typealias CloseBlock = () -> Void
    static func identify() -> String

    var browser: HeroBrowser? { get }

    var viewModule: HeroBrowserViewModule? { get set }
    var videoViewModule: HeroBrowserVideoViewModule? { get set }

    var beginFrame: CGRect { get set }
    var beginTouchPoint : CGPoint { get set }
    var updatedContainerScaleBlock: UpdatedContainerScaleBlock? { get set }
    var closeBlock: CloseBlock? { get set }

    func getContainer() -> UIView
    func resetZoom()
    func doubleTap(location: CGPoint)
}

extension HeroBrowserCollectionCellProtocol {
    func resetZoom() {}
    func doubleTap(location: CGPoint) {}
}
