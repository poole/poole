---

layout: post


title: Modifikasi Java di Macbook
categories: PPN
version: '1.0'
toc: true
datePublished: '2018-05-08 05:01:21 +0000'
nour: 20180100002
author: editor
related_posts:
  - umum
  - Dimulainya Kewajiban Perpajakan
isChild: true
anchor: wpop
permalink: /ppn/efaktur/modifikasi-java-di-macbook.html
---
###cara modifikasi Java di macbook

Jika di dalam Macbook sudah terinstall versi 9 atau 10 maka perlu dilakukan manipulasi Java Version agar Macbook dapat membaca versi 8u171
Dengan Langkah-langkah sebagai berikut :
1. Install JDK 8u171
2. Buat Direktori baru dengan perintah : sudo /usr/local/bin/java
3. Buat link java 8u171 yang pada local : ln -s /Library/Java/JavaVirtualMachines/jdk1.8.0_171.jdk/Contents/Home/bin/java[ spasi ]/usr/local/bin/java
4. Lakukan pengecekan versi java untuk memastikan dengan perintah : /usr/bin/java -version

### Cara menjalankan eFaktur di Macbook setelah manipulasi java version :
1. Masuk ke dalam folder efaktur, misalnya Lokasi efaktur berada di Desktop dengan Nama Folder EFaktur_Mac64 : cd ./Desktop/EFaktur_Mac64
2. Jalankan eFaktur dengan perintah : ./ETaxInvoice.jar 

--Semoga Berhasil--

> Sebelum melakukan langkah di atas, cb dulu install jdk 8u171 dan jlnkn ETaxInvoice.jar dgn cara double click

**Kalo gagal dgn cara biasa, baru coba cara manipulasi versi java**
mmm
