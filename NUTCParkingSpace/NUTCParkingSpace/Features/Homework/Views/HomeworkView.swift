//
//  HomeworkView.swift
//  NUTCParkingSpace
//

import SwiftUI
import SwiftData
import UIKit

struct HomeworkView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddHomework = false
    @State private var showCompleted = false
    @State private var homeworkToDelete: HomeworkItem?
    @Query(sort: \HomeworkItem.dueDate) var homeworks: [HomeworkItem]

    /// 由外部（如課業頁「新增作業」快速鍵）帶入，進頁後自動開啟新增表單
    var autoPresentAdd: Bool = false

    private var pending: [HomeworkItem] {
        homeworks.filter { !$0.isCompleted }
    }

    private var completeds: [HomeworkItem] {
        homeworks.filter { $0.isCompleted }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if pending.isEmpty && completeds.isEmpty {
                    emptyStateCard
                } else {
                    // 待完成區塊
                    if pending.isEmpty {
                        allDoneCard
                    } else {
                        ForEach(pending) { homework in
                            HomeworkCard(homework: homework, onToggle: {
                                withAnimation(.spring(response: 0.3)) {
                                    homework.isCompleted.toggle()
                                    syncNotifications()
                                }
                            })
                            .contextMenu {
                                Button(role: .destructive) {
                                    homeworkToDelete = homework
                                } label: {
                                    Label("刪除作業", systemImage: "trash")
                                }
                            }
                        }
                    }

                    // 已完成摺疊區塊
                    if !completeds.isEmpty {
                        completedSection
                    }

                    Text("長按作業可刪除")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("作業追蹤")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { showAddHomework = true }) {
                    Image(systemName: "plus")
                }
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

    private func deleteHomework(_ homework: HomeworkItem) {
        modelContext.delete(homework)
        try? modelContext.save()
        homeworkToDelete = nil
        // homeworks.count 改變會觸發 onChange → syncNotifications()，清掉對應的提醒
    }

    // MARK: - Sub Views

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("尚無作業")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("點右上角「+」新增作業")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }

    private var allDoneCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(.green)
            Text("所有作業都已完成！")
                .font(.headline)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }

    private var completedSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showCompleted.toggle()
                }
            }) {
                HStack {
                    Text("已完成 (\(completeds.count))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            if showCompleted {
                ForEach(completeds) { homework in
                    HomeworkCard(homework: homework, onToggle: {
                        withAnimation(.spring(response: 0.3)) {
                            homework.isCompleted.toggle()
                            syncNotifications()
                        }
                    })
                    .contextMenu {
                        Button(role: .destructive) {
                            homeworkToDelete = homework
                        } label: {
                            Label("刪除作業", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func syncNotifications() {
        // 轉成 Sendable 快照後再交給 actor，避免把 SwiftData @Model 跨 actor 傳遞
        let snapshot = homeworks.map {
            HomeworkReminder(title: $0.title, courseName: $0.courseName,
                             dueDate: $0.dueDate, isCompleted: $0.isCompleted)
        }
        Task { await HomeworkNotificationService.shared.reschedule(homeworks: snapshot) }
    }
}

// MARK: - HomeworkCard

struct HomeworkCard: View {
    let homework: HomeworkItem
    let onToggle: () -> Void

    private var daysLeft: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: homework.dueDate)
        return calendar.dateComponents([.day], from: today, to: due).day ?? 0
    }

    private var urgencyColor: Color {
        if homework.isCompleted { return .gray }
        switch daysLeft {
        case ..<0:   return .red
        case 0:      return .red
        case 1...2:  return .orange
        case 3...7:  return .yellow
        default:     return .blue
        }
    }

    private var dueLabel: some View {
        Group {
            if homework.isCompleted {
                Text("已完成")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.green)
            } else if daysLeft < 0 {
                Text("已逾期")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.red)
            } else if daysLeft == 0 {
                Text("今天到期")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.red)
            } else if daysLeft <= 2 {
                Text("\(daysLeft)天後")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.orange)
            } else {
                Text("\(daysLeft)天後")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // 左側彩色色條
            Rectangle()
                .fill(urgencyColor)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .padding(.vertical, 10)

            HStack(spacing: 12) {
                // 勾選圓圈
                Button(action: onToggle) {
                    Image(systemName: homework.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(homework.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                // 標題 + 科目 + 備註
                VStack(alignment: .leading, spacing: 4) {
                    Text(homework.title)
                        .font(.headline)
                        .strikethrough(homework.isCompleted || daysLeft < 0)
                        .foregroundColor(
                            (homework.isCompleted || daysLeft < 0) ? .secondary : .primary
                        )
                    Text(homework.courseName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let note = homework.note, !note.isEmpty {
                        Text(note)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // 右側到期資訊
                VStack(alignment: .trailing, spacing: 4) {
                    dueLabel
                    Text(homework.dueDate.formatted(.dateTime.month().day().locale(Locale(identifier: "zh_Hant_TW"))))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
        .background(
            (homework.isCompleted || daysLeft < 0)
                ? Color(UIColor.tertiarySystemGroupedBackground)
                : Color(UIColor.secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }
}

// MARK: - AddHomeworkView

struct AddHomeworkView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var homeworkTitle = ""
    @State private var courseName = ""
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("作業資訊")) {
                    TextField("作業名稱", text: $homeworkTitle)
                    TextField("科目", text: $courseName)
                }

                Section(header: Text("截止日期")) {
                    DatePicker("到期日", selection: $dueDate, displayedComponents: .date)
                }

                Section(header: Text("備註（選填）")) {
                    TextEditor(text: $note)
                        .frame(height: 80)
                }
            }
            .navigationTitle("新增作業")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        addHomework()
                        isPresented = false
                    }
                    .disabled(homeworkTitle.isEmpty || courseName.isEmpty)
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

#Preview {
    NavigationStack {
        HomeworkView()
    }
}
