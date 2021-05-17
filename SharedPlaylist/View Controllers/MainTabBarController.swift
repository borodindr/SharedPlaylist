//
//  MainTabBarController.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 22.02.2021.
//

import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setViewControllers()
    }
    
    private func setViewControllers() {
        let vc0 = LibraryViewController()
        let nav0 = UINavigationController(rootViewController: vc0)
        nav0.navigationBar.prefersLargeTitles = true
        nav0.tabBarItem.title = "Library"
        
        let vc1 = NewPlaylistViewController()
        let nav1 = UINavigationController(rootViewController: vc1)
        nav1.navigationBar.prefersLargeTitles = true
        nav1.tabBarItem.title = "New Playlist"
        
        setViewControllers([nav0, nav1], animated: false)
    }
    
}
