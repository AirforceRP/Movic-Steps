//
//  LanguageSelectionView.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/23/25.
//  9/23/25 - Created language selection interface for multi-language support
//  100+ Lines of Code
//

import SwiftUI

struct LanguageSelectionView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedLanguage: String = LocalizationManager.shared.getCurrentLanguage()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SupportedLanguage.allCases, id: \.rawValue) { language in
                    LanguageRow(
                        language: language,
                        isSelected: selectedLanguage == language.rawValue
                    ) {
                        selectedLanguage = language.rawValue
                        localizationManager.setLanguage(language.rawValue)
                    }
                }
            }
            .navigationTitle("Language Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LanguageRow: View {
    let language: SupportedLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.flag)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(language.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LanguageSelectionView()
}
