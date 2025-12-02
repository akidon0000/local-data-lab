//
//  LocalDataLabApp.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import SwiftUI
import SwiftData

@main
struct LocalDataLabApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
		.modelContainer(for: [
			SimpleObject.self,
            SimpleData_100K_2.self,
			SimpleData_100K.self,
			ComplexIndexSchool.self,
			ComplexStudent.self,
			ComplexGrade.self
		])
    }
}
