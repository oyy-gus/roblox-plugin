# Part, Mesh, CSG & Script Studio - Roblox Studio Plugin
*(Part to Terrain, Part & Union to MeshPart, CSG Operations, & Script Obfuscator)*

**Part, Mesh, CSG & Script Studio** adalah plugin komprehensif untuk Roblox Studio dengan tema antarmuka modern **Hitam Putih (Monochrome Edition)** yang menggabungkan 5 alat esensial developer:
1. ⛰️ **Part to Terrain Converter**: Konversi bentuk geometris ke Smooth Terrain voxel presisi tinggi.
2. 🔷 **Part & Union to MeshPart**: Konversi Part standar dan UnionOperation CSG menjadi `MeshPart` native (mendukung mode Terpisah maupun Penggabungan Prosedural jadi 1 MeshPart).
3. 🔘 **Penumpul Sudut Part (Bevel / Rounded Box)**: Fitur instan 1-klik untuk menumpulkan sudut dan tepi tajam balok Part menjadi melengkung halus (*procedural rounded bevel*) dengan custom radius dan tingkat kehalusan segmen.
4. 🧩 **CSG Tools (Union & Negate)**: Fitur membuat Part menjadi Negatif (`NegateOperation`), menggabungkan part/melubangi objek menjadi `UnionOperation`, serta memisahkan kembali (`Separate`).
5. 🔒 **Script Obfuscator**: Pengacak dan pengenkripsi kode Luau tingkat tinggi (*Source-to-Source*) untuk `Script`, `LocalScript`, dan `ModuleScript` yang membuat kode **sangat susah dibaca & dibongkar**, tanpa membutuhkan `loadstring` sehingga 100% aman dijalankan di Client maupun Server!

---

## ✨ Fitur Utama

### 🌓 Tema Hitam Putih (Monochrome Edition)
- Desain antarmuka minimalis, elegan, dan profesional bernuansa **Hitam & Putih (B&W)**.
- Kontras tinggi dan teks tajam yang nyaman di mata untuk sesi kerja panjang di Roblox Studio.
- Adaptasi otomatis terhadap mode terang/gelap Studio dengan skema monokrom yang konsisten.

---

### 🧩 1. Fitur CSG Tools (Union & Negate) (Baru!)
Alat pemodelan CSG (*Constructive Solid Geometry*) bawaan langsung di dalam panel plugin:

- ➖ **Negate Part (Ubah ke Negatif / Positif)**:
  - Mengubah Part biasa (Block, Cylinder, Wedge, Sphere) menjadi `NegateOperation` semi-transparan kemerahan.
  - Berfungsi sebagai "pemotong" (*cutter*) untuk melubangi atau memotong bentuk part lain.
  - Klik lagi pada objek negatif untuk mengembalikannya menjadi Part biasa (*toggle*).
- ➕ **Union Parts (Gabung Jadi 1 Union / CSG Subtraction)**:
  - Menggabungkan sekumpulan part terpilih menjadi satu objek `UnionOperation` tunggal.
  - Jika seleksi mengandung Part Negatif, plugin otomatis **memotong/melubangi** part solid sesuai volume part negatif tersebut.
  - Mendukung pengaturan **Collision Fidelity** dan **Render Fidelity** secara langsung.
  - Opsi penamaan rapi otomatis (`<NamaPart>_Union`).
- ✂️ **Separate Union (Pisahkan Union)**:
  - Membongkar kembali model `UnionOperation` menjadi part-part penyusun aslinya serta part negatif pemotongnya.
- 🔷 **Shortcut Convert ke MeshPart**:
  - Tombol 1-klik untuk langsung memanggang (*bake*) model Union menjadi `MeshPart` native yang teroptimasi.
- ⚡ **Akses Cepat di Tab MeshPart**:
  - Tombol pintas `➖ Negate Part` dan `➕ Union Parts` juga disematkan di Tab MeshPart untuk efisiensi workflow pemodelan.

---

### 🔒 2. Fitur Script Obfuscator
Fitur khusus untuk melindungi aset script game Anda dari pencurian intelektual, *exploit leaker*, atau *decompilation*:

- 🛡️ **100% Native Luau Execution (Client & Server Safe)**:
  - Bekerja secara *Source-to-Source transformation*.
  - **TIDAK memerlukan `loadstring()`**, sehingga aman dijalankan di `LocalScript` client, `Script` server, maupun `ModuleScript` bersama.
- ⚡ **3 Preset Tingkat Keamanan**:
  - **● Ekstrem (Maksimal - Rekomendasi)**: Enkripsi String XOR Multibyte, Barcode Mangling (`_Il11II...`), Mutasi Angka Hexadecimal, Opaque Predicates (Junk Logic), dan Minifikasi.
  - **○ Standar**: Enkripsi String XOR, Barcode Mangling, Mutasi Angka Hex, dan Minifikasi.
  - **○ Minify Saja**: Menghapus seluruh komentar dan merapatkan spasi tanpa enkripsi/pengubahan nama variable.
- 🔐 **Teknologi Proteksi Tingkat Lanjut**:
  - 🔑 **Enkripsi String XOR Multibyte Dynamic Table**: Seluruh string literal dienkripsi dengan *rotating session key* dan diakses melalui metatable runtime self-decrypting (`_STR[(0x.. - 0x..)]`).
  - 🔠 **Barcode Variable Mangling (`_Il11II...`)**: Seluruh variabel lokal, parameter fungsi, dan loop counter diubah menjadi deretan barcode karakter visual serupa (`_Il11II11`, `_1lIlII1l`) yang membuat manusia maupun decompiler pusing membacanya. Tetap menjaga fungsi/property bawaan Roblox (`.Position`, `:GetService()`, dll).
  - 🔢 **Mutasi Angka Hexadecimal & Aritmatika**: Nilai numerik diubah menjadi ekspresi matematika dinamis (contoh: `42` menjadi `(0x8E - 0x64)`).
  - 🎭 **Opaque Predicates (Junk Logic Anti-Read)**: Logika evaluasi semu anti-tamper yang mempersulit decompiler.
  - 🧹 **Pembersihan Metadata & Minifikasi**: Menghapus seluruh komentar serta merapatkan baris.
- 💾 **Fitur Safety Auto-Backup & Restore**:
  - Opsi **Auto-Backup**: Menduplikasi script asli ke `<NamaScript>_Backup` sebelum diubah.
  - Tombol **↩ Pulihkan Backup**: Mengembalikan kode asli dari file backup secara instan.
  - Dukungan Undo/Redo penuh (`Ctrl + Z`) melalui `ChangeHistoryService`.
- 📋 **Pratinjau Output Console**: Melihat pratinjau hasil obfuscasi di Output Studio sebelum diterapkan.

---

### ⛰️ 3. Fitur Part to Terrain
- 📐 **Deteksi Bentuk Cerdas (Smart Shape Detection)**:
  - **Block Part**: Mengonversi kubus/balok menggunakan `Terrain:FillBlock`.
  - **Ball / Sphere**: Otomatis menjadi bola terrain halus dengan `Terrain:FillBall`.
  - **Cylinder**: Orientasi sumbu silinder disesuaikan otomatis dengan `Terrain:FillCylinder`.
  - **WedgePart**: Kemiringan segitiga presisi dengan `Terrain:FillWedge`.
- 🎨 **Dukungan 22+ Material Terrain**:
  - **Auto**: Otomatis mencocokkan material part asli (contoh: part Rock menjadi Terrain Rock, Wood jadi WoodPlanks).
  - Pilihan manual: Grass, Rock, Sand, Water, Mud, Snow, Ice, Slate, Basalt, Concrete, Brick, Cobblestone, dll.

---

### 🔷 4. Fitur Part to MeshPart & Union to MeshPart
- 🔀 **Mode Seleksi Ganda (Terpisah vs Gabung Jadi 1 MeshPart)**:
  - 🧱 **Terpisah (Per Part)**: Setiap Part atau Union yang dipilih dikonversi menjadi MeshPart individual.
  - 🔗 **Gabung Jadi 1 MeshPart (Combine Mode)**: Menggabungkan seluruh part dan union terpilih menjadi **1 buah MeshPart tunggal** dengan geometri yang disatukan secara prosedural! Sangat bagus untuk optimasi draw call dan performa game.
- 🧩 **Dukungan UnionOperation (Union to MeshPart)**:
  - Otomatis mendeteksi model CSG (`UnionOperation`), mendekonstruksi poligonnya secara aman, dan memanggangnya (*baking*) langsung ke dalam `EditableMesh` / `MeshPart` native tanpa perlu export/import manual.
- 🔄 **Auto-Detect SpecialMesh / FileMesh**:
  - Memindai part dengan `SpecialMesh` dan otomatis mengonversinya menjadi `MeshPart` native dengan mempertahankan `MeshId` dan `TextureId`.
- ⚡ **Konversi Bentuk Native (Procedural EditableMesh)**:
  - Part standar (Block, Wedge, CornerWedge, Ball/Sphere, Cylinder) langsung dikonversi menjadi **MeshPart** 100% native tanpa aset eksternal.
- ⚙️ **Pengaturan Fidelity**:
  - **Collision Fidelity**: `Default`, `PreciseConvexDecomposition`, `Hull`, `Box`.
  - **Render Fidelity**: `Automatic`, `Performance`, `Precise`.

---

### 🔘 5. Fitur Penumpul Sudut Part (Bevel / Rounded Box) (Baru!)
Fitur prosedural untuk mengubah balok Part yang kaku dan tajam menjadi model tumpul melengkung halus (*chamfered / rounded bevel*):

- 🔘 **Aksi Instan 1-Klik (`TUMPULKAN SUDUT PART TERPILIH`)**:
  - Pilih satu atau banyak balok Part di Viewport, lalu klik tombol penumpul.
  - Balok otomatis digantikan dengan `MeshPart` berujung tumpul yang presisi.
  - Mempertahankan posisi, orientasi, ukuran, warna, material, nama, attributes, tags, dan children objek.
- 🎚️ **Pengaturan Radius (Studs)**:
  - Tentukan sendiri besar kelengkungan sudut (default `0.4` studs).
  - Dilengkapi sistem *safety clamping* dinamis agar geometri tidak tembus atau tumpang tindih (*watertight topology*).
- 🎛️ **3 Tingkat Kehalusan (Segments)**:
  - **1 (Chamfer 45°)**: 1 segmen sudut miring, sangat ringan dan bergaya *low-poly modern*.
  - **2 (Halus - Standar)**: 2 segmen melengkung halus dan seimbang untuk performa game.
  - **3 (Sangat Halus)**: 3 segmen kurva ultra halus untuk detail arsitektur tingkat tinggi.
- 🔁 **Integrasi Konversi Mesh Biasa**:
  - Centang opsi *"Terapkan sudut tumpul saat konversi MeshPart biasa"* jika Anda ingin semua balok otomatis ditumpulkan sudutnya saat melakukan konversi MeshPart biasa (baik mode Terpisah maupun Gabung).

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
   - **🧩 CSG**: Pemodelan CSG (membuat part negatif, menggabungkan/melubangi part jadi union, memisahkan union).
   - **🔒 Obfuscator**: Pengacak dan pengaman kode script (`ModuleScript`, `LocalScript`, `Script`).
4. Pilih target objek di **Viewport 3D** atau **Explorer**.
5. Sesuaikan opsi yang diinginkan.
6. Klik tombol aksi hitam-putih utama:
   - `⚡ KONVERSI KE TERRAIN`
   - `⚡ KONVERSI KE MESHPART` (atau `⚡ GABUNG SEMUA JADI 1 MESHPART`)
   - `➖ NEGATE PART` atau `➕ UNION PARTS`
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
