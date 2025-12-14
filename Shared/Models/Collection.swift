// Collection.swift
// NoorReader
//
// SwiftData model for book collections/folders

import SwiftData
import Foundation

@Model
final class Collection {
    var id: UUID
    var name: String
    var icon: String
    var dateCreated: Date

    var books: [Book] = []

    init(name: String, icon: String = "folder") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.dateCreated = Date()
    }
}
