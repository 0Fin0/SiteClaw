//
//  SiteClawTheme.swift
//  SiteClaw
//

import SwiftUI

enum SiteClawTheme {
    static let navy = Color(red: 0.05, green: 0.10, blue: 0.17)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.15)
    static let coral = Color(red: 0.91, green: 0.31, blue: 0.24)
    static let gold = Color(red: 0.96, green: 0.67, blue: 0.25)
    static let mint = Color(red: 0.18, green: 0.63, blue: 0.55)
    static let sky = Color(red: 0.22, green: 0.54, blue: 0.83)
    static let background = Color(red: 0.97, green: 0.97, blue: 0.94)
    static let surface = Color.white
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(SiteClawTheme.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ClawCard<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SiteClawTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black.opacity(0.06), lineWidth: 1)
            }
    }
}

struct LabelPill: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
