//
//  RemoveButtonView.swift
//  yummy
//
//  Created by Trae AI on 2025/01/11.
//

import SwiftUI

struct RemoveButtonView: View {
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: {
            onRemove()
        }) {
            Image(systemName: "minus.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.red)
        }
    }
}

#Preview {
    RemoveButtonView {
        print("Remove tapped")
    }
    .padding()
}
