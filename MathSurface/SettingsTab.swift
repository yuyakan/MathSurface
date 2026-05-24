//
//  SettingsTab.swift
//  MathSurface
//

import SwiftUI

enum ThemePreference: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "システム設定に従う"
        case .light:  "ライト"
        case .dark:   "ダーク"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max.fill"
        case .dark:   "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

struct SettingsTab: View {
    @AppStorage("themePreference") private var themeRaw: String = ThemePreference.system.rawValue

    private var theme: Binding<ThemePreference> {
        Binding(
            get: { ThemePreference(rawValue: themeRaw) ?? .system },
            set: { themeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    sectionHeader("外観")
                    themeCard
                    sectionHeader("情報")
                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(backgroundGradient)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var aboutCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                LicensesView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "doc.text")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.indigo)
                        .frame(width: 28)
                    Text("ライセンス")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var themeCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(ThemePreference.allCases.enumerated()), id: \.element.id) { index, option in
                themeRow(option)
                if index < ThemePreference.allCases.count - 1 {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func themeRow(_ option: ThemePreference) -> some View {
        Button {
            theme.wrappedValue = option
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .frame(width: 28)
                Text(option.label)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                if theme.wrappedValue == option {
                    Image(systemName: "checkmark")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.indigo)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
