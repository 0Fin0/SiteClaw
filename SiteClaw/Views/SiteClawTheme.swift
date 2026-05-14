//
//  SiteClawTheme.swift
//  SiteClaw
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum SiteClawTheme {
    static let navy = Color(red: 0.05, green: 0.10, blue: 0.17)
    static let ink = Color.primary
    static let coral = Color(red: 0.91, green: 0.31, blue: 0.24)
    static let gold = Color(red: 0.91, green: 0.61, blue: 0.18)
    static let mint = Color(red: 0.16, green: 0.62, blue: 0.42)
    static let sky = Color(red: 0.12, green: 0.45, blue: 0.96)
    static let background: Color = {
        #if os(iOS)
        Color(uiColor: .systemGroupedBackground)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }()
    static let surface: Color = {
        #if os(iOS)
        Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.white
        #endif
    }()
    static let elevatedSurface: Color = {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #elseif os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color.white
        #endif
    }()
    static let separator = Color.primary.opacity(0.08)
    static let softStroke = Color.primary.opacity(0.06)
    static let tabBarClearance: CGFloat = 132
    static let primaryActionClearance: CGFloat = 112
    static let topScrollResetClearance: CGFloat = {
        #if os(iOS)
        20
        #else
        0
        #endif
    }()
    static let floatingActionBottomPadding: CGFloat = {
        #if os(iOS)
        36
        #else
        6
        #endif
    }()
    static let navigationContentTopInset: CGFloat = {
        #if os(iOS)
        0
        #else
        16
        #endif
    }()
    static let iconContainerSize: CGFloat = 38

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
        static let xLarge: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 6
        static let card: CGFloat = 8
        static let control: CGFloat = 8
        static let floating: CGFloat = 22
    }

    enum Shadow {
        static let cardColor = Color.black.opacity(0.05)
        static let floatingColor = Color.black.opacity(0.14)
    }
}

struct AppSurface<Content: View>: View {
    var gradient: [Color] = []
    var content: Content

    init(gradient: [Color] = [], @ViewBuilder content: () -> Content) {
        self.gradient = gradient
        self.content = content()
    }

    var body: some View {
        ZStack {
            SiteClawTheme.background
                .ignoresSafeArea()
            if !gradient.isEmpty {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            content
        }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(SiteClawTheme.ink)
            Text(subtitle)
                .font(.footnote)
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
            .padding(SiteClawTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SiteClawTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: SiteClawTheme.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SiteClawTheme.Radius.card, style: .continuous)
                    .stroke(SiteClawTheme.separator, lineWidth: 1)
            }
    }
}

struct IconBadge: View {
    let systemImage: String
    let color: Color
    var size: CGFloat = SiteClawTheme.iconContainerSize
    var isDecorative = true

    var body: some View {
        Image(systemName: systemImage)
            .font(.headline.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: SiteClawTheme.Radius.control, style: .continuous))
            .accessibilityHidden(isDecorative)
    }
}

struct StatusPill: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.footnote.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .accessibilityElement(children: .combine)
    }
}

struct LabelPill: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        StatusPill(title: title, systemImage: systemImage, color: color)
    }
}

struct SectionDisclosureRow: View {
    let title: String
    let subtitle: String
    let statusTitle: String
    let statusImage: String
    let statusColor: Color
    let systemImage: String
    let tint: Color
    let isExpanded: Bool

    var body: some View {
        HStack(alignment: .center, spacing: SiteClawTheme.Spacing.medium) {
            IconBadge(systemImage: systemImage, color: tint)

            VStack(alignment: .leading, spacing: SiteClawTheme.Spacing.xxSmall) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(SiteClawTheme.ink)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: SiteClawTheme.Spacing.small)

            VStack(alignment: .trailing, spacing: SiteClawTheme.Spacing.xSmall) {
                StatusPill(title: statusTitle, systemImage: statusImage, color: statusColor)
                    .labelStyle(.titleAndIcon)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
        }
        .padding(SiteClawTheme.Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(SiteClawTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: SiteClawTheme.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SiteClawTheme.Radius.card, style: .continuous)
                .stroke(SiteClawTheme.separator, lineWidth: 1)
        }
    }
}

struct GlassFloatingContainer<Content: View>: View {
    var cornerRadius = SiteClawTheme.Radius.floating
    var content: Content

    init(cornerRadius: CGFloat = SiteClawTheme.Radius.floating, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            glassBody
        } else {
            materialBody
        }
        #else
        materialBody
        #endif
    }

    private var materialBody: some View {
        content
            .padding(10)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: SiteClawTheme.Shadow.floatingColor, radius: 18, y: 8)
    }

    #if os(iOS)
    @available(iOS 26.0, *)
    private var glassBody: some View {
        content
            .padding(10)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            .shadow(color: SiteClawTheme.Shadow.floatingColor, radius: 18, y: 8)
    }
    #endif
}

struct PrimaryBottomAction: View {
    let title: String
    let detail: String?
    let systemImage: String
    var color: Color = SiteClawTheme.coral
    var isDisabled = false
    let action: () -> Void

    init(
        title: String,
        detail: String? = nil,
        systemImage: String,
        color: Color = SiteClawTheme.coral,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.color = color
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        GlassFloatingContainer {
            VStack(spacing: SiteClawTheme.Spacing.xSmall) {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(color)
                .disabled(isDisabled)

                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, SiteClawTheme.floatingActionBottomPadding)
    }
}

struct DemoFlowCTA: View {
    let title: String
    let detail: String
    let actionTitle: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    IconBadge(systemImage: systemImage, color: color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(SiteClawTheme.ink)
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button(action: action) {
                    Label(actionTitle, systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(color)
            }
        }
    }
}

private struct SiteClawNavigationChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SiteClawTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        #else
        content
        #endif
    }
}

private struct SiteClawTabBarChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .toolbarBackground(SiteClawTheme.elevatedSurface, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        #else
        content
        #endif
    }
}

extension View {
    func siteClawNavigationChrome() -> some View {
        modifier(SiteClawNavigationChromeModifier())
    }

    func siteClawTabBarChrome() -> some View {
        modifier(SiteClawTabBarChromeModifier())
    }
}
