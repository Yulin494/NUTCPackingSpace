//
//  PixelHomeworkView.swift
//  NUTCParkingSpace
//
//  像素模式作業追蹤頁與「新增作業」表單。資料操作（新增、刪除、完成勾選、
//  已完成摺疊、提醒同步、autoPresentAdd）與 HomeworkView / AddHomeworkView 一致。
//

import SwiftUI
import SwiftData

// MARK: - 共用小元件（僅本檔使用）

/// 子頁骨架：紙色背景、像素標題、紙色導覽列底
private struct HwPxChrome: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .background(PixelPalette.paper2.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .pixelFont(size: PixelMetrics.FontSize.medium)
                        .foregroundStyle(PixelPalette.ink)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .toolbarBackground(PixelPalette.paper2, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

/// 狀態章：形狀 + 文字 + 底色（不靠顏色單獨表示）
private struct HwPxStatusTag: View {
    let icon: PixelIconKind
    let text: String
    let fill: Color
    let textColor: Color

    var body: some View {
        HStack(spacing: 4) {
            PixelIcon(kind: icon, scale: 1)
            Text(text).pixelFont(size: PixelMetrics.FontSize.small).lineLimit(1)
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .pixelFrame(fill: fill)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

private struct HwPxPlus: View {
    var body: some View {
        ZStack {
            Rectangle().frame(width: 16, height: 4)
            Rectangle().frame(width: 4, height: 16)
        }
        .foregroundStyle(PixelPalette.ink)
        .frame(width: 20, height: 20)
        .accessibilityHidden(true)
    }
}

private struct HwPxBlock<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NamePlate(text: title)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelFrame(fill: PixelPalette.paper)
        }
    }
}

private struct HwPxFieldFrame: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17))
            .foregroundStyle(PixelPalette.ink)
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .pixelFrame(fill: PixelPalette.paper)
    }
}

// MARK: - 作業頁

struct PixelHomeworkView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddHomework = false
    @State private var showCompleted = false
    @State private var homeworkToDelete: HomeworkItem?
    @Query(sort: \HomeworkItem.dueDate) var homeworks: [HomeworkItem]

    /// 由外部帶入，進頁後自動開啟新增表單（同 HomeworkView.autoPresentAdd）
    var autoPresentAdd: Bool = false

    private var pending: [HomeworkItem] { homeworks.filter { !$0.isCompleted } }
    private var completeds: [HomeworkItem] { homeworks.filter { $0.isCompleted } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if pending.isEmpty && completeds.isEmpty {
                    emptyStateCard
                } else {
                    NamePlate(text: "待完成 (\(pending.count))",
                              fill: PixelPalette.gold, textColor: PixelPalette.ink)

                    if pending.isEmpty {
                        allDoneCard
                    } else {
                        ForEach(pending) { homework in
                            card(homework)
                        }
                    }

                    if !completeds.isEmpty {
                        completedSection
                    }

                    Text("長按作業可刪除")
                        .font(.system(size: 15))
                        .foregroundStyle(PixelPalette.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .modifier(HwPxChrome(title: "作業追蹤"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { showAddHomework = true } label: {
                    HwPxPlus().frame(minWidth: 28, minHeight: 28)
                }
                .buttonStyle(PixelButtonStyle(
                    fill: PixelPalette.gold,
                    contentPadding: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)))
                .accessibilityLabel("新增作業")
            }
        }
        .sheet(isPresented: $showAddHomework) {
            AddHomeworkView(isPresented: $showAddHomework)
        }
        .confirmationDialog(
            "刪除作業",
            isPresented: Binding(
                get: { homeworkToDelete != nil },
                set: { if !$0 { homeworkToDelete = nil } }
            ),
            presenting: homeworkToDelete
        ) { hw in
            Button("刪除「\(hw.title)」", role: .destructive) { deleteHomework(hw) }
            Button("取消", role: .cancel) { homeworkToDelete = nil }
        } message: { hw in
            Text("確定要刪除「\(hw.title)」嗎？此動作無法復原。")
        }
        .onAppear {
            syncNotifications()
            if autoPresentAdd && !showAddHomework { showAddHomework = true }
        }
        .onChange(of: homeworks.count) { syncNotifications() }
        .onChange(of: pending.count) { syncNotifications() }
    }

    private func card(_ homework: HomeworkItem) -> some View {
        PixelHomeworkCard(homework: homework, onToggle: {
            homework.isCompleted.toggle()
            syncNotifications()
        })
        .contextMenu {
            Button(role: .destructive) {
                homeworkToDelete = homework
            } label: {
                Label("刪除作業", systemImage: "trash")
            }
        }
        .accessibilityAction(named: "刪除作業") { homeworkToDelete = homework }
    }

    private func deleteHomework(_ homework: HomeworkItem) {
        modelContext.delete(homework)
        try? modelContext.save()
        homeworkToDelete = nil
    }

    // MARK: Sub Views

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            PixelIcon(kind: .check, scale: 4)
                .foregroundStyle(PixelPalette.muted)
            Text("尚無作業")
                .pixelFont(size: PixelMetrics.FontSize.medium)
                .foregroundStyle(PixelPalette.ink)
            Text("點右上角「＋」新增作業")
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .pixelFrame(fill: PixelPalette.paper)
    }

    private var allDoneCard: some View {
        HStack(spacing: 12) {
            PixelIcon(kind: .check, scale: 2)
            Text("所有作業都已完成！")
                .font(.system(size: 17, weight: .semibold))
        }
        .foregroundStyle(PixelPalette.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .pixelFrame(fill: PixelPalette.grass)
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showCompleted.toggle()
            } label: {
                HStack {
                    Text("已完成 (\(completeds.count))")
                        .pixelFont(size: PixelMetrics.FontSize.small)
                    Spacer()
                    Text(showCompleted ? "收合" : "展開")
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(PixelPalette.muted)
                }
                .foregroundStyle(PixelPalette.ink)
                .frame(minHeight: 28)
            }
            .buttonStyle(PixelButtonStyle(fill: PixelPalette.paper))
            .accessibilityValue(showCompleted ? "已展開" : "已收合")

            if showCompleted {
                ForEach(completeds) { homework in
                    card(homework)
                }
            }
        }
    }

    // MARK: Helpers（同 HomeworkView.syncNotifications）

    private func syncNotifications() {
        let snapshot = homeworks.map {
            HomeworkReminder(title: $0.title, courseName: $0.courseName,
                             dueDate: $0.dueDate, isCompleted: $0.isCompleted)
        }
        Task { await HomeworkNotificationService.shared.reschedule(homeworks: snapshot) }
    }
}

// MARK: - 作業卡

private struct PixelHomeworkCard: View {
    let homework: HomeworkItem
    let onToggle: () -> Void

    private var daysLeft: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: homework.dueDate)
        return calendar.dateComponents([.day], from: today, to: due).day ?? 0
    }

    private var muted: Bool { homework.isCompleted || daysLeft < 0 }

    @ViewBuilder private var dueTag: some View {
        if homework.isCompleted {
            HwPxStatusTag(icon: .check, text: "已完成", fill: PixelPalette.water, textColor: PixelPalette.ink)
        } else if daysLeft < 0 {
            HwPxStatusTag(icon: .cross, text: "已逾期", fill: PixelPalette.ink, textColor: PixelPalette.paper)
        } else if daysLeft == 0 {
            HwPxStatusTag(icon: .alert, text: "今天到期", fill: PixelPalette.red, textColor: PixelPalette.paper)
        } else if daysLeft <= 2 {
            HwPxStatusTag(icon: .triangle, text: "\(daysLeft)天後", fill: PixelPalette.orange, textColor: PixelPalette.ink)
        } else if daysLeft <= 7 {
            HwPxStatusTag(icon: .dot, text: "\(daysLeft)天後", fill: PixelPalette.gold, textColor: PixelPalette.ink)
        } else {
            HwPxStatusTag(icon: .dot, text: "\(daysLeft)天後", fill: PixelPalette.paper2, textColor: PixelPalette.ink)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 勾選方框（觸控區 44pt）
            Button(action: onToggle) {
                ZStack {
                    PixelFrameShape().fill(PixelPalette.ink)
                    PixelFrameShape().inset(by: 2)
                        .fill(homework.isCompleted ? PixelPalette.grass : PixelPalette.paper)
                    if homework.isCompleted {
                        PixelIcon(kind: .check, scale: 2, color: PixelPalette.ink)
                    }
                }
                .frame(width: 28, height: 28)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(homework.isCompleted ? "標為未完成" : "標為完成")

            VStack(alignment: .leading, spacing: 4) {
                Text(homework.title)
                    .font(.system(size: 17, weight: .semibold))
                    .strikethrough(muted)
                    .foregroundStyle(muted ? PixelPalette.muted : PixelPalette.ink)
                Text(homework.courseName)
                    .font(.system(size: 15))
                    .foregroundStyle(PixelPalette.muted)
                if let note = homework.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 15))
                        .foregroundStyle(PixelPalette.muted)
                        .lineLimit(2)
                }
            }
            .padding(.top, 10)

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                dueTag
                Text(homework.dueDate.formatted(.dateTime.month().day().locale(Locale(identifier: "zh_Hant_TW"))))
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(PixelPalette.muted)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.paper)
        .opacity(muted ? 0.7 : 1)
    }
}

// MARK: - 新增作業

struct PixelAddHomeworkView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var homeworkTitle = ""
    @State private var courseName = ""
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HwPxBlock(title: "作業資訊") {
                        TextField("作業名稱", text: $homeworkTitle).modifier(HwPxFieldFrame())
                        TextField("科目", text: $courseName).modifier(HwPxFieldFrame())
                    }

                    HwPxBlock(title: "截止日期") {
                        DatePicker("到期日", selection: $dueDate, displayedComponents: .date)
                            .tint(PixelPalette.ink)
                            .modifier(HwPxFieldFrame())
                    }

                    HwPxBlock(title: "備註（選填）") {
                        TextEditor(text: $note)
                            .scrollContentBackground(.hidden)
                            .font(.system(size: 17))
                            .foregroundStyle(PixelPalette.ink)
                            .frame(height: 96)
                            .padding(6)
                            .pixelFrame(fill: PixelPalette.paper)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .modifier(HwPxChrome(title: "新增作業"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { isPresented = false } label: {
                        Text("取消").font(.system(size: 15)).foregroundStyle(PixelPalette.ink)
                    }
                    .buttonStyle(PixelButtonStyle(
                        contentPadding: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)))
                }
                ToolbarItem(placement: .confirmationAction) {
                    let disabled = homeworkTitle.isEmpty || courseName.isEmpty
                    Button {
                        addHomework()
                        isPresented = false
                    } label: {
                        Text("完成").font(.system(size: 15)).foregroundStyle(PixelPalette.ink)
                    }
                    .buttonStyle(PixelButtonStyle(
                        fill: PixelPalette.gold,
                        contentPadding: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)))
                    .disabled(disabled)
                    .opacity(disabled ? 0.4 : 1)
                }
            }
        }
    }

    private func addHomework() {
        let homework = HomeworkItem(
            title: homeworkTitle,
            courseName: courseName,
            dueDate: dueDate,
            note: note.isEmpty ? nil : note
        )
        modelContext.insert(homework)
    }
}
