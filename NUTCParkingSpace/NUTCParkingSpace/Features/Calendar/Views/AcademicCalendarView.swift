//
//  AcademicCalendarView.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI

struct AcademicCalendarView: View {
    let events = AcademicCalendarData.events
    @State private var isExporting = false
    @State private var exportMessage: String?
    @State private var showAlert = false

    private let today = Calendar.current.startOfDay(for: Date())

    var body: some View {
        List(events) { event in
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(isPast(event.date) ? .secondary : .primary)
                HStack {
                    Text(event.date.formatted(.dateTime.month().day().locale(Locale(identifier: "zh_Hant_TW"))))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    typeBadge(event.type)
                    if !isPast(event.date) {
                        let days = daysUntil(event.date)
                        Text(days == 0 ? "今天" : "\(days) 天後")
                            .font(.caption2)
                            .foregroundColor(days <= 3 ? .red : .blue)
                    }
                }
            }
            .opacity(isPast(event.date) ? 0.5 : 1)
        }
        .navigationTitle("學術行事曆")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await exportCalendar() }
                } label: {
                    if isExporting {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
                .disabled(isExporting)
            }
        }
        .alert("匯出行事曆", isPresented: $showAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(exportMessage ?? "")
        }
    }

    private func exportCalendar() async {
        isExporting = true
        do {
            let count = try await CalendarExportService.exportAll()
            exportMessage = count > 0
                ? "已將 \(count) 筆行程加入「NUTC 學年行事曆」"
                : "所有行程已存在，無需重複加入"
        } catch {
            exportMessage = error.localizedDescription
        }
        isExporting = false
        showAlert = true
    }

    private func isPast(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) < today
    }

    private func daysUntil(_ date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day],
            from: today, to: Calendar.current.startOfDay(for: date)).day ?? 0)
    }

    @ViewBuilder
    private func typeBadge(_ type: EventType) -> some View {
        let (color, _): (Color, String) = {
            switch type {
            case .exam:         return (.red, "考試")
            case .holiday:      return (.green, "放假")
            case .registration: return (.orange, "加退選")
            case .general:      return (.blue, "其他")
            }
        }()
        Text(type.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

#Preview {
    NavigationStack {
        AcademicCalendarView()
    }
}
