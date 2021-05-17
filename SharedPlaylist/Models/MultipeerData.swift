//
//  MultipeerData.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation
import MultipeerConnectivity

enum MultipeerData {
    enum RequestType: String {
        case initialPlaylist
    }
    
    case request(type: RequestType)
    case playlist(Playlist)
    case addSong(Song, atIndex: Int)
    case none
}

extension MultipeerData.RequestType: Codable { }

private extension MultipeerData {
    private enum CodingKeys: String, CodingKey {
        case `case`
        case requestType
        case playlist
        case song
        case index
    }
    
    private enum CaseType: String {
        case request
        case playlist
        case addSongAtIndex
    }
    
}

extension MultipeerData: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseRawValue = try container.decode(String.self, forKey: .case)
        guard let `case` = CaseType(rawValue: caseRawValue) else {
            self = .none
            return
        }
        switch `case` {
        case .request:
            let requestTypeRawValue = try container.decode(String.self, forKey: .requestType)
            guard let requestType = RequestType(rawValue: requestTypeRawValue) else {
                self = .none
                return
            }
            self = .request(type: requestType)
        case .playlist:
            let playlist = try container.decode(Playlist.self, forKey: .playlist)
            self = .playlist(playlist)
        case .addSongAtIndex:
            let song = try container.decode(Song.self, forKey: .song)
            let index = try container.decode(Int.self, forKey: .index)
            self = .addSong(song, atIndex: index)
        }
    }
    
}

extension MultipeerData: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .playlist(let playlist):
            try container.encode(CaseType.playlist.rawValue, forKey: .case)
            try container.encode(playlist, forKey: .playlist)
        case .request(let type):
            try container.encode(CaseType.request.rawValue, forKey: .case)
            try container.encode(type, forKey: .requestType)
        case .addSong(let song, let index):
            try container.encode(CaseType.addSongAtIndex.rawValue, forKey: .case)
            try container.encode(song, forKey: .song)
            try container.encode(index, forKey: .index)
        case .none:
            break
        }
    }
    
}
