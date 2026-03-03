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
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("SkinGuard")
                    .font(.largeTitle.bold())

                Text("Cari produk atau foto bahan untuk memeriksa kandungan zat berbahaya")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Cari nama produk...", text: $searchText)
                        .onSubmit { submit() }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // OR divider
                HStack {
                    VStack { Divider() }
                    Text("atau")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    VStack { Divider() }
                }
                .padding(.horizontal)

                // Foto Ingredients button
                Button {
                    showScanner = true
                } label: {
                    Label("Foto Bahan", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("SkinGuard")
            .navigationDestination(item: $submittedQuery) { query in
                SearchResultView(query: query)
            }
            .fullScreenCover(isPresented: $showScanner) {
                IngredientScanView()
            }
        }
    }

    private func submit() {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            submittedQuery = trimmed
        }
    }
}

#Preview {
    ContentView()
}
