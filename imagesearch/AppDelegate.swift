//
//  AppDelegate.swift
//  imagesearch
//
//  Created by Nikita Zatsepilov on 25/04/2018.
//  Copyright © 2018 Nikita Zatsepilov. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: ImagesViewController())
        window?.makeKeyAndVisible()

//        let query = ImagesFetchQuery(searchText: "hello", imageFormat: .png, limit: 4, position: 1)
//        try! MediaService.init().fetchImages(using: query, { (succeed, result, error) in
//
//        })

        return true
    }




}

