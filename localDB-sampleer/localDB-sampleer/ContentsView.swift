//
//  ContentsView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import SwiftUI
import SwiftData

struct ContentsView: View {
    @Environment(\.modelContext) private var modelContext
	var body: some View {
		NavigationStack {
			List {
				NavigationLink("1-SimpleObjectListView") { SimpleObjectListView() }
				NavigationLink("SimpleSearchListView") { SimpleSearchListView() }
				NavigationLink("SimpleIndexListView") { SimpleIndexLabelListView() }
				NavigationLink("SimpleData_100K_ListView") { SimpleData_100K_ListView() }
                NavigationLink("SimpleDataWrite_100K_ListView") {
                    SimpleDataWrite_100K_ListView(
                        simpleDataModelActor: SimpleDataModelActor(
                            modelContainer: modelContext.container
                        )
                    ) 
                }
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
			.navigationTitle("Contents")
		}
	}
}


