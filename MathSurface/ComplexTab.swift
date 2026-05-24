//
//  ComplexTab.swift
//  MathSurface
//
//  複素数タブ（軌跡 / 演算 / 冪乗）
//

import SwiftUI

enum ComplexSubMode: String, CaseIterable, Identifiable {
    case locus = "軌跡"
    case arithmetic = "演算"
    case power = "冪乗"
    var id: String { rawValue }
}

struct ComplexTab: View {
    @State private var subMode: ComplexSubMode = .locus

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Picker("モード", selection: $subMode) {
                    ForEach(ComplexSubMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 14)
                .padding(.top, 8)

                ScrollView {
                    Group {
                        switch subMode {
                        case .locus: ComplexLocusView()
                        case .arithmetic: ComplexArithmeticView()
                        case .power: ComplexPowerView()
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
