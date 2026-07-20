//
//  EmergencyView.swift
//  NUTCParkingSpace
//

import SwiftUI
import UIKit

private struct EmergencyContact: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let icon: String
    let color: Color
    let desc: String
}

struct EmergencyView: View {
    // 電話為台中科大三民校區實際分機（校安中心為校園安全通報專線）
    private let contacts: [EmergencyContact] = [
        EmergencyContact(name: "校安中心",   phone: "04-22195999", icon: "shield.fill",                        color: .red,    desc: "校園安全通報專線"),
        EmergencyContact(name: "衛生保健組", phone: "04-22195234", icon: "cross.circle.fill",                  color: .green,  desc: "健康中心・急救協助"),
        EmergencyContact(name: "生活輔導組", phone: "04-22195210", icon: "person.2.fill",                      color: .blue,   desc: "生活・住宿・急難協助"),
        EmergencyContact(name: "學校總機",   phone: "04-22195678", icon: "building.columns.fill",              color: .teal,   desc: "各單位轉接代表號"),
        EmergencyContact(name: "消防救護",   phone: "119",          icon: "flame.fill",                        color: .orange, desc: "火災、緊急救護"),
        EmergencyContact(name: "警察報案",   phone: "110",          icon: "star.circle.fill",                  color: .indigo, desc: "治安事件報案"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sosBanner
                ForEach(contacts) { c in
                    contactCard(c)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("緊急聯絡")
    }

    private var sosBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "sos.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text("緊急聯絡").font(.title2).bold().foregroundColor(.white)
                Text("遇到緊急狀況請立即撥打").font(.subheadline).foregroundColor(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.red, Color(red: 0.8, green: 0.1, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .red.opacity(0.4), radius: 14, y: 5)
    }

    private func contactCard(_ c: EmergencyContact) -> some View {
        Link(destination: URL(string: "tel:\(c.phone.filter(\.isNumber))")!) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(c.color.opacity(0.15)).frame(width: 52, height: 52)
                    Image(systemName: c.icon).font(.title2).foregroundColor(c.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.name).font(.headline).foregroundColor(.primary)
                    Text(c.desc).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(c.phone)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(c.color)
                        .monospacedDigit()
                    Image(systemName: "phone.fill")
                        .font(.caption).foregroundColor(c.color)
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        EmergencyView()
    }
}
