//
//  HeroBrowserEmbeddedView.swift
//  JFHeroBrowser
//
//  Created by tdt on 2026/4/22.
//

import SwiftUI

public struct HeroBrowserEmbeddedView: UIViewControllerRepresentable {

    public typealias Coordinator = Void

    let browser: HeroBrowser
    let onDismissRequested: () -> Void

    public init(browser: HeroBrowser, onDismissRequested: @escaping () -> Void) {
        self.browser = browser
        self.onDismissRequested = onDismissRequested
    }

    public func makeUIViewController(context: Context) -> HeroBrowserEmbeddedHostViewController {
        let controller = HeroBrowserEmbeddedHostViewController()
        controller.set(browser: browser, onDismissRequested: onDismissRequested)
        return controller
    }

    public func updateUIViewController(_ uiViewController: HeroBrowserEmbeddedHostViewController, context: Context) {
        uiViewController.set(browser: browser, onDismissRequested: onDismissRequested)
    }

    public static func dismantleUIViewController(_ uiViewController: HeroBrowserEmbeddedHostViewController, coordinator: ()) {
        uiViewController.cleanup()
    }
}

public final class HeroBrowserEmbeddedHostViewController: UIViewController {

    private weak var currentBrowser: HeroBrowser?
    private var pendingDismissCompletion: (() -> Void)?
    private var onDismissRequested: (() -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    func set(browser: HeroBrowser, onDismissRequested: @escaping () -> Void) {
        self.onDismissRequested = onDismissRequested
        browser.embeddedDismissHandle = { [weak self] _, completion in
            guard let self else { return }
            pendingDismissCompletion = completion
            self.onDismissRequested?()
        }

        guard currentBrowser !== browser else { return }

        if let currentBrowser {
            currentBrowser.embeddedDismissHandle = nil
            detach(browser: currentBrowser)
        }

        currentBrowser = browser
        attach(browser: browser)
    }

    func cleanup() {
        if let currentBrowser {
            currentBrowser.embeddedDismissHandle = nil
            detach(browser: currentBrowser)
            self.currentBrowser = nil
        }
        pendingDismissCompletion?()
        pendingDismissCompletion = nil
    }

    private func attach(browser: HeroBrowser) {
        if browser.parent !== self {
            addChild(browser)
            view.addSubview(browser.view)
            browser.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                browser.view.topAnchor.constraint(equalTo: view.topAnchor),
                browser.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                browser.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                browser.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            browser.didMove(toParent: self)
        }
    }

    private func detach(browser: HeroBrowser) {
        guard browser.parent === self else { return }
        browser.willMove(toParent: nil)
        browser.view.removeFromSuperview()
        browser.removeFromParent()
    }
}
