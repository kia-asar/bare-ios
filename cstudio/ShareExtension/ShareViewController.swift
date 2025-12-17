//
//  ShareViewController.swift
//  cstudio Share Extension
//
//  Created by Kiarash Asar on 11/4/25.
//
//  NOTE: This UIViewController is a minimal required bridge for the extension system.
//  All actual logic is in SwiftUI (ShareView.swift) to maintain modern, declarative code.
//

import UIKit
import SwiftUI

@MainActor
final class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Minimal UIKit bridge: Just host the SwiftUI view
        // Pass extension context to SwiftUI for pure SwiftUI implementation
        let shareView = ShareView(extensionContext: extensionContext)
        let hostingController = UIHostingController(rootView: shareView)
        hostingController.view.backgroundColor = .clear
        
        // Embed SwiftUI view with minimal constraints
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }
}

