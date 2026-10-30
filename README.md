# SakuKu – Pencatatan Keuangan Anda
> **Aplikasi Manajemen Keuangan Pribadi Pintar**  
> Didesain dengan antarmuka modern *Dark Mode* (*Deep Slate*, *Emerald Green*, *Accent Cyan*, *Rose*), responsif, dan kaya fitur dari Fase 1 hingga Fase 4.

---

## 🌟 Ringkasan Implementasi Produk

Aplikasi **SakuKu** telah diimplementasikan secara menyeluruh sesuai dengan dokumen **Product Requirement Document (PRD)**:

| Berkas | Deskripsi |
| :--- | :--- |
| **`index.html`** | Aplikasi Web Interaktif mandiri (*Single-Page Application*) siap pakai langsung di peramban (Chrome, Edge, Firefox, Safari) tanpa perlu dependensi rumit. Memuat Chart.js, SheetJS, Lucide Icons, dan sistem `localStorage` reaktif. |
| **`dapa.sql`** | Skema Database Relasional MySQL 8.0+ / MariaDB lengkap (`users`, `categories`, `transactions`, `category_budgets`, `savings_goals`, `sync_logs`) dilengkapi indeks performa, relasi *Foreign Key*, dan data *seed* awal. |
| **`daoa.py`** | *Data Access Object* (DAO) Python backend engine untuk manipulasi data transaksi, kalkulasi ringkasan, ekspor/impor CSV dengan penanganan UTF-8 BOM, serta validasi ambang batas anggaran. |

---

## 🚀 Fitur Utama Berdasarkan Roadmap PRD

### Fase 1: Core Essentials & Visual Alignment
* **Identitas Visual Modern:** Palet warna *Deep Slate* (`#0F172A`), *Emerald Green* (`#10B981`), *Accent Cyan* (`#38BDF8`), dan *Rose Red* (`#F43F5E`).
* **Catat Transaksi Cepat (3 Langkah):** Input nominal Rupiah (Rp) $\rightarrow$ Pilih Kategori (dinamis & bisa tambah kategori baru) $\rightarrow$ Simpan.
* **Grafik Keuangan Interaktif (Chart.js):**
  * **Tren Historis 12 Bulan:** Grafik multi-line atau diagram batang membandingkan Pemasukan vs Pengeluaran.
  * **Rincian per Kategori:** Donut chart dengan persentase proporsi pengeluaran secara visual.
* **Metrik Finansial Real-time:** Total Saldo Kas Bersih, Pemasukan Bulanan, Pengeluaran Bulanan, dan Rasio Tabungan (Net Savings Rate).

### Fase 2: Historical Data & Excel Integration
* **Riwayat Transaksi:** Dikelompokkan kronologis per bulan dengan indikator arus kas.
* **Cari & Saring Instan:** Filter berdasarkan kata kunci deskripsi, kategori, tipe (Pemasukan/Pengeluaran), dan periode bulan.
* **Laporan Bulanan:** Rekapitulasi bulanan, navigasi mundur/maju antar bulan, dan tabel rincian proporsi pengeluaran per kategori.
* **Integrasi Excel & CSV:**
  * **Ekspor CSV:** Menghasilkan file `.csv` standar RFC 4180 dengan UTF-8 BOM yang langsung rapi dibuka di Microsoft Excel maupun Google Sheets.
  * **Impor CSV / Excel (.xlsx):** Parser dengan validasi skema otomatis dan penanganan galat.
  * **Panduan Format Kolom & Template:** Dialog panduan kolom serta tombol sekali klik untuk mengunduh template CSV siap isi.

### Fase 3: Budgeting & Financial Goals
* **Target Keuangan (Savings Goals):**
  * Buat target tabungan (Dana Darurat, Laptop Baru, Liburan).
  * Batas waktu/tenggat, nominal target, dan tombol *"Tambah Tabungan"* untuk top-up progres.
  * Indikator progres bar interaktif dan status *"Tercapai!"*.
* **Anggaran Kategori (Category Budgeting):**
  * Penetapan kuota batas pengeluaran bulanan per kategori.
  * Peringatan visual otomatis:
    * **Normal (< 80%):** Hijau / Cyan
    * **Mendekati Batas (80% – 99%):** Kuning Amber (`#F59E0B`)
    * **Melebihi Batas (≥ 100%):** Merah Rose (`#F43F5E`) dengan lencana kedip dan peringatan.

### Fase 4: Account System & Cloud Sync
* **Sistem Akun:** Profil pengguna, inisial avatar, status membership *SakuKu Cloud Basic*, serta simulasi masuk dengan Google OAuth.
* **Status Sinkronisasi Cloud:** Indikator cloud aktif *"Tersinkron"*, stempel waktu sinkronisasi terakhir, dan tombol sinkronisasi paksa (*Sync Now*).
* **Multi-Device Simulator:** Pilihan simulasi beralih perangkat (Laptop Kantor, HP Android, Tablet Pribadi).
* **Cadangkan & Pulihkan:** Ekspor dan impor seluruh basis data aplikasi dalam format JSON.

---

## 💻 Cara Menjalankan Aplikasi

### 1. Menjalankan Antarmuka Web (Frontend)
Cukup buka file `index.html` langsung di browser favorit Anda:
* Klik ganda (double-click) pada file **`index.html`**, ATAU
* Jalankan server lokal sederhana jika diinginkan:
  ```powershell
  # Menggunakan ekstensi Live Server VS Code / browser langsung
  Start-Process "index.html"
  ```

### 2. Menjalankan Database MySQL (Backend Schema)
Import file `dapa.sql` ke server MySQL atau MariaDB Anda:
```bash
mysql -u root -p < dapa.sql
```

### 3. Menguji Data Access Object (DAO Python)
Jika lingkungan Python telah terpasang:
```bash
python daoa.py
```

---

## 📋 Skema Format Impor Kolom CSV / Excel

| Tanggal | Tipe | Kategori | Nominal | Deskripsi |
| :--- | :--- | :--- | :--- | :--- |
| `2026-10-25` | `Pemasukan` | Gaji Pokok | `10000000` | Gaji Bulanan |
| `2026-10-26` | `Pengeluaran` | Makanan & Minuman | `75000` | Makan siang kantor |
| `2026-10-27` | `Pengeluaran` | Transportasi | `50000` | Bensin motor |

