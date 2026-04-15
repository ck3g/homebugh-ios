//
//  HomeBughApp.swift
//  HomeBugh
//
//  Created by Vitali Tatarintev on 01.10.20.
//

import SwiftUI

@main
struct HomeBughApp: App {

    let repositoryProvider: RepositoryProvider

    init() {
        do {
            repositoryProvider = try RepositoryProvider.makeDefault()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(repositoryProvider)
                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
        }
    }
}

extension UIApplication {
    func addTapGestureRecognizer() {
        guard let window = windows.first else { return }
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        window.addGestureRecognizer(tapGesture)
    }
}

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
