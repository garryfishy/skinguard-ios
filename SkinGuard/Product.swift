//
//  Product.swift
//  SkinGuard
//

import Foundation

struct Product: Codable, Identifiable {
    let no: String
    let namaProduk: String
    let nomorIzinEdar: String
    let kandunganBahanBerbahaya: String
    let produsenPendaftar: String
    let nomorSuratPublicWarning: String

    var id: String { no }

    enum CodingKeys: String, CodingKey {
        case no = "No"
        case namaProduk = "Nama Produk"
        case nomorIzinEdar = "Nomor Izin Edar / Notifikasi"
        case kandunganBahanBerbahaya = "Kandungan Bahan Berbahaya/Dilarang"
        case produsenPendaftar = "Produsen / Pendaftar"
        case nomorSuratPublicWarning = "Nomor Surat Public Warning"
    }
}

struct SearchResult: Codable {
    let query: String
    let count: Int
    let results: [Product]
}
