//
//  HeroBrowserHostedCellProtocol.swift
//  JFHeroBrowser
//
//  Created by WillsonWang on 29/01/2023.
//

import Foundation

@MainActor
public protocol HeroBrowserHostedCellProtocol {
    var videoViewModule: HeroBrowserVideoViewModule? { get set }
    var viewModule: HeroBrowserViewModule? { get set }
}
