//
//  DiningView.swift
//  NUTCParkingSpace
//

import SwiftUI

struct DiningView: View {
    let restaurants = RestaurantData.restaurants

    var body: some View {
        List(restaurants) { restaurant in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(restaurant.name)
                        .font(.headline)
                    Spacer()
                    Text(restaurant.category)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(restaurant.address)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(restaurant.hours)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(restaurant.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }

                if let note = restaurant.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("育才街美食")
    }
}

#Preview {
    NavigationStack {
        DiningView()
    }
}
