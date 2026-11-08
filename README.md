# Part to Terrain - Roblox Studio Plugin

**Part to Terrain** adalah plugin Roblox Studio yang memungkinkan Anda mengonversi geometri Part, Wedge, Silinder, dan Bola menjadi Terrain voxel halus secara instan dengan dukungan berbagai material dan deteksi bentuk otomatis.

---

## ✨ Fitur Utama

- 📐 **Deteksi Bentuk Cerdas (Smart Shape Detection)**:
  - **Block Part**: Menggunakan `Terrain:FillBlock` sesuai CFrame dan ukuran part.
  - **Ball / Sphere**: Otomatis dikonversi menjadi bola terrain halus dengan `Terrain:FillBall`.
  - **Cylinder**: Otomatis menyesuaikan orientasi sumbu silinder dengan `Terrain:FillCylinder`.
  - **WedgePart**: Otomatis menyesuaikan kemiringan segitiga dengan `Terrain:FillWedge`.
  - **Model & Folder**: Otomatis memindai semua part di dalam hierarki model/folder pilihan.
- 🎨 **Dukungan Material Lengkap**:
  - **Auto (Material Part)**: Menyesuaikan material part asli secara otomatis (misal: part batu jadi Terrain Rock, part rumput jadi Grass).
  - **Manual Selection**: Pilihan 22+ material Terrain (Grass, Rock, Sand, Water, Mud, Snow, Ice, Slate, Basalt, Concrete, Brick, Cobblestone, dll.).
- ⚙️ **Opsi Fleksibel**:
  - Hapus part asli setelah konversi (dapat diaktifkan/dinonaktifkan).
  - Pindai part di dalam Model dan Folder.
  - Aktifkan/nonaktifkan deteksi bentuk khusus.
- ↩️ **Undo / Redo Penuh**:
  - Terintegrasi langsung dengan `ChangeHistoryService` Studio (`Ctrl + Z` untuk membatalkan konversi kapan saja).
- 🌓 **Tema Studio Dinamis**:
  - Mendukung tampilan **Dark Mode** dan **Light Mode** Roblox Studio secara native.
  - Dilengkapi tombol manual **🔄 Refresh** dan deteksi part real-time.
- 🚀 **Anti-Freeze (Batch Processing)**:
  - Menggunakan batching `task.wait()` sehingga Studio tetap responsif meskipun mengonversi ratusan part sekaligus.

---

## 📥 Cara Instalasi

### Metode 1: Menggunakan File `.rbxmx` (Paling Mudah)
1. Unduh file [`plugin/PartToTerrain.rbxmx`](plugin/PartToTerrain.rbxmx).
2. Salin dan letakkan file tersebut ke dalam folder plugin lokal Roblox Studio Anda:
   - **Windows**: `%LOCALAPPDATA%\Roblox\Plugins\`
     *(tekan `Win + R`, ketik `%localappdata%\Roblox\Plugins`, lalu tekan Enter)*.
3. Buka atau muat ulang Roblox Studio.
4. Plugin akan langsung muncul di tab **Plugins** dengan nama **PartToTerrain**.

### Metode 2: Lewat Explorer Studio
1. Buat sebuah `Script` baru di `ServerStorage`.
2. Salin kode dari [`PartToTerrain.luau`](PartToTerrain.luau) ke dalam script tersebut.
3. Klik kanan script tersebut di jendela **Explorer** ➔ pilih **"Save as Local Plugin..."** ➔ simpan.

### Metode 3: Menggunakan Rojo
Jika Anda menggunakan Rojo untuk workflow pengembangan:
```bash
rojo build -o PartToTerrain.rbxm
```
Lalu pindahkan file hasil build ke folder plugin Roblox Studio.

---

## 🎮 Cara Penggunaan

1. Buka tempat (place) Anda di Roblox Studio.
2. Klik tombol **PartToTerrain** pada tab **Plugins** di ribbon atas untuk membuka jendela panel.
3. Pilih part atau model yang ingin diubah menjadi terrain di **Viewport 3D** atau **Explorer**.
4. Pilih material yang diinginkan pada dropdown **TARGET MATERIAL** (default: `Auto`).
5. Sesuaikan opsi konversi jika diperlukan.
6. Klik tombol hijau **⚡ Konversi ke Terrain**.
7. Jika hasil konversi ingin dibatalkan, klik tombol **↩ Undo** atau tekan shortcut `Ctrl + Z`.

---

## 📂 Struktur Proyek

```text
roblox-plugin/
├── src/
│   └── init.server.luau        # Source code utama plugin (Rojo-compatible)
├── plugin/
│   └── PartToTerrain.rbxmx     # File model XML Roblox siap pakai
├── PartToTerrain.luau          # Standalone source file
├── default.project.json        # Konfigurasi Rojo
├── .gitignore
├── LICENSE
└── README.md
```

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).
