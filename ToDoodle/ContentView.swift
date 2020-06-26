//
//  ContentView.swift
//  ToDoodle
//
//  Created by Jared Pendergraft on 6/10/20.
//  Copyright © 2020 Jared Pendergraft Designs. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var isEditing: EditMode = .inactive
    @State var isFocused = false
    @State var isSettings: Bool = false
    @State var editTaskID: UUID = UUID()
    @State var editTaskTitle = ""
    @State var newTask = ""
    @State var offset = CGSize.zero
    @ObservedObject var store = TaskStore()
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    func resetUI() {
        hideKeyboard()
        newTask = ""
        editTaskID = UUID()
        editTaskTitle = ""
    }
    
    func taskAdd() {
        store.tasks.append(Task(completed: false, title: "\(newTask)"))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        resetUI()
    }
    
    var filteredTasks: [Task]  {
        if store.hideCompleted {
            return store.tasks.filter { return !$0.completed }
        } else {
            return store.tasks
        }
    }
    
    var themeColor: Color {
        let filteredThemes = themes.filter { return $0.position == store.theme }
        if filteredThemes.count > 0 {
            for theme in filteredThemes {
                return theme.color
            }
        }
        return Color.gray
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Header
                HStack (spacing: 16) {
                    Button(action: {
                        self.isEditing = .inactive
                        self.isSettings.toggle()
                        self.resetUI()
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 22, weight: .bold))
                    }
                    if self.store.tasks.count > 0 {
                        Spacer()
                        Text("ToDoodle")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: {
                            self.isEditing.toggle()
                            self.isSettings = false
                            self.resetUI()
                        }) {
                            Image(systemName: self.isEditing == .active ? "xmark.circle.fill" : "ellipsis.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                        }
                    } else {
                        Spacer()
                    }
                }.padding()
                // Main Content
                VStack {
                    // Tasks
                    if filteredTasks.count > 0 {
                        List {
                            ForEach(filteredTasks, id:\.id) { task in
                                HStack(spacing: 16) {
                                    if self.isEditing != .active && self.editTaskID != task.id {
                                        Button(action: { self.store.tasks[self.store.tasks.firstIndex(where: { $0.id == task.id })!].completed.toggle() }) {
                                            Image(systemName: task.completed ? "checkmark.circle.fill":"circle")
                                                .font(.system(size: 22, weight: .bold))
                                                .frame(width: 22)
                                        }.buttonStyle(BorderlessButtonStyle())
                                    }
                                    if self.editTaskID == task.id {
                                        TextField("Add item…", text: self.$editTaskTitle, onCommit: {
                                            self.store.tasks[self.store.tasks.firstIndex(where: { $0.id == task.id })!].title = self.editTaskTitle
                                            self.resetUI()
                                        })
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Button(action: {
                                            self.store.tasks[self.store.tasks.firstIndex(where: { $0.id == task.id })!].title = self.editTaskTitle
                                            self.resetUI()
                                        }) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .bold))
                                                .frame(width: 22)
                                        }.buttonStyle(BorderlessButtonStyle())
                                    } else {
                                        Text("\(task.title)")
                                            .foregroundColor(task.completed ? .secondary : .primary)
                                            .strikethrough(task.completed ? true : false)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        if task.completed != true && self.isEditing != .active {
                                            Button(action: {
                                                self.editTaskID = task.id
                                                self.editTaskTitle = task.title
                                            }) {
                                                Image(systemName: "ellipsis")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .frame(width: 22)
                                            }.buttonStyle(BorderlessButtonStyle())
                                        } else {
                                            Rectangle()
                                                .frame(width: 22)
                                                .opacity(0)
                                        }
                                    }
                                }
                            }
                            .onDelete { index in
                                self.store.tasks.remove(at: index.first!)
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                            }
                            .onMove { (source: IndexSet, destination: Int) in
                                self.store.tasks.move(fromOffsets: source, toOffset: destination)
                            }
                        }.environment(\.editMode, $isEditing)
                    } else {
                        // Home View
                        VStack(spacing: 8) {
                            Text("ToDoodle")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("What good shall I do this day?")
                                .foregroundColor(.secondary)
                        }.padding()
                    }
                }.frame(maxHeight: .infinity)
                // Footer
                VStack {
                    Divider()
                    if self.isEditing == .active {
                        HStack {
                            Button(action: { self.store.tasks.removeAll() }) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 22)
                                Text("Remove all")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }.foregroundColor(.red)
                        }.padding()
                    } else {
                        HStack {
                            TextField("Add item…", text: $newTask, onCommit: { self.taskAdd() })
                                .onTapGesture {
                                    self.isFocused = true
                                    self.isSettings = false
                            }
                            Button(action: {
                                if self.newTask != "" { self.taskAdd() }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22, weight: .bold))
                            }
                            
                        }.padding()
                    }
                }
                .padding(.bottom, isFocused ? self.keyboardHeightHelper.keyboardHeight : 0)
                .animation(.spring())
            }.accentColor(themeColor)
            // App Settings
            GeometryReader { bounds in
                VStack {
                    Spacer()
                    VStack{
                        Rectangle()
                            .frame(width: 40, height: 5)
                            .cornerRadius(3)
                            .opacity(0.125)
                        Button(action: { self.store.hideCompleted.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: self.store.hideCompleted ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(self.themeColor)
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 22)
                                Text("\(self.store.hideCompleted ? "Show completed tasks" : "Hide completed tasks")")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }.padding(.vertical)
                        Text("THEME")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)
                        ForEach(themes, id:\.id) { item in
                            Button(action: { self.store.theme = item.position }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .frame(width: 22)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(item.color)
                                    Text("\(item.label)")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if self.store.theme == item.position {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(item.color)
                                            .frame(width: 22)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .padding(.bottom, bounds.safeAreaInsets.bottom + 40)
                    .background(BlurView(style: .systemMaterial))
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                self.offset = gesture.translation
                        }
                        .onEnded { _ in
                            if self.offset.height < 0 {
                                self.offset = .zero
                            } else if self.offset.height > 40 {
                                self.offset = .zero
                                self.isSettings = false
                            } else {
                                self.offset = .zero
                            }
                        }
                    )
                }
                .frame(maxWidth: 640, maxHeight: .infinity)
                .animation(.spring())
                .offset(y: self.isSettings ? (bounds.safeAreaInsets.bottom > 0 ? bounds.safeAreaInsets.bottom + 30 + self.offset.height : self.offset.height - 20) : bounds.size.height)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Extras

extension EditMode {
    mutating func toggle() {
        self = self == .active ? .inactive : .active
    }
}

struct Task: Identifiable, Codable {
    var id = UUID()
    var completed: Bool
    var title: String
}

struct Theme: Identifiable {
    var id = UUID()
    var position: Int
    var color: Color
    var label: String
}

let themes = [
    Theme(position: 1, color: Color.gray, label: "Dark and Stormy"),
    Theme(position: 2, color: Color.blue, label: "Kind of Blue"),
    Theme(position: 3, color: Color.green, label: "Garden Green"),
    Theme(position: 4, color: Color.purple, label: "Purple Rain")
]
