import SwiftUI

/// AsyncImage with a consistent placeholder, used for candidate photos and municipality logos.
struct RemoteImage: View {
    let url: URL?
    var placeholderSystemImage: String = "person.crop.circle.fill"
    var size: CGFloat = 56
    var cornerRadius: CGFloat? = nil  // nil = circle

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.2))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholder
            default:
                ZStack {
                    Color.secondary.opacity(0.1)
                    ProgressView()
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay(shape.stroke(Color.secondary.opacity(0.15), lineWidth: 1))
        .accessibilityHidden(true)
    }

    private var shape: AnyShape {
        if let cornerRadius {
            AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            AnyShape(Circle())
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            Image(systemName: placeholderSystemImage)
                .resizable()
                .scaledToFit()
                .padding(size * 0.2)
                .foregroundStyle(.secondary)
        }
    }
}
