import SwiftUI

struct WrapSafeIngredientsView: View {
    let ingredients: [String]

    var body: some View {
        FlexibleView(
            data: ingredients,
            spacing: 8,
            alignment: .leading
        ) { ingredient in
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(primaryColor)
                Text(ingredient)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(primaryColor.opacity(0.08))
            )
        }
    }
}

/// Simple flexible wrap layout for chips
struct FlexibleView<Items: Collection, Content: View>: View where Items.Element: Hashable {
    let data: Items
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Items.Element) -> Content

    init(data: Items,
         spacing: CGFloat = 8,
         alignment: HorizontalAlignment = .leading,
         @ViewBuilder content: @escaping (Items.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geometry in
            ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
                ForEach(Array(data), id: \.self) { item in
                    content(item)
                        .padding(.all, 4)
                        .alignmentGuide(.leading, computeValue: { dimension in
                            if abs(width - dimension.width) > geometry.size.width {
                                width = 0
                                height -= dimension.height + spacing
                            }
                            let result = width
                            width -= dimension.width + spacing
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { _ in height })
                }
            }
        }
        .frame(height: intrinsicHeight(for: data))
    }

    private func intrinsicHeight(for data: Items) -> CGFloat {
        // Rough estimate; layout will adjust at runtime
        let rows = max(1, (data.count + 2) / 3)
        return CGFloat(rows) * 32
    }
}

