//
//  PlaylistHostBrowserDelegate.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 04.03.2021.
//

import Foundation

protocol PlaylistHostBrowserDelegate: class {
    func playlistHostBrowser(_ browser: PlaylistHostBrowser, didAdd host: PlaylistHost)
    func playlistHostBrowser(_ browser: PlaylistHostBrowser, didRemoveHostWith id: PlaylistHost.ID)
    
}
