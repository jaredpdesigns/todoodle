//
//  TaskStore.swift
//  ToDoodle
//
//  Created by Jared Pendergraft on 6/19/20.
//  Copyright © 2020 Jared Pendergraft Designs. All rights reserved.
//

import SwiftUI
import Combine

class TaskStore: ObservableObject {
    @Published var hideCompleted: Bool = UserDefaults.standard.bool(forKey: "HideCompleted") {
        didSet {
            UserDefaults.standard.set(self.hideCompleted, forKey: "Theme")
        }
    }
    @Published var tasks: [Task] {
        didSet {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(tasks) {
                UserDefaults.standard.set(encoded, forKey: "Tasks")
            }
        }
    }
    @Published var theme: Int = UserDefaults.standard.integer(forKey: "Theme") {
        didSet {
            UserDefaults.standard.set(self.theme, forKey: "Theme")
        }
    }
    
    init() {
        self.hideCompleted = UserDefaults.standard.object(forKey: "HideCompleted") as? Bool ?? false
        if let tasks = UserDefaults.standard.data(forKey: "Tasks") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([Task].self, from: tasks) {
                self.tasks = decoded
                return
            }
        }
        self.tasks = []
        self.theme = UserDefaults.standard.object(forKey: "Theme") as? Int ?? 1
    }
}
