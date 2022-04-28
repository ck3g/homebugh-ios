//
//  View+Ext.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 05.10.2021.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
