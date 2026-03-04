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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var normalizedQuery: String {
        query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var exactMatch: Product? {
        viewModel.result?.results.first { product in
            product.namaProduk
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() == normalizedQuery
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Mencari produk kamu...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        Text("Terjadi Kesalahan")
                            .font(.headline)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let result = viewModel.result {
                    if result.results.isEmpty {
                        SafeResultView(query: query) {
                            dismiss()
                        }
                    } else if let product = exactMatch {
                        DangerResultView(product: product) {
                            if let url = URL(string: "https://standar-otskk.pom.go.id/otskk-db/kategori/database-kosmetik-mengandung-bahan-berbahaya") {
                                openURL(url)
                            }
                        }
                    } else {
                        CautionResultListView(
                            products: result.results,
                            expandedIDs: $expandedIDs
                        )
                    }
                }
            }
        }
        .navigationTitle("Hasil Pencarian")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.search(query: query)
        }
    }
}

struct CautionResultListView: View {
    let products: [Product]
    @Binding var expandedIDs: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Warning header block
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Wah kamu harus hati-hati")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text("Brand ini ada yang di-banned produknya, cek list ini ya:")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.9))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(primaryColor)
            )
            .padding(.horizontal)
            .padding(.top)

            List(products) { product in
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

struct SafeResultView: View {
    let query: String
    let onBackToHome: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(primaryColor)

            Text("Selamat!")
                .font(.title2.bold())

            Text("Produk \"\(query)\" tidak ditemukan dalam daftar produk berbahaya BPOM.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onBackToHome) {
                Text("Cek Produk Lain")
                    .font(.headline)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(primaryColor)
                    )
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DangerResultView: View {
    let product: Product
    let onOpenBPOM: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 72))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("WAH BAHAYA NIH!")
                    .font(.title2.bold())

                Text("Produk kamu persis seperti yang di-banned.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Nama Produk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(product.namaProduk)
                    .font(.headline)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Kandungan Berbahaya")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(product.kandunganBahanBerbahaya)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                if !product.nomorSuratPublicWarning.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No. Public Warning")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(product.nomorSuratPublicWarning)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Text("Segera hentikan pemakaian produk ini dan konsultasikan dengan dokter kulit jika terjadi iritasi.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: onOpenBPOM) {
                    Text("Info BPOM")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(primaryColor)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.namaProduk)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
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
                VStack(alignment: .leading, spacing: 8) {
                    if !product.kandunganBahanBerbahaya.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kandungan Berbahaya")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(product.kandunganBahanBerbahaya)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.red.opacity(0.15))
                                )
                        }
                    }

                    if !product.produsenPendaftar.isEmpty {
                        Text("Produsen / Pendaftar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(product.produsenPendaftar)
                            .font(.subheadline)
                    }

                    if !product.nomorSuratPublicWarning.isEmpty {
                        Text("No. Public Warning")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        Text(product.nomorSuratPublicWarning)
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }
}

