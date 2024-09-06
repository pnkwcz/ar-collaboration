//
//  AppDelegate.swift
//  colab-session
//
//  Created by Artur Pinkevych on 01/08/2024.
//

import UIKit
import ARKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication) -> Bool {
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("ARKit is not available")
        }

        return true
    }
}
