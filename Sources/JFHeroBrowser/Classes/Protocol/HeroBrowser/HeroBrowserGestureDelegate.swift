//
//  HeroBrowserGestureDelegate.swift
//  JFHeroBrowser
//
//  Created by tdt on 7/3/25.
//

import Foundation

public protocol HeroBrowserGestureDelegate: AnyObject {
    func heroBrowser(_ heroBrowser: HeroBrowser, didLongPressHandle viewModule: HeroBrowserViewModuleBaseProtocol)
}

extension HeroBrowserGestureDelegate {
    func heroBrowser(_ heroBrowser: HeroBrowser, didLongPressHandle viewModule: HeroBrowserViewModuleBaseProtocol) {}
}
