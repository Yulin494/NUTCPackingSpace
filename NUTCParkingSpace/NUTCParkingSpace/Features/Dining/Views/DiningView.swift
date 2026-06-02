//
//  DiningView.swift
//  NUTCParkingSpace
//

import SwiftUI
import UIKit

struct DiningView: View {
    let restaurants = RestaurantData.restaurants
    @State private var selectedCategory: String = "全部"

    private var categories: [String] {
        ["全部"] + Array(Set(restaurants.map(\.category))).sorted()
    }

    private var filtered: [Restaurant] {
        selectedCategory == "全部" ? restaurants : restaurants.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 分類 Chip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            CategoryChip(
                                label: cat,
                                isSelected: selectedCategory == cat,
                                color: .orange,
                                action: { withAnimation(.spring(response: 0.3)) { selectedCategory = cat } }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(filtered) { r in
                        RestaurantCard(restaurant: r)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("育才街美食")
    }
}

struct RestaurantCard: View {
    let restaurant: Restaurant

    private var iconAndColor: (String, Color) {
        let c = restaurant.category
        if c.contains("自助餐")                         { return ("fork.knife.circle.fill", .orange) }
        if c.contains("便當")                           { return ("takeoutbag.and.cup.and.straw.fill", .brown) }
        if c.contains("韓式")                           { return ("flame.fill", .red) }
        if c.contains("滷味")                           { return ("drop.fill", .brown) }
        if c.contains("燒肉")                           { return ("flame.fill", .orange) }
        if c.contains("冰品")                           { return ("snowflake", .blue) }
        if c.contains("咖啡") || c.contains("義大利麵") { return ("cup.and.saucer.fill", .brown) }
        if c.contains("包子") || c.contains("早餐")     { return ("sunrise.fill", .yellow) }
        if c.contains("串燒") || c.contains("小吃")     { return ("fork.knife", .red) }
        if c.contains("甜食") || c.contains("點心")     { return ("heart.fill", .pink) }
        return ("fork.knife.circle.fill", .orange)
    }

    var body: some View {
        let (icon, color) = iconAndColor

        VStack(alignment: .leading, spacing: 10) {
            // 頂部 icon 區
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(height: 70)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.subheadline).bold()
                    .lineLimit(1)
                Text(restaurant.category)
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(color.opacity(0.12))
                    .foregroundColor(color)
                    .clipShape(Capsule())
                HStack(spacing: 3) {
                    Image(systemName: "clock").font(.caption2).foregroundColor(.secondary)
                    Text(restaurant.hours).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                }
                if let note = restaurant.note {
                    Text(note).font(.caption2).foregroundColor(.secondary).lineLimit(2)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        DiningView()
    }
}
