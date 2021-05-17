//
//  Playlist.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation

struct Playlist {
    let id: UUID
    let name: String
    let songs: [Song]
    
}

extension Playlist: Codable { }
