//
//  AnnouncementListView.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI

struct AnnouncementListView: View {
    @State private var selectedCategory: AnnouncementCategory = .all
    @StateObject private var viewModel = AnnouncementViewModel()

    var filteredAnnouncements: [AnnouncementItem] {
        if selectedCategory == .all {
            return viewModel.announcements
        }
        return viewModel.announcements.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack {
            Picker("分類", selection: $selectedCategory) {
                ForEach(AnnouncementCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("載入中...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("無法載入公告")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button(action: {
                        Task {
                            await viewModel.fetchAnnouncements()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("重試")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding()
            } else if filteredAnnouncements.isEmpty {
                VStack {
                    Image(systemName: "newspaper")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("沒有公告")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List(filteredAnnouncements) { announcement in
                    NavigationLink(destination: AnnouncementDetailView(url: announcement.url)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(announcement.title)
                                .font(.headline)
                                .lineLimit(2)

                            HStack {
                                Text(announcement.date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(announcement.category.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .refreshable {
                    await viewModel.fetchAnnouncements()
                }
            }
        }
        .navigationTitle("校園公告")
        .task {
            if viewModel.announcements.isEmpty {
                await viewModel.fetchAnnouncements()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnnouncementListView()
    }
}
