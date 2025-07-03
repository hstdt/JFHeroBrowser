//
//  HeroBrowserHeaderFooterDataSource.swift
//  JFHeroBrowser
//
//  Created by tdt on 7/3/25.
//

import Foundation
import UIKit

@objc public protocol HeroBrowserHeaderFooterDataSource: AnyObject {
    @objc func viewForHeader() -> UIView?
    @objc func viewForFooter() -> UIView?
}
