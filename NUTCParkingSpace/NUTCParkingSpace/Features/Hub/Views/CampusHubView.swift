//
//  CampusHubView.swift
//  NUTCParkingSpace
//

import SwiftUI
import UIKit
import NUTCParkingShared

struct CampusHubView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 行事曆倒數橫幅
                    calendarBanner

                    // 資訊查詢 2欄
                    sectionGrid(title: "資訊查詢", items: infoItems)

                    // 生活服務 2欄
                    sectionGrid(title: "生活服務", items: lifeItems)

                    // 學校系統 2欄
                    sectionGrid(title: "學校系統", items: systemItems)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("校園服務")
        }
    }

    // MARK: - Calendar Banner（漸層卡片）
    private var calendarBanner: some View {
        NavigationLink(destination: AcademicCalendarView()) {
            HStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 36))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 4) {
                    if let next = SharedAcademicCalendar.nextEvent() {
                        let days = SharedAcademicCalendar.daysUntil(next)
                        Text(next.title)
                            .font(.headline).bold().foregroundColor(.white)
                        Text(days == 0 ? "就是今天！" : "\(days) 天後")
                            .font(.subheadline).foregroundColor(.white.opacity(0.85))
                    } else {
                        Text("學術行事曆").font(.headline).bold().foregroundColor(.white)
                        Text("查看全年行程").font(.subheadline).foregroundColor(.white.opacity(0.85))
                    }
                }

                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.39, green: 0.40, blue: 0.95),
                             Color(red: 0.62, green: 0.35, blue: 0.92)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.35), radius: 14, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grid Section
    private func sectionGrid(title: String, items: [HubGridItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3).bold()
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(items) { item in
                    item.view
                }
            }
        }
    }

    // MARK: - Data
    private var infoItems: [HubGridItem] { [
        HubGridItem(id: "ann",  view: AnyView(gridButton(icon: "megaphone.fill",      title: "校園公告",    sub: "最新消息與通知",       color: .blue,   dest: AnyView(AnnouncementListView())))),
        HubGridItem(id: "cal",  view: AnyView(gridButton(icon: "calendar",             title: "學術行事曆",  sub: "考試、放假、截止",      color: .purple, dest: AnyView(AcademicCalendarView())))),
        HubGridItem(id: "wx",   view: AnyView(gridButton(icon: "cloud.sun.fill",       title: "台中天氣",    sub: "即時天氣預報",         color: .orange, dest: AnyView(WeatherView())))),
        HubGridItem(id: "lib",  view: AnyView(gridButton(icon: "books.vertical.fill",  title: "圖書館",      sub: "開放時間 · 館藏",      color: .green,  dest: AnyView(LibraryView())))),
    ] }

    private var lifeItems: [HubGridItem] { [
        HubGridItem(id: "din",  view: AnyView(gridButton(icon: "fork.knife",           title: "育才街美食",  sub: "周邊餐廳推薦",         color: .orange, dest: AnyView(DiningView())))),
        HubGridItem(id: "bike", view: AnyView(gridButton(icon: "bicycle",              title: "YouBike",     sub: "附近可借站點",         color: .teal,   dest: AnyView(YouBikeView())))),
    ] }

    private var systemItems: [HubGridItem] { [
        HubGridItem(id: "portal", view: AnyView(gridButton(icon: "person.crop.rectangle.fill", title: "學校系統", sub: "選課 · 成績 · ePortal", color: .indigo, dest: AnyView(SchoolPortalView())))),
        HubGridItem(id: "sos",    view: AnyView(gridButton(icon: "phone.fill",         title: "緊急聯絡",    sub: "校安 · 健康 · 警衛",   color: .red,    dest: AnyView(EmergencyView())))),
    ] }

    private func gridButton(icon: String, title: String, sub: String, color: Color, dest: AnyView) -> some View {
        NavigationLink(destination: dest) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline).bold().foregroundColor(.primary)
                    Text(sub).font(.caption2).foregroundColor(.secondary).lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct HubGridItem: Identifiable {
    let id: String
    let view: AnyView
}

#Preview {
    CampusHubView()
}
