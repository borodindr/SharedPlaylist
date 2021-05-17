//
//  PlaylistEntity+Extension.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 02.03.2021.
//

import Foundation
import CoreData

extension PlaylistEntity {
    var asPlaylist: Playlist {
        let songEntities = songs as! Set<SongEntity>
        let songs = Array(songEntities)
            .sorted { $0.indexInPlaylist < $1.indexInPlaylist }
            .map {
                Song(artistId: Int($0.artistId),
                     artistName: $0.artistName ?? "",
                     artworkURL: $0.artworkURL!,
                     trackId: Int($0.trackId),
                     trackName: $0.trackName ?? "")
            }
        
        return Playlist(id: id!, name: name ?? "", songs: songs)
    }
    
    func updateSongIndices() {
        let songEntities = songs as! Set<SongEntity>
        let updatedSongs = Array(songEntities)
            .sorted { $0.indexInPlaylist < $1.indexInPlaylist }
            .enumerated()
            .map { index, song -> SongEntity in
                song.indexInPlaylist = Int16(index)
                return song
            }
        self.songs = NSSet(array: updatedSongs)
    }
    
}

extension PlaylistEntity {
    convenience init(name: String, insertInto context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = UUID()
        self.dateCreated = Date()
        self.name = name
    }
}
