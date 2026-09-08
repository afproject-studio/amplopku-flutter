# AmplopKu

AmplopKu adalah aplikasi money tracker sederhana berbasis Flutter dengan konsep **Envelope Budgeting**. Uang bulanan dibagi ke beberapa amplop supaya pengguna lebih mudah memahami batas pengeluaran.

## Fitur utama

- Splash screen, login demo, dan register demo.
- Setup pendapatan bulanan.
- Pembagian amplop Kebutuhan, Keinginan, dan Tabungan.
- Dashboard ringkasan pemasukan, pengeluaran, dan sisa amplop.
- Tambah transaksi income/expense.
- Laporan transaksi dan rasio pengeluaran.
- Kalender transaksi sederhana.
- Halaman profil dan kelola amplop.

## Cara menjalankan

```bash
flutter pub get
flutter run
```

Untuk demo cepat, tekan **Mulai demo tanpa akun** di halaman login.

## Alur aplikasi

1. Splash screen.
2. Login/Register atau Demo.
3. Setup pendapatan.
4. Setup pembagian amplop sampai total 100%.
5. Dashboard.
6. Tambah transaksi dan pantau laporan.

## Catatan pengembangan

Versi ini dibuat sebagai MVP tugas akhir. State transaksi masih disimpan secara lokal menggunakan `ValueNotifier`, sehingga mudah dipresentasikan dan tidak tergantung koneksi database. Struktur sudah disiapkan agar nanti bisa dikembangkan ke Firebase Auth dan Cloud Firestore.
