//
//  ContentsView.swift
//  localDB-sampleer
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import SwiftUI

struct ContentsView: View {
	var body: some View {
		NavigationStack {
			List {
				NavigationLink("SimpleDataListView") { SimpleDataListView() }
				NavigationLink("SimpleSearchListView") { SimpleSearchListView() }
				NavigationLink("SimpleIndexListView") { SimpleIndexListView() }
				NavigationLink("SimpleData_100K_ListView") { SimpleData_100K_ListView() }
				NavigationLink("ComplexDataListView") { ComplexDataListView() }
			}
			.navigationTitle("Contents")
		}
	}
}


