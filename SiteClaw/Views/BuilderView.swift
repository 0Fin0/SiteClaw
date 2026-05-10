//
//  BuilderView.swift
//  SiteClaw
//

import SwiftUI

struct BuilderView: View {
    @Bindable var studio: SiteClawStudio
    var continueToPreview: (() -> Void)?
    @State private var ownerNote = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HeroBuilderCard(studio: studio)
                    RestaurantIntakeView(studio: studio)
                    MenuCorrectionsView(studio: studio)
                    ContactCorrectionsView(studio: studio)
                    GenerateSiteButton(studio: studio)
                    if let continueToPreview {
                        DemoFlowCTA(
                            title: "Preview the Website",
                            detail: previewNextStepDetail,
                            actionTitle: "Open Preview",
                            systemImage: "iphone",
                            color: SiteClawTheme.coral,
                            action: continueToPreview
                        )
                    }
                    ConversationView(studio: studio, ownerNote: $ownerNote)
                }
                .padding(16)
            }
            .background(SiteClawTheme.background.ignoresSafeArea())
            .navigationTitle("Build Site")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        studio.loadVoiceExample()
                    } label: {
                        Image(systemName: "waveform")
                    }
                    .accessibilityLabel("Load voice example")
                }
            }
        }
    }

    private var previewNextStepDetail: String {
        studio.isDraftGenerated
            ? "The generated site is ready for owner review."
            : "Generate the restaurant website, then open the customer preview."
    }
}

private struct HeroBuilderCard: View {
    let studio: SiteClawStudio

    var body: some View {
        ClawCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checklist.checked")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(SiteClawTheme.coral)
                        .frame(width: 42, height: 42)
                        .background(SiteClawTheme.coral.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Build Site")
                            .font(.title2.weight(.semibold))
                        Text("Review the voice answers, fix any speech mistakes, then generate the website preview.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    LabelPill(title: studio.publishStatus, systemImage: studio.isPublished ? "checkmark.circle.fill" : "clock", color: studio.isPublished ? SiteClawTheme.mint : SiteClawTheme.coral)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: Double(studio.completionPercent), total: 100)
                        .tint(SiteClawTheme.mint)
                        .accessibilityLabel("Site completion")

                    HStack {
                        Label("\(studio.completionPercent)% complete", systemImage: "gauge.with.dots.needle.67percent")
                        Spacer()
                        Label(menuSummary, systemImage: "fork.knife")
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var menuSummary: String {
        studio.restaurant.menuItems.isEmpty
            ? "Menu needed"
            : "\(studio.restaurant.menuItems.count) menu item\(studio.restaurant.menuItems.count == 1 ? "" : "s")"
    }
}

private struct RestaurantIntakeView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Restaurant Basics",
                subtitle: "Fix anything the transcript got wrong before generating the preview."
            )

            ClawCard {
                VStack(spacing: 12) {
                    LabeledTextField(label: "Restaurant Name", placeholder: "Enter restaurant name", text: $studio.restaurant.name)
                    LabeledTextField(label: "Cuisine", placeholder: "Enter cuisine or restaurant type", text: $studio.restaurant.cuisine)
                    LabeledTextField(label: "City", placeholder: "Enter city", text: $studio.restaurant.neighborhood)
                    LabeledTextField(label: "Hours", placeholder: "Enter operating hours", text: $studio.restaurant.hours)
                    LabeledTextField(label: "Owner Story", placeholder: "Add what makes the restaurant special", text: $studio.restaurant.story, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
        }
    }
}

private struct MenuCorrectionsView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                SectionHeader(
                    title: "Featured Menu",
                    subtitle: "Edit item names, prices, and short descriptions."
                )
                Spacer(minLength: 0)

                Button {
                    studio.restaurant.menuItems.append(MenuItem(name: "", description: "", price: nil))
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(SiteClawTheme.mint)
                .accessibilityLabel("Add menu item")
            }

            ClawCard {
                if studio.restaurant.menuItems.isEmpty {
                    EmptyMenuPrompt {
                        studio.restaurant.menuItems.append(MenuItem(name: "", description: "", price: nil))
                    }
                } else {
                    VStack(spacing: 14) {
                        ForEach(studio.restaurant.menuItems.indices, id: \.self) { index in
                            MenuCorrectionRow(
                                index: index,
                                item: $studio.restaurant.menuItems[index],
                                priceText: priceBinding(for: index),
                                deleteAction: {
                                    deleteMenuItem(at: index)
                                }
                            )

                            if index != studio.restaurant.menuItems.indices.last {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func deleteMenuItem(at index: Int) {
        guard studio.restaurant.menuItems.indices.contains(index) else { return }
        studio.restaurant.menuItems.remove(at: index)
    }

    private func priceBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard studio.restaurant.menuItems.indices.contains(index),
                      let price = studio.restaurant.menuItems[index].price else {
                    return ""
                }

                return Self.priceFormatter.string(from: NSNumber(value: price)) ?? String(format: "%.2f", price)
            },
            set: { value in
                guard studio.restaurant.menuItems.indices.contains(index) else { return }
                let cleaned = value
                    .replacingOccurrences(of: "$", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                studio.restaurant.menuItems[index].price = cleaned.isEmpty ? nil : Double(cleaned)
            }
        )
    }

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter
    }()
}

private struct MenuCorrectionRow: View {
    let index: Int
    @Binding var item: MenuItem
    @Binding var priceText: String
    let deleteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("Item \(index + 1)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SiteClawTheme.ink)

                Spacer()

                Button(role: .destructive, action: deleteAction) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete menu item")
            }

            LazyVGrid(columns: Self.fieldColumns, spacing: 10) {
                LabeledTextField(label: "Name", placeholder: "Menu item name", text: $item.name)
                LabeledTextField(label: "Price", placeholder: "12.99", text: $priceText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }

            LabeledTextField(label: "Description", placeholder: "Add a short menu description", text: $item.description, axis: .vertical)
                .lineLimit(2...3)
        }
    }

    private static let fieldColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 10, alignment: .top)
    ]
}

private struct EmptyMenuPrompt: View {
    let addAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No menu items captured yet.")
                .font(.headline)
            Text("Add items manually or return to Talk and capture the menu answer again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: addAction) {
                Label("Add First Item", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(SiteClawTheme.mint)
        }
    }
}

private struct ContactCorrectionsView: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Visit Details",
                subtitle: "Add customer-facing contact details when the owner provides them."
            )

            ClawCard {
                VStack(spacing: 12) {
                    LabeledTextField(label: "Street Address", placeholder: "Enter street address", text: $studio.restaurant.streetAddress)

                    LazyVGrid(columns: Self.fieldColumns, spacing: 10) {
                        LabeledTextField(label: "City", placeholder: "Enter city", text: $studio.restaurant.neighborhood)
                        LabeledTextField(label: "State", placeholder: "State", text: $studio.restaurant.state)
                        LabeledTextField(label: "ZIP", placeholder: "ZIP code", text: $studio.restaurant.postalCode)
                    }

                    LabeledTextField(label: "Phone", placeholder: "Phone number", text: $studio.restaurant.phone)
                }
            }
        }
    }

    private static let fieldColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 10, alignment: .top)
    ]
}

private struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ConversationView: View {
    @Bindable var studio: SiteClawStudio
    @Binding var ownerNote: String
    @State private var showsRecentNotes = false

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(
                title: "Optional Notes",
                subtitle: "Add one more owner instruction without leaving the correction screen."
            )

            ClawCard {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        TextField("Add an owner note...", text: $ownerNote, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...3)

                        Button {
                            studio.applyQuickUpdate(ownerNote)
                            ownerNote = ""
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                        .disabled(ownerNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("Apply owner note")
                    }

                    if !studio.messages.isEmpty {
                        DisclosureGroup("Recent Notes", isExpanded: $showsRecentNotes) {
                            VStack(spacing: 10) {
                                ForEach(studio.messages.suffix(5)) { message in
                                    MessageBubble(message: message)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }
}

private struct MessageBubble: View {
    let message: BuilderMessage

    var isOwner: Bool {
        message.role == .owner
    }

    var body: some View {
        HStack {
            if isOwner { Spacer(minLength: 36) }

            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(isOwner ? .white : SiteClawTheme.ink)
                .padding(12)
                .background(isOwner ? SiteClawTheme.coral : SiteClawTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.black.opacity(isOwner ? 0 : 0.06), lineWidth: 1)
                }

            if !isOwner { Spacer(minLength: 36) }
        }
    }
}

private struct GenerateSiteButton: View {
    @Bindable var studio: SiteClawStudio

    var body: some View {
        Button {
            studio.generateDraft()
        } label: {
            Label("Generate Restaurant Website", systemImage: "sparkles")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(SiteClawTheme.coral)
    }
}

#Preview {
    BuilderView(studio: SiteClawStudio.preview)
}
