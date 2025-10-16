//
//  localDB_sampleerApp.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/09/25.
//

import SwiftUI
import SwiftData

@main
struct localDB_sampleerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentsView()
        }
		.modelContainer(for: [
			SimpleData.self,
			SimpleData_100K.self,
			ComplexIndexSchool.self,
			ComplexStudent.self,
			ComplexGrade.self
		])
    }
}
