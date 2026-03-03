//
//  SearchResultView.swift
//  SkinGuard
//

import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var result: SearchResult?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func search(query: String) async {
        isLoading = true
        errorMessage = nil
        result = nil

        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://skinguard-api.oceandigital.id/api/products?q=\(encoded)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            result = try JSONDecoder().decode(SearchResult.self, from: data)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct SearchResultView: View {
    let query: String
    @StateObject private var viewModel = SearchViewModel()
    @State private var expandedIDs: Set<String> = []

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let result = viewModel.result {
                if result.results.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)
                        Text("Produk Aman")
                            .font(.title2.bold())
                        Text("Produk yang anda cari aman")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(result.results) { product in
                        ProductAccordionRow(
                            product: product,
                            isExpanded: expandedIDs.contains(product.id)
                        ) {
                            if expandedIDs.contains(product.id) {
                                expandedIDs.remove(product.id)
                            } else {
                                expandedIDs.insert(product.id)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .animation(.easeInOut(duration: 0.2), value: expandedIDs)
                }
            }
        }
        .navigationTitle(viewModel.result.map { $0.results.isEmpty ? "Hasil Pencarian" : "\($0.count) Hasil" } ?? "Hasil Pencarian")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.search(query: query)
        }
    }
}

struct ProductAccordionRow: View {
    let product: Product
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(product.namaProduk)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kandungan Berbahaya")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(product.kandunganBahanBerbahaya)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(.bottom, 12)
            }
        }
    }
}
