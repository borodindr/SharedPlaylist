//
//  ModifyPlaylistServiceDelegate.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 27.02.2021.
//

import Foundation
import UIKit
import MultipeerConnectivity

protocol ModifyPlaylistServiceDelegate: class {
    func modifyPlaylistService(_ modifyPlaylistService: ModifyPlaylistService,
                               didChangeContentWith snapshot: NSDiffableDataSourceSnapshot<PlaylistSection, Song>)
    func modifyPlaylistServiceDidEnd(_ modifyPlaylistService: ModifyPlaylistService)
}

