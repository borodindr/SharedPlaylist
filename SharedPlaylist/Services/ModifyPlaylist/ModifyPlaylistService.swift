//
//  ModifyPlaylistService.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation
import MultipeerConnectivity

protocol ModifyPlaylistService: class {
    var delegate: ModifyPlaylistServiceDelegate? { get set }
    var canSavePlaylist: Bool { get }
    var dismissButtonTitle: String { get }
    
    func start()
    func addNewSong(_ song: Song, completion: @escaping (Bool) -> ())
    func removeSong(_ song: Song, completion: @escaping (Bool) -> ())
    func isSongAlreadyAdded(_ song: Song) -> Bool
    func dismissPlaylist()
    func savePlaylist()
}
