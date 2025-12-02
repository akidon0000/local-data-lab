//
//  HomeView.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import SwiftUI
import SwiftData

struct Home: View {
    let persistenceController = PersistenceController.shared
    @Environment(\.modelContext) private var modelContext

	var body: some View {
		NavigationStack {
			List {
				Section("SwiftData") {
					NavigationLink("SimpleObjectListView") { SimpleObjectListView() }
//					NavigationLink("SimpleSearchListView") { SimpleSearchListView() }
					NavigationLink("SimpleIndexListView") { SimpleIndexLabelListView() }
                NavigationLink("SimpleWrite_100K") {
                    SimpleDataWrite_100K_ListView(
                        simpleDataModelActor: SimpleDataModelActor(
                            modelContainer: modelContext.container
                        )
                    ) 
                }
					NavigationLink("SimpleRead_100K_ListView") { SimpleData_100K_ListView() }
					NavigationLink("SimpleDataInfiniteScrollView") { SimpleDataInfiniteScrollView() }
				}

				Section("Core Data") {
					NavigationLink("SimpleObjectCDListView") { SimpleObjectCDListView() }
				}

				Section("Complex (SwiftData)") {
					NavigationLink("ComplexDataListView") { ComplexDataListView() }
                NavigationLink("ComplexDataIndexView") { ComplexDataIndexView() }
                NavigationLink("ComplexPagingListView") { ComplexPagingListView() }
                NavigationLink("ComplexSearchListView") { ComplexSearchListView() }
                NavigationLink("ComplexIndexPagingListView") { ComplexIndexPagingListView() }
					NavigationLink("ComplexAllFetchListView") { ComplexAllFetchListView(
						simpleDataModelActor: ComplexDataModelActor(
							modelContainer: modelContext.container
						)
					)}
				}
			}
			.navigationTitle("Home")
		}
		.environment(\.managedObjectContext, persistenceController.container.viewContext)
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


