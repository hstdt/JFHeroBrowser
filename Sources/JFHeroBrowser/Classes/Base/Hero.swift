//
//  Hero.swift
//  Example
//
//  Created by 逸风 on 2021/8/4.
//

import Foundation
import UIKit
import JRBaseKit

public enum JFHeroBrowserPageControlType: Sendable {
    case none
    case pageControl
    case number
}

public struct JFHeroBrowserGlobalConfig: Sendable {
    public var pageControlType: JFHeroBrowserPageControlType
    public var enableBlurEffect: Bool
    public var networkImageProvider: NetworkImageProvider?
    public init(
        _ enableBlurEffect: Bool,
        networkImageProvider: NetworkImageProvider? = nil,
        pageControlType: JFHeroBrowserPageControlType = .none
    ) {
        self.enableBlurEffect = enableBlurEffect
        self.networkImageProvider = networkImageProvider
        self.pageControlType = pageControlType
    }
    @MainActor public static var `default` = JFHeroBrowserGlobalConfig(true, networkImageProvider: nil, pageControlType: .pageControl)
    @MainActor public static var multiSource = JFHeroBrowserGlobalConfig(false, networkImageProvider: nil, pageControlType: .none)
}

public enum JFHeroBrowserOption {
    case enableBlurEffect(Bool)
    case pageControlType(JFHeroBrowserPageControlType)
    case heroView(UIImageView?)
    case heroBrowserDidLongPressHandle(HeroBrowser.HeroBrowserDidLongPressHandle)
    case heroBrowserWillDismissHandle(HeroBrowser.HeroBrowserWillDismissHandle)
    case heroBrowserDidDismissHandle(HeroBrowser.HeroBrowserDidDismissHandle)
    case imageDidChangeHandle(HeroBrowser.ImagePageDidChangeHandle)
}

public struct Hero<Base> {
    public let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

struct HeroError: Error {
    let errorMsg: String
}

public protocol HeroCompatible {}
public extension HeroCompatible {
    static var hero: Hero<Self>.Type {
        Hero<Self>.self
    }
    var hero: Hero<Self> {
        Hero(self)
    }
}
