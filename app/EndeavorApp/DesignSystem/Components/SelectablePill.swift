import SwiftUI

struct SelectablePill: View {
    let title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.branding.inputLabel)
                .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.cardBackground : Color.inputBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.brandPrimary : Color.clear, lineWidth: 1)
                )
        }
    }
}

// Helper view to arrange pills in a flow layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(subviews: subviews, containerWidth: proposal.width ?? 0)
        let height = rows.last?.maxY ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(subviews: subviews, containerWidth: bounds.width)
        
        for row in rows {
            for element in row.elements {
                element.subview.place(at: CGPoint(x: bounds.minX + element.x, y: bounds.minY + element.y), proposal: .unspecified)
            }
        }
    }

    struct Row {
        var elements: [Element]
        var maxY: CGFloat
    }

    struct Element {
        var subview: LayoutSubview
        var x: CGFloat
        var y: CGFloat
    }

    func arrangeSubviews(subviews: Subviews, containerWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentRowElements: [Element] = []
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > containerWidth {
                // New row
                rows.append(Row(elements: currentRowElements, maxY: currentY + currentRowHeight))
                currentX = 0
                currentY += currentRowHeight + spacing
                currentRowElements = []
                currentRowHeight = 0
            }

            currentRowElements.append(Element(subview: subview, x: currentX, y: currentY))
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }

        if !currentRowElements.isEmpty {
             rows.append(Row(elements: currentRowElements, maxY: currentY + currentRowHeight))
        }

        return rows
    }
}

struct SelectablePill_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FlowLayout {
                SelectablePill(title: "FinTech", isSelected: false, action: {})
                SelectablePill(title: "SaaS", isSelected: true, action: {})
                SelectablePill(title: "E-commerce", isSelected: false, action: {})
                SelectablePill(title: "HealthTech", isSelected: false, action: {})
                SelectablePill(title: "VC", isSelected: true, action: {})
                SelectablePill(title: "Mobile", isSelected: false, action: {})
            }
        }
        .padding()
        .background(Color.background)
    }
}
