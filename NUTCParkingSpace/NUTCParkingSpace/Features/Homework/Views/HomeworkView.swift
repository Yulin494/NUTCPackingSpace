//
//  HomeworkView.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI
import SwiftData

struct HomeworkView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddHomework = false
    @Query(sort: \HomeworkItem.dueDate) var homeworks: [HomeworkItem]

    var uncomplateds: [HomeworkItem] {
        homeworks.filter { !$0.isCompleted }
    }

    var completeds: [HomeworkItem] {
        homeworks.filter { $0.isCompleted }
    }

    var body: some View {
        List {
            if uncomplateds.isEmpty && completeds.isEmpty {
                Section {
                    Text("尚無作業")
                        .foregroundColor(.secondary)
                }
            } else {
                Section(header: Text("待完成")) {
                    if uncomplateds.isEmpty {
                        Text("所有作業都已完成！")
                            .foregroundColor(.green)
                    } else {
                        ForEach(uncomplateds) { homework in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: homework.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .onTapGesture {
                                            homework.isCompleted.toggle()
                                        }
                                        .foregroundColor(homework.isCompleted ? .green : .gray)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(homework.title)
                                            .font(.headline)
                                            .strikethrough(homework.isCompleted)
                                        Text(homework.courseName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        let daysLeft = daysUntil(homework.dueDate)
                                        if daysLeft <= 0 {
                                            Text("已逾期")
                                                .font(.caption2)
                                                .foregroundColor(.red)
                                        } else if daysLeft == 0 {
                                            Text("今天")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                        } else {
                                            Text("\(daysLeft) 天後")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }

                                        Text(homework.dueDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                if !completeds.isEmpty {
                    Section(header: Text("已完成 (\(completeds.count))")) {
                        ForEach(completeds) { homework in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(homework.title)
                                    .font(.headline)
                                    .strikethrough(true)
                                    .foregroundColor(.secondary)
                                Text(homework.courseName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { indices in
                            indices.forEach { modelContext.delete(completeds[$0]) }
                        }
                    }
                }
            }
        }
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
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.year, .month, .day], from: Date())
        let targetDate = calendar.dateComponents([.year, .month, .day], from: date)

        guard let todayDate = calendar.date(from: today),
              let targetDateFromComponents = calendar.date(from: targetDate) else {
            return 0
        }

        let components = calendar.dateComponents([.day], from: todayDate, to: targetDateFromComponents)
        return components.day ?? 0
    }
}

struct AddHomeworkView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var homeworkTitle = ""
    @State private var courseName = ""
    @State private var dueDate = Date().addingTimeInterval(86400) // 明天
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("作業資訊")) {
                    TextField("作業名稱", text: $homeworkTitle)
                    TextField("科目", text: $courseName)
                    TextEditor(text: $note)
                        .frame(height: 80)
                }

                Section(header: Text("截止日期")) {
                    DatePicker("到期日", selection: $dueDate, displayedComponents: .date)
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
