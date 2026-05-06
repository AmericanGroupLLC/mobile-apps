import SwiftUI
import CardCore

/// Shown when a card is tapped. Mark as task / Set reminder / Done / Edit / Delete.
struct CardActionSheet: View {
    @EnvironmentObject private var repository: CardRepository
    @Environment(\.dismiss) private var dismiss
    let card: Card

    @State private var showReminderPicker = false
    @State private var pickerDate: Date = Date().addingTimeInterval(60 * 60)
    @State private var showEdit = false
    @State private var editText: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(card.text)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                Section("Convert") {
                    Button {
                        repository.convert(card, to: .task)
                        dismiss()
                    } label: {
                        Label("Mark as task", systemImage: "checklist")
                    }
                    Button {
                        showReminderPicker = true
                    } label: {
                        Label("Set reminder", systemImage: "bell")
                    }
                    if card.kind != .note {
                        Button {
                            repository.convert(card, to: .note)
                            dismiss()
                        } label: {
                            Label("Convert to plain note", systemImage: "doc.plaintext")
                        }
                    }
                }
                if card.kind == .task {
                    Section {
                        Button {
                            repository.toggleCompleted(card)
                            dismiss()
                        } label: {
                            Label(card.isCompleted ? "Mark not done" : "Mark done",
                                  systemImage: card.isCompleted ? "arrow.uturn.left" : "checkmark.circle")
                        }
                    }
                }
                Section {
                    Button {
                        editText = card.text
                        showEdit = true
                    } label: {
                        Label("Edit text", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        repository.delete(card)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showReminderPicker) {
                NavigationStack {
                    Form {
                        DatePicker("Remind me at",
                                   selection: $pickerDate,
                                   in: Date()...,
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                    .navigationTitle("Set reminder")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                repository.convert(card, to: .reminder, reminderAt: pickerDate)
                                showReminderPicker = false
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showReminderPicker = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                NavigationStack {
                    Form {
                        TextField("Card text", text: $editText, axis: .vertical)
                            .lineLimit(2...10)
                    }
                    .navigationTitle("Edit")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                repository.update(card, text: editText)
                                showEdit = false
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showEdit = false }
                        }
                    }
                }
            }
        }
    }
}
