//
//  SearchSongCell.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 25.02.2021.
//

import UIKit
import SnapKit

protocol SearchSongCellDelegate: class {
    func searchSongCellDidTapAdd(at cell: SearchSongCell)
}

class SongCell: SearchSongCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        statusView.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchSongCell: UITableViewCell {
    enum State {
        case add, added, failure, loading
    }
    
    weak var delegate: SearchSongCellDelegate?
    
    lazy var artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var trackNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    lazy var artistNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        return label
    }()
    
    fileprivate let statusView = UIView()
    
    lazy var addButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var successStatusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle")
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    lazy var failureStatusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "xmark.octagon")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.isHidden = true
        return loader
    }()
    
    var failureTimer: Timer?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        failureTimer?.invalidate()
    }
    
    func setState(_ state: State) {
        failureTimer?.invalidate()
        switch state {
        case .add:
            addButton.isHidden = false
            successStatusImageView.isHidden = true
            failureStatusImageView.isHidden = true
            loader.isHidden = true
        case .added:
            addButton.isHidden = true
            successStatusImageView.isHidden = false
            failureStatusImageView.isHidden = true
            loader.isHidden = true
        case .failure:
            addButton.isHidden = true
            successStatusImageView.isHidden = true
            failureStatusImageView.isHidden = false
            loader.isHidden = true
        case .loading:
            addButton.isHidden = true
            successStatusImageView.isHidden = true
            failureStatusImageView.isHidden = true
            loader.isHidden = false
            loader.startAnimating()
        }
    }
    
    private func addSubviews() {
        let labelsStackView = UIStackView(arrangedSubviews: [
            trackNameLabel,
            artistNameLabel
        ])
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 4
        
        statusView.addSubview(addButton)
        statusView.addSubview(successStatusImageView)
        statusView.addSubview(failureStatusImageView)
        statusView.addSubview(loader)
        
        statusView.subviews
            .forEach { view in
                view.snp.makeConstraints { (make) in
                    make.top.bottom.trailing.leading.equalToSuperview()
//                    make.width.equalTo(view.snp.height)
                }
            }
        
        let mainStackView = UIStackView(arrangedSubviews: [
            artworkImageView,
            labelsStackView,
            statusView
        ])
        mainStackView.axis = .horizontal
        mainStackView.spacing = 8
//        mainStackView.layoutMargins = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: 0)
        
        artworkImageView.snp.makeConstraints { (make) in
            make.width.equalTo(artworkImageView.snp.height)
        }
        
        contentView.addSubview(mainStackView)
        mainStackView.snp.makeConstraints { (make) in
            make.topMargin.leadingMargin.bottomMargin.trailingMargin.equalToSuperview()
        }
        
    }
    
    private func scheduleFailureTimer() {
        failureTimer?.invalidate()
        failureTimer = Timer.scheduledTimer(withTimeInterval: 3,
                                            repeats: false) { [weak self] _ in
            self?.setState(.add)
        }
    }
    
    @objc
    private func addButtonTapped(_ sender: UIButton) {
        delegate?.searchSongCellDidTapAdd(at: self)
        print("Tap")
    }
    
}
