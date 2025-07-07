//
//  HeroVideoViewDelegate.swift
//  JFHeroBrowser
//
//  Created by tdt on 7/3/25.
//

import Foundation
import AVFoundation

public enum HeroVideoPlayerState: Sendable {
    case unkonw
    case playing
    case pause
    case stop
    case buffering
    case failed
}

extension AVPlayerItem: @unchecked @retroactive Sendable {}

@MainActor
public protocol HeroVideoViewDelegate: NSObjectProtocol {
    func videoViewReadyToPlay(playerItem: AVPlayerItem, view: HeroVideoView)
    func videoViewPlayerPlayingProgress(currentTime: Double, totalTime: Double, view: HeroVideoView)
    func videoViewPlayerStatusDidChange(state: HeroVideoPlayerState, view: HeroVideoView)
    func videoViewPlayerDidPlayToEnd(noti: Notification, view: HeroVideoView)
}

public extension HeroVideoViewDelegate {
    func videoViewReadyToPlay(playerItem: AVPlayerItem, view: HeroVideoView) {

    }

    func videoViewPlayerPlayingProgress(currentTime: Double, totalTime: Double, view: HeroVideoView) {

    }

    func videoViewPlayerStatusDidChange(state: HeroVideoPlayerState, view: HeroVideoView) {

    }

    func videoViewPlayerDidPlayToEnd(noti: Notification, view: HeroVideoView) {

    }
}
