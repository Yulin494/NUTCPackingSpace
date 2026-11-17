//
//  PixelAcademicCalendarView.swift
//  NUTCParkingSpace
//
//  像素模式學術行事曆。資料來源、匯出、自動捲動沿用 AcademicCalendarView。
//

import SwiftUI

struct PixelAcademicCalendarView: View {
    let events = AcademicCalendarData.events
    @State private var isExporting = false
    @State private var exportMessage: String?
    @State private var showAlert = false

    private let today = Calendar.current.startOfDay(for: Date())

    private var firstUpcomingID: AcademicEvent.ID? {
        events.first { !isPast($0.date) }?.id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if events.isEmpty {
                    VStack(spacing: 12) {
                        NamePlate(text: "沒有行程")
                        Text("目前沒有行事曆資料")
                            .font(.system(size: 15)).foregroundStyle(PixelPalette.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .pixelFrame()
                    .padding(16)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(events) { event in
                            row(event)
                                .id(event.id)
                        }
                    }
                    .padding(16)
                }
            }
            .onAppear {
                if let target = firstUpcomingID {
                    DispatchQueue.main.async {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
            }
        }
        .foregroundStyle(PixelPalette.ink)
        .background(PixelPalette.paper2.ignoresSafeArea())
        .navigationTitle("學術行事曆")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PixelPalette.paper2, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("學術行事曆").pixelFont(size: PixelMetrics.FontSize.medium)
                    .foregroundStyle(PixelPalette.ink)
                    .accessibilityHidden(true)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await exportCalendar() }
                } label: {
                    Group {
                        if isExporting {
                            Text("匯出中").pixelFont(size: PixelMetrics.FontSize.small)
                        } else {
                            Text("加入").pixelFont(size: PixelMetrics.FontSize.small)
                        }
                    }
                    .foregroundStyle(PixelPalette.ink)
                    .frame(minWidth: 44, minHeight: 28)
                }
                .buttonStyle(PixelButtonStyle(
                    fill: PixelPalette.gold,
                    contentPadding: EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)))
                .disabled(isExporting)
                .accessibilityLabel("將行事曆加入系統行事曆")
            }
        }
        .alert("匯出行事曆", isPresented: $showAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(exportMessage ?? "")
        }
    }

    private func row(_ event: AcademicEvent) -> some View {
        let past = isPast(event.date)
        let days = daysUntil(event.date)
        return VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(past ? PixelPalette.muted : PixelPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text(event.date.formatted(.dateTime.month().day().locale(Locale(identifier: "zh_Hant_TW"))))
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(PixelPalette.muted)
                Spacer(minLength: 4)
                typeBadge(event.type)
                if !past {
                    Text(days == 0 ? "今天" : "\(days) 天後")
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(days <= 3 ? PixelPalette.red : PixelPalette.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .pixelFrame(fill: past ? PixelPalette.paper : (days == 0 ? PixelPalette.gold : PixelPalette.paper))
        .opacity(past ? 0.7 : 1)
        .accessibilityElement(children: .combine)
    }

    private func typeBadge(_ type: EventType) -> some View {
        let fill: Color = {
            switch type {
            case .exam:         return PixelPalette.red
            case .holiday:      return PixelPalette.grass
            case .registration: return PixelPalette.orange
            case .general:      return PixelPalette.water
            }
        }()
        let text: Color = (type == .exam) ? PixelPalette.paper : PixelPalette.ink
        return Text(type.rawValue)
            .pixelFont(size: PixelMetrics.FontSize.small)
            .foregroundStyle(text)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .pixelFrame(fill: fill)
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
}

#Preview {
    NavigationStack { PixelAcademicCalendarView() }
}
