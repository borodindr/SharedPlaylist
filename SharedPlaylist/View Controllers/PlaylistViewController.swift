//
//  PlaylistViewController.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 03.03.2021.
//

import UIKit
import CoreData

final class PlaylistViewController: UIViewController {
    
    // MARK: - Views
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Private properties
    private lazy var dataSource = UITableViewDiffableDataSource<Int, Song>(
        tableView: tableView
    ) { [weak self] (tv, indexPath, song) -> UITableViewCell? in
        let cell = tv.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongCell
        cell.trackNameLabel.text = song.trackName
        cell.artistNameLabel.text = song.artistName
        let artwork: UIImage?
        cell.artworkImageView.sd_setImage(with: song.artworkURL,
                                          placeholderImage: UIImage(systemName: "music.quarternote.3"))
        return cell
    }
    
    // MARK: - Init
    init(songs: [Song]) {
        super.init(nibName: nil, bundle: nil)
        var snapshot = NSDiffableDataSourceSnapshot<Int, Song>()
        snapshot.appendSections([0])
        snapshot.appendItems(songs, toSection: 0)
        dataSource.apply(snapshot)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Playlist"
        view.backgroundColor = .systemGroupedBackground
        prepareTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    // MARK: - Private methods
    private func prepareTableView() {
        view.addSubview(tableView)
        tableView.register(SongCell.self, forCellReuseIdentifier: "SongCell")
        tableView.dataSource = dataSource
        tableView.rowHeight = 80
    }
    
}
