//
//  SongResponse.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 23.02.2021.
//

import Foundation

struct ITunesSearchResponse: Decodable, Hashable {
    let resultCount: Int
    let results: [SongResponse]
    
}

struct SongResponse: Decodable, Hashable {
    let wrapperType: String
    let kind: String
    let artistId: Int
    let trackId: Int
    let artistName: String
    let trackName: String
    let artworkUrl100: URL
    
}
