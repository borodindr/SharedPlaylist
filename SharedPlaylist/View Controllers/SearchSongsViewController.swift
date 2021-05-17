//
//  SearchSongsViewController.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 23.02.2021.
//

import UIKit
import Moya
import SDWebImage

protocol SearchSongsViewControllerDelegate: class {
    func searchSongsViewController(_ searchSongsViewController: SearchSongsViewController,
                                   didAddSong song: Song,
                                   completion: @escaping (Bool) -> ())
    func searchSongsViewController(_ searchSongsViewController: SearchSongsViewController,
                                   isSongAlreadyAdded song: Song) -> Bool
    
    
}

class SearchSongsViewController: UIViewController {
    
    weak var delegate: SearchSongsViewControllerDelegate?
    lazy var tableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    
    lazy var dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) { [weak self] (tv, indexPath, song) -> UITableViewCell? in
        guard let self = self else { return UITableViewCell() }
        let cell = tv.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SearchSongCell
        cell.trackNameLabel.text = song.trackName
        cell.artistNameLabel.text = song.artistName
        cell.artworkImageView.sd_setImage(with: song.artworkURL,
                                          placeholderImage: UIImage(systemName: "music.quarternote.3"))
        let isAlreadyAdded = self.delegate?.searchSongsViewController(self, isSongAlreadyAdded: song) ?? false
        if isAlreadyAdded {
            cell.setState(.added)
        } else {
            cell.setState(.add)
        }
        cell.delegate = self
        return cell
    }
    
    private let iTunesProvider = MoyaProvider<ITunesSearchAPI>()
    private var debounceTimer: Timer?
    private lazy var doneButtonBottomInset: CGFloat = view.bounds.height - view.safeAreaInsets.bottom - 8
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        prepareTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    func searchSongs(query: String) {
        debounce { [weak self] in
            self?.iTunesProvider.request(.songs(query: query)) { (result) in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    print("Error fetching songs:", error)
                    
                case .success(let response):
                    do {
                        let result = try JSONDecoder().decode(ITunesSearchResponse.self, from: response.data)
                        let songResponses = result.results
                        let songs = songResponses.map { $0.asSong }
                        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                        snapshot.appendSections([.songs])
                        snapshot.appendItems(songs, toSection: .songs)
                        DispatchQueue.main.async {
                            self.dataSource.apply(snapshot, animatingDifferences: true)
                        }
                    } catch {
                        print("Error decoding iTunes result:", error)
                    }
                }
            }
        }
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    private func prepareTableView() {
        tableView.register(SearchSongCell.self, forCellReuseIdentifier: "SongCell")
        tableView.dataSource = dataSource
        tableView.rowHeight = 80
        tableView.allowsSelection = false
    }
    
    private func debounce(block: @escaping () -> ()) {
        // TODO: Implement
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { (_) in
            block()
        }
    }
    
}

extension SearchSongsViewController {
    enum Section {
        case songs
    }
    
    typealias Item = Song
}

extension SearchSongsViewController: SearchSongCellDelegate {
    func searchSongCellDidTapAdd(at cell: SearchSongCell) {
        cell.setState(.loading)
        guard let indexPath = tableView.indexPath(for: cell),
              let song = dataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.searchSongsViewController(self,
                                            didAddSong: song) { (success) in
            if success {
                cell.setState(.added)
            } else {
                cell.setState(.failure)
            }
        }
    }
    
}
