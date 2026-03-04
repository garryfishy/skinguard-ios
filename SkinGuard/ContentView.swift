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
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [
                                primaryColor,
                                primaryColor.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .ignoresSafeArea(edges: .top)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Image("splash_icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .shadow(radius: 10)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cek Keamanan\nSkincare Kamu")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Hi, masukkan nama kosmetik kamu di sini yaa untuk cek apakah mengandung bahan berbahaya.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 76)
                    }

                    Spacer()
                }

                VStack(spacing: 24) {
                    Spacer().frame(height: 220)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nama Produk")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(primaryColor)

                                TextField("Contoh: Tabita, HN, Olay...", text: $searchText)
                                    .focused($isTextFieldFocused)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .onSubmit { submit() }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        }

                        Button(action: submit) {
                            Text("Cek Sekarang")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(primaryColor)
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)

                        HStack {
                            VStack { Divider() }
                            Text("atau")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                            VStack { Divider() }
                        }

                        Button {
                            showScanner = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Foto Bahan")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(primaryColor.opacity(0.1))
                            )
                            .foregroundStyle(primaryColor)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 20)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(primaryColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Data ini berdasarkan database BPOM untuk kosmetik yang mengandung bahan berbahaya.")
                                .font(.footnote)
                            Text("Selalu pastikan produkmu memiliki nomor BPOM resmi dan gunakan seperlunya.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(primaryColor.opacity(0.08))
                    )
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $submittedQuery) { query in
                SearchResultView(query: query)
            }
            .fullScreenCover(isPresented: $showScanner) {
                IngredientScanView()
            }
        }
    }

    private func submit() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        submittedQuery = trimmed
        isTextFieldFocused = false
    }
}

#Preview {
    ContentView()
}

