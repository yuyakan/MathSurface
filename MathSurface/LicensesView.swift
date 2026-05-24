//
//  LicensesView.swift
//  MathSurface
//

import SwiftUI

struct LicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(LicenseEntry.all) { entry in
                    licenseCard(entry)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(backgroundGradient)
        .navigationTitle("ライセンス")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func licenseCard(_ entry: LicenseEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.name)
                    .font(.headline)
                Spacer()
                Text(entry.license)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.indigo.opacity(0.15), in: Capsule())
            }
            if let url = entry.url {
                Link(destination: url) {
                    Label(url.absoluteString, systemImage: "link")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            }
            Text(entry.copyright)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Divider()
            Text(entry.licenseText)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
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

struct LicenseEntry: Identifiable {
    let id: String
    let name: String
    let license: String
    let copyright: String
    let url: URL?
    let licenseText: String

    static let all: [LicenseEntry] = [
        LicenseEntry(
            id: "expression",
            name: "Expression",
            license: "MIT",
            copyright: "Copyright (c) 2016 Nick Lockwood",
            url: URL(string: "https://github.com/nicklockwood/Expression"),
            licenseText: """
            MIT License

            Copyright (c) 2016 Nick Lockwood

            Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
            """
        )
    ]
}
