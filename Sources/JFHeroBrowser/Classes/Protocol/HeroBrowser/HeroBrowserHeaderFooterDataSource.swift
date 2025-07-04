//
//  HeroBrowserHeaderFooterDataSource.swift
//  JFHeroBrowser
//
//  Created by tdt on 7/3/25.
//

import Foundation
import UIKit

@MainActor
public protocol HeroBrowserHeaderFooterDataSource: AnyObject {
    func viewForHeader(store: HeroBrowserObservation) -> UIView?
    func viewForFooter(store: HeroBrowserObservation) -> UIView?
}
