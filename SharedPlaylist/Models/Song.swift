//
//  Song.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation

struct Song: Hashable {
    let artistId: Int
    let artistName: String
    let artworkURL: URL
    let trackId: Int
    let trackName: String
}

extension Song: Codable { }

extension SongResponse {
    var asSong: Song {
        Song(artistId: artistId,
             artistName: artistName,
             artworkURL: artworkUrl100,
             trackId: trackId,
             trackName: trackName)
    }
}

extension SongEntity {
    var asSong: Song? {
        guard let artistName = artistName,
              let artworkURL = artworkURL,
              let trackName = trackName else { return nil }
        return Song(
            artistId: Int(artistId),
            artistName: artistName,
            artworkURL: artworkURL,
            trackId: Int(trackId),
            trackName: trackName
        )
    }
}
