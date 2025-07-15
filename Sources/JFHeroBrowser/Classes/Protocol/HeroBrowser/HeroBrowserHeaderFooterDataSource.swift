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
    func viewForHeader(browser: HeroBrowserObservation) -> UIView?
    func viewForFooter(browser: HeroBrowserObservation) -> UIView?
}
