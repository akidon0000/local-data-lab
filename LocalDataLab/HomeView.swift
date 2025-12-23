//
//  HomeView.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import SwiftUI
import SwiftData

struct HomeView: View {
	var body: some View {
		NavigationStack {
			List {
				Section("SwiftData") {
					NavigationLink("[SimpleObject] View") { SimpleObjectListView() }
					NavigationLink("[SimpleObject + #Index] View") { SimpleIndexObjectListView() }
					NavigationLink("[SimpleDescriptorObject + FetchDescriptor] 検索") { SimpleDescriptorSearchListView() }
				}
			}
		}
		.modelContainer(for: [
			SimpleObject.self,
			SimpleIndexObject.self,
			SimpleDescriptorObject.self,
		])
	}
}
