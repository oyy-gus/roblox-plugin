# Part, Mesh & Script Studio - Roblox Studio Plugin
*(Part Converter, Union to MeshPart & Advanced Script Obfuscator)*

**Part, Mesh & Script Studio** adalah plugin komprehensif untuk Roblox Studio dengan tema antarmuka modern **Hitam Putih (Monochrome Edition)** yang menggabungkan 3 alat penting developer:
1. ⛰️ **Part to Terrain Converter**: Konversi bentuk geometris ke Smooth Terrain voxel presisi tinggi.
2. 🔷 **Part & Union to MeshPart**: Konversi Part standar dan UnionOperation CSG menjadi `MeshPart` native (mendukung mode Terpisah maupun Penggabungan Prosedural jadi 1 MeshPart).
3. 🔒 **Script Obfuscator**: Pengacak dan pengenkripsi kode Luau tingkat tinggi (*Source-to-Source*) untuk `Script`, `LocalScript`, dan `ModuleScript` yang membuat kode **sangat susah dibaca & dibongkar**, tanpa membutuhkan `loadstring` sehingga 100% aman dijalankan di Client maupun Server!

---

## ✨ Fitur Utama

### 🌓 Tema Hitam Putih (Monochrome Edition)
- Desain antarmuka minimalis, elegan, dan profesional bernuansa **Hitam & Putih (B&W)**.
- Kontras tinggi dan teks tajam yang nyaman di mata untuk sesi kerja panjang di Roblox Studio.
- Adaptasi otomatis terhadap mode terang/gelap Studio dengan skema monokrom yang konsisten.

---

### 🔒 1. Fitur Script Obfuscator (Baru!)
Fitur khusus untuk melindungi aset script game Anda dari pencurian intelektual, *exploit leaker*, atau *decompilation*:

- 🛡️ **100% Native Luau Execution (Client & Server Safe)**:
  - Bekerja secara *Source-to-Source transformation*.
  - **TIDAK memerlukan `loadstring()`**, sehingga aman dijalankan di `LocalScript` client, `Script` server, maupun `ModuleScript` bersama.
- ⚡ **3 Preset Tingkat Keamanan**:
  - **● Ekstrem (Maksimal - Rekomendasi)**: Enkripsi String XOR Multibyte, Barcode Mangling (`_Il11II...`), Mutasi Angka Hexadecimal, Opaque Predicates (Junk Logic), dan Minifikasi.
  - **○ Standar**: Enkripsi String XOR, Barcode Mangling, Mutasi Angka Hex, dan Minifikasi.
  - **○ Minify Saja**: Menghapus seluruh komentar dan merapatkan spasi tanpa enkripsi/pengubahan nama variable.
- 🔐 **Teknologi Proteksi Tingkat Lanjut**:
  - 🔑 **Enkripsi String XOR Multibyte Dynamic Table**: Seluruh string literal (seperti nama service, nama part, pesan error) dienkripsi dengan *rotating session key* dan diakses melalui metatable runtime self-decrypting (`_STR[(0x.. - 0x..)]`).
  - 🔠 **Barcode Variable Mangling (`_Il11II...`)**: Seluruh variabel lokal, parameter fungsi, dan loop counter diubah menjadi deretan barcode karakter visual serupa (`_Il11II11`, `_1lIlII1l`) yang membuat manusia maupun decompiler pusing membacanya. Tetap menjaga fungsi/property bawaan Roblox (`.Position`, `:GetService()`, dll).
  - 🔢 **Mutasi Angka Hexadecimal & Aritmatika**: Konstanta numerik diubah menjadi ekspresi matematika dinamis (contoh: `42` menjadi `(0x8E - 0x64)`).
  - 🎭 **Opaque Predicates (Junk Logic Anti-Read)**: Penyisipan logika evaluasi palsu dan anti-tamper yang mempersulit analisis decompiler.
  - 🧹 **Pembersihan Metadata & Minifikasi**: Menghapus seluruh komentar (`--` dan `--[[ ]]`) serta merapatkan baris.
- 💾 **Fitur Safety Auto-Backup & Restore**:
  - Opsi **Auto-Backup**: Sebelum script dimodifikasi, plugin otomatis menduplikasi script asli ke `<NamaScript>_Backup` di lokasi yang sama.
  - Tombol **↩ Pulihkan Backup**: Mengembalikan kode asli dari file backup secara instan hanya dengan 1 klik.
  - Dukungan penuh Undo/Redo (`Ctrl + Z`) melalui `ChangeHistoryService`.
- 📋 **Pratinjau Output Console**: Tombol pratinjau untuk melihat hasil obfuscasi di jendela Output Studio sebelum diterapkan.

---

### ⛰️ 2. Fitur Part to Terrain
- 📐 **Deteksi Bentuk Cerdas (Smart Shape Detection)**:
  - **Block Part**: Mengonversi kubus/balok menggunakan `Terrain:FillBlock`.
  - **Ball / Sphere**: Otomatis menjadi bola terrain halus dengan `Terrain:FillBall`.
  - **Cylinder**: Orientasi sumbu silinder disesuaikan otomatis dengan `Terrain:FillCylinder`.
  - **WedgePart**: Kemiringan segitiga presisi dengan `Terrain:FillWedge`.
- 🎨 **Dukungan 22+ Material Terrain**:
  - **Auto**: Otomatis mencocokkan material part asli (contoh: part Rock menjadi Terrain Rock, Wood jadi WoodPlanks).
  - Pilihan manual: Grass, Rock, Sand, Water, Mud, Snow, Ice, Slate, Basalt, Concrete, Brick, Cobblestone, dll.

---

### 🔷 3. Fitur Part to MeshPart & Union to MeshPart
- 🔀 **Mode Seleksi Ganda (Terpisah vs Gabung Jadi 1 MeshPart)**:
  - 🧱 **Terpisah (Per Part)**: Setiap Part atau Union yang dipilih akan dikonversi menjadi MeshPart individual masing-masing di posisinya.
  - 🔗 **Gabung Jadi 1 MeshPart (Combine Mode)**: Menggabungkan seluruh part dan union yang dipilih menjadi **1 buah MeshPart tunggal** dengan geometri yang disatukan secara prosedural! Sangat berguna untuk optimasi draw call dan performa game.
- 🧩 **Dukungan UnionOperation (Union to MeshPart)**:
  - Otomatis mendeteksi model CSG (`UnionOperation`), mendekonstruksi poligon konstituennya secara aman, dan memanggangnya (*baking*) langsung ke dalam `EditableMesh` / `MeshPart` native tanpa perlu export/import manual.
- 🔄 **Auto-Detect SpecialMesh / FileMesh**:
  - Memindai part yang memiliki `SpecialMesh` dan otomatis mengonversinya menjadi `MeshPart` native dengan mempertahankan `MeshId` dan `TextureId`.
- ⚡ **Konversi Bentuk Native (Procedural EditableMesh)**:
  - Part standar (Block, Wedge, CornerWedge, Ball/Sphere, Cylinder) dapat langsung dikonversi menjadi **MeshPart** 100% native tanpa ketergantungan aset eksternal.
- 🎯 **Dukungan Custom Mesh ID**:
  - Opsi memasukkan **Mesh ID / Asset URL** kustom untuk mengubah sekumpulan part sekaligus.
- ⚙️ **Pengaturan Fidelity**:
  - **Collision Fidelity**: `Default`, `PreciseConvexDecomposition`, `Hull`, `Box`.
  - **Render Fidelity**: `Automatic`, `Performance`, `Precise`.

---

## 📥 Cara Instalasi

### Metode 1: Menggunakan File `.rbxmx` (Paling Mudah)
1. Buka folder [`plugin/PartToTerrain.rbxmx`](plugin/PartToTerrain.rbxmx).
2. Salin file tersebut ke folder plugin lokal Roblox Studio Anda:
   - **Windows**: `%LOCALAPPDATA%\Roblox\Plugins\`
     *(tekan `Win + R`, ketik `%localappdata%\Roblox\Plugins`, buat folder jika belum ada, lalu tekan Enter)*.
3. Buka atau muat ulang Roblox Studio.
4. Plugin akan langsung muncul di tab **Plugins** dengan nama **Part & Script Studio**.

### Metode 2: Lewat Explorer Studio
1. Buat sebuah `Script` baru di `ServerStorage`.
2. Salin seluruh kode dari [`PartToTerrain.luau`](PartToTerrain.luau) ke dalam script tersebut.
3. Klik kanan script di jendela **Explorer** ➔ pilih **"Save as Local Plugin..."** ➔ simpan.

---

## 🎮 Cara Penggunaan

1. Buka project Anda di Roblox Studio.
2. Klik tombol **PartStudioTools** pada tab **Plugins** di ribbon atas untuk membuka jendela panel.
3. Pilih tab yang ingin digunakan di navigasi atas:
   - **⛰️ Terrain**: Konversi part ke smooth terrain voxel.
   - **🔷 MeshPart**: Konversi part & union ke MeshPart native (terpisah atau gabung jadi 1).
   - **🔒 Obfuscator**: Pengacak dan pengaman kode script (`ModuleScript`, `LocalScript`, `Script`).
4. Pilih target objek di **Viewport 3D** atau **Explorer**.
5. Sesuaikan opsi yang diinginkan.
6. Klik tombol aksi hitam-putih utama:
   - `⚡ KONVERSI KE TERRAIN`
   - `⚡ KONVERSI KE MESHPART` (atau `⚡ GABUNG SEMUA JADI 1 MESHPART`)
   - `⚡ OBFUSCATE SCRIPT TERPILIH`
7. Seluruh aksi mendukung **Undo / Redo (`Ctrl + Z`)**.

---

## 📂 Struktur Proyek

```text
roblox-plugin/
├── src/
│   └── init.server.luau        # Source code utama plugin (Rojo-compatible)
├── plugin/
│   └── PartToTerrain.rbxmx     # File model XML Roblox siap pakai
├── PartToTerrain.luau          # Standalone source file plugin
├── default.project.json        # Konfigurasi Rojo
├── plugin.project.json         # Konfigurasi build plugin Rojo
├── .gitignore
├── LICENSE
└── README.md
```

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).
