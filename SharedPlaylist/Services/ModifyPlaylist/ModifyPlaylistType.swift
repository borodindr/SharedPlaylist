//
//  ModifyPlaylistType.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation

enum ModifyPlaylistType {
    case host(playlistName: String)
    case guest(host: PlaylistHost, hostBrowser: PlaylistHostBrowser)
    
    var service: ModifyPlaylistService {
        switch self {
        case .host(let name):
            return PlaylistHostService(playlistName: name)
            
        case .guest(let host, let browser):
            return PlaylistGuestService(host: host, hostBrowser: browser)
        }
        
    }
}
