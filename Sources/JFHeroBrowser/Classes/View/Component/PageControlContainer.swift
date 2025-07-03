//
//  PageControlContainer.swift
//  JFHeroBrowser
//
//  Created by tdt on 7/3/25.
//

import SwiftUI
import Combine

class PageControlContainer: UIView {

    private var pageControl: UIPageControl?
    private var pageLabel: UILabel?
    typealias DidChangePageHandle = (UIPageControl) -> Void
    var didChangePageHandle: DidChangePageHandle?

    var numberOfPages: Int {
        guard let store else { return 0 }
        return store._viewModules.count
    }

    private var cancellables = Set<AnyCancellable>()

    weak var store: HeroBrowserObservation?
    init(store: HeroBrowserObservation, frame: CGRect) {
        self.store = store
        super.init(frame: frame)
        store.$currentPage
            .sink {[weak self] currentPage in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.pageControl?.currentPage = currentPage
                    self.pageLabel?.text = "\(currentPage + 1)/\(self.numberOfPages)"
                }
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.pageControl?.frame = self.bounds
        self.pageLabel?.frame = self.bounds
    }

    func updateView() {
        guard let store else { return }
        var type = store.config.pageControlType
        var available = false
        if #available(iOS 14.0, *) {
            available = true
        }
        if !available && numberOfPages > 9 {
            type = .number
        }
        if type == .pageControl {
            let pageC = UIPageControl()
            pageC.addTarget(self, action: #selector(changePage(pageControl:)), for: .valueChanged)
            pageC.hidesForSinglePage = true
            pageC.numberOfPages = numberOfPages
            self.pageControl = pageC
            self.addSubview(pageC)
        } else if type == .number {
            let label = UILabel()
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 15)
            label.textColor = .white
            self.pageLabel = label
            self.addSubview(label)
        } else {
            self.isHidden = true
        }
    }

    @objc func changePage(pageControl: UIPageControl) {
        self.didChangePageHandle?(pageControl)
    }
}
