//
//  View+HideKeyboard.swift
//  UpQuest
//
//  Created by Enes Eken on 14.07.2025.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
