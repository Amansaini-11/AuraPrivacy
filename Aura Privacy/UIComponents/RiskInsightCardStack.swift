//
//  RiskInsightCardStack.swift
//  Aura Privacy
//
//  High-contrast risk cards using `GlassEffectContainer` for scan narratives.
//

import SwiftUI

struct RiskInsightCardStack: View {
    let insight: String
    var compact: Bool = false
    /// When set, only the first N cards are shown (e.g. dashboard list rows).
    var maxCards: Int? = nil
    
    private var models: [RiskInsightCardModel] {
        let all = RiskInsightParser.cards(from: insight)
        if let maxCards { return Array(all.prefix(maxCards)) }
        return all
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            ForEach(models) { model in
                RiskInsightCardRow(model: model, compact: compact)
            }
        }
    }
}

private struct RiskInsightCardRow: View {
    let model: RiskInsightCardModel
    var compact: Bool
    
    var body: some View {
        if compact {
            rowCore
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
        } else {
            GlassEffectContainer(cornerRadius: 20) {
                rowCore
            }
        }
    }
    
    private var rowCore: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: model.systemImage)
                .font(.system(size: compact ? 20 : 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.tint)
                .frame(width: compact ? 28 : 40, alignment: .center)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(model.title)
                    .font(.system(compact ? .subheadline : .headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(model.subtitle)
                    .font(.system(compact ? .caption : .subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(compact ? 3 : nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
