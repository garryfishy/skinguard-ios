//
//  ContentView.swift
//  SkinGuard
//
//  Created by Fishy on 03/03/26.
//

import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var submittedQuery: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("SkinGuard")
                    .font(.largeTitle.bold())

                Text("Search for products to check for dangerous ingredients")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("SkinGuard")
            .searchable(text: $searchText, prompt: "Search product name...")
            .onSubmit(of: .search) {
                let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    submittedQuery = trimmed
                }
            }
            .navigationDestination(item: $submittedQuery) { query in
                SearchResultView(query: query)
            }
        }
    }
}

#Preview {
    ContentView()
}
