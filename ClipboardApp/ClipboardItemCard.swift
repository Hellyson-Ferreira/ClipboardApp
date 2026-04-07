import SwiftUI
import AppKit

struct ClipboardItemCard: View {
    let item: ClipboardItem
    let isFirst: Bool
    let onPin: () -> Void
    let onDelete: () -> Void
    let onCopy: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                contentPreview
                    .frame(maxWidth: .infinity)
                    .frame(height: 86)
                    .clipped()

                cardFooter
            }
            .background(Color(hex: "#1E1E1E"))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(borderColor, lineWidth: isFirst ? 1.5 : 1)
            )

            if isHovered {
                hoverActions.padding(5)
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { onCopy() }
    }

    private var borderColor: Color {
        if isFirst   { return Color(hex: "#30D158").opacity(0.65) }
        if isHovered { return .white.opacity(0.18) }
        return .white.opacity(0.07)
    }

    // MARK: - Content Preview

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .image: imagePreview
        case .url:   urlPreview
        case .text:  textPreview
        case .file:  filePreview
        }
    }

    private var imagePreview: some View {
        ZStack {
            Color(hex: "#141414")
            if let img = item.imageContent {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.1))
            }
        }
    }

    private var urlPreview: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .bold))
                Text("Link")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(Color(hex: "#0A84FF"))

            Text(item.textContent ?? "")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(4)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var textPreview: some View {
        let text = item.textContent ?? ""
        let size: CGFloat = text.count > 40 ? 9 : (text.count > 20 ? 11 : 13)

        return Text(text)
            .font(.system(size: size, weight: .medium))
            .foregroundColor(.white.opacity(0.88))
            .lineLimit(6)
            .multilineTextAlignment(.leading)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var filePreview: some View {
        VStack(spacing: 6) {
            Image(systemName: "doc.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.25))
            Text(item.textContent ?? "")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Card Footer

    private var cardFooter: some View {
        HStack(spacing: 4) {
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Color(hex: "#30D158"))
            }

            Text(item.sourceApp)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.3))
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(item.date.relativeShort)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color(hex: "#181818"))
    }

    // MARK: - Hover Actions (pin + delete)

    private var hoverActions: some View {
        HStack(spacing: 4) {
            overlayBtn(
                icon: "trash",
                color: Color(hex: "#FF453A"),
                action: onDelete
            )
            overlayBtn(
                icon: item.isPinned ? "pin.slash.fill" : "pin.fill",
                color: item.isPinned ? Color(hex: "#30D158") : .white.opacity(0.75),
                action: onPin
            )
        }
    }

    @ViewBuilder
    private func overlayBtn(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(color)
                .padding(5)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}
