# TeknoPOS - WiFi Voucher Management System

TeknoPOS adalah aplikasi Point of Sale (POS) desktop yang dirancang untuk mempermudah manajemen dan penjualan voucher WiFi Hotspot Mikrotik. Aplikasi ini dibangun menggunakan Flutter dan dapat berjalan di Windows, Linux, dan macOS.

## Fitur Utama

- **Manajemen Voucher**:
  - **Generate Voucher**: Buat ratusan voucher baru secara massal, baik di database lokal maupun langsung di Mikrotik.
  - **Import Data**: Impor data voucher dari file CSV, Excel (.xlsx), atau file ekspor Mikrotik (.rsc).
  - **Input Manual**: Tambahkan voucher satu per satu secara manual.
  - **Stok Real-time**: Lihat jumlah stok voucher yang tersedia untuk setiap paket.

- **Integrasi Mikrotik**:
  - **Sinkronisasi Stok**: Secara otomatis mengambil daftar user dari Mikrotik (`/ip/hotspot/user`) dan menampilkannya sebagai stok yang tersedia.
  - **Filter Uptime**: Hanya menampilkan user dengan `uptime` nol (belum pernah dipakai) sebagai stok.
  - **Generate Langsung**: Membuat user baru di Mikrotik saat fitur "Generate Voucher" digunakan.
  - **Manajemen Paket**: Sinkronisasi "User Profile" dari Mikrotik sebagai paket voucher di aplikasi.

- **Point of Sale (POS)**:
  - **Antarmuka Kasir**: Tampilan yang mudah digunakan untuk memilih dan menjual voucher.
  - **Manajemen Keranjang**: Tambah dan hapus item dari keranjang belanja.
  - **Multi-Metode Pembayaran**: Dukungan untuk pembayaran via Cash, Transfer, dan E-Wallet.

- **Laporan Penjualan**:
  - **Dashboard Laporan**: Lihat ringkasan total penjualan, jumlah transaksi, dan penjualan per metode pembayaran.
  - **Filter Tanggal**: Saring laporan transaksi berdasarkan rentang tanggal tertentu.
  - **Manajemen Transaksi**: Lihat detail transaksi dan lakukan proses **Refund**.
  - **Export ke Excel**: Ekspor data laporan penjualan dan stok ke dalam format file `.xlsx`.

- **Database Lokal**:
  - **Penyimpanan Offline**: Menggunakan SQLite untuk menyimpan semua data transaksi, paket, dan voucher yang terjual.
  - **Persistensi Data**: Data penjualan tetap aman bahkan jika tidak terhubung ke server atau Mikrotik.

## Tampilan Aplikasi

*(Disarankan untuk menambahkan screenshot aplikasi di sini)*

1.  **Halaman POS**:
    !POS Screen
2.  **Manajemen Voucher**:
    !Voucher Management Screen
3.  **Laporan**:
    !Reports Screen

---

## Instalasi dan Setup (Untuk Pengguna)

1.  Unduh versi terbaru aplikasi dari halaman Releases.
2.  Ekstrak file ZIP dan jalankan file `teknopos.exe`.
3.  **Konfigurasi Awal**:
    - Buka aplikasi, klik ikon **Gear (Pengaturan)** di pojok kanan atas.
    - Masukkan **IP Address**, **Port API**, **Username**, dan **Password** Mikrotik Anda.
    - Klik **Test & Save**. Jika muncul status "Connected Successfully!", aplikasi siap digunakan.

## Panduan Penggunaan

### 1. Menambah Stok Voucher

Ada tiga cara untuk menambah stok:

- **Sinkronisasi dengan Mikrotik (Direkomendasikan)**:
  - Pastikan konfigurasi Mikrotik sudah benar.
  - Buka menu **Vouchers**. Stok akan otomatis ditarik dari Mikrotik.
  - Tekan tombol **Refresh** untuk sinkronisasi ulang.

- **Generate Voucher**:
  - Di menu **Vouchers**, klik **Generate**.
  - Pilih paket, tentukan jumlah, prefix (opsional), dan panjang kode.
  - Klik **Generate**. Voucher akan dibuat di database lokal dan di Mikrotik.

- **Import File**:
  - Di menu **Vouchers**, klik **Import File**.
  - Pilih file `.csv`, `.xlsx`, atau `.rsc`.
  - Aplikasi akan memproses dan menambahkan voucher ke database.

### 2. Mengelola Paket

- Buka menu **Vouchers**, klik **Packets**.
- Di sini Anda bisa **menambah**, **mengedit**, atau **menghapus** paket voucher (misal: "Paket 1 Jam", "Paket Harian").
- Harga yang diatur di sini akan digunakan saat generate atau menjual voucher.

### 3. Melakukan Penjualan

- Buka menu **POS**.
- Klik pada paket voucher yang ingin dijual. Item akan ditambahkan ke keranjang.
- Di sisi kanan, Anda bisa melihat total belanja, memilih metode pembayaran, dan menyelesaikan transaksi dengan menekan tombol **Complete Sale**.

### 4. Melihat Laporan & Refund

- Buka menu **Reports**.
- Gunakan filter tanggal untuk melihat transaksi pada periode tertentu.
- Klik pada salah satu item transaksi untuk melihat detailnya atau melakukan **Refund**.

---

## Untuk Developer (Setup Lingkungan Pengembangan)

1.  Pastikan Flutter SDK sudah terinstall di sistem Anda.
2.  Clone repository ini: `git clone https://github.com/username/teknopos.git`
3.  Masuk ke direktori proyek: `cd teknopos`
4.  Install dependensi: `flutter pub get`
5.  Jalankan aplikasi: `flutter run -d windows` (atau `linux`/`macos`)

## Kontribusi

Kontribusi dalam bentuk pull request, laporan bug, atau saran fitur sangat kami hargai. Silakan buat *issue* baru untuk memulai diskusi.